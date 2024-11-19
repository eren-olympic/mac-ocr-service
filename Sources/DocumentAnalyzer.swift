import Foundation
import Vision
import PDFKit

enum DocumentError: Error {
    case pdfLoadFailed
    case imageExtractionFailed
    case recognitionFailed(String)
    case writeError(String)
}

class DocumentAnalyzer {
    typealias ProgressHandler = (String) -> Void
    
    enum ChartType {
        case table
        case chart
        case image
        case unknown
    }
    
    struct AnalysisResult {
        var text: String
        var tables: [(frame: CGRect, content: [[String]])]
        var charts: [(frame: CGRect, type: ChartType)]
        var images: [(frame: CGRect, image: CGImage)]
    }
    
    func analyzePDF(at url: URL, progress: @escaping ProgressHandler) async throws -> AnalysisResult {
        progress("正在載入 PDF 文件...")
        
        guard let pdfDocument = PDFDocument(url: url) else {
            throw DocumentError.pdfLoadFailed
        }
        
        var result = AnalysisResult(text: "", tables: [], charts: [], images: [])
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            progress("正在處理第 \(pageIndex + 1) 頁...")
            
            if let text = page.string {
                result.text += text + "\n"
            }
            
            let images = try await extractImages(from: page)
            progress("發現 \(images.count) 個圖像元素")
            
            for (frame, cgImage) in images {
                if try await detectRectangularStructure(cgImage) {
                    if let tableContent = try await recognizeTable(cgImage) {
                        result.tables.append((frame, tableContent))
                        progress("識別到表格")
                    } else {
                        result.charts.append((frame, .chart))
                        progress("識別到圖表")
                    }
                } else {
                    result.images.append((frame, cgImage))
                    progress("識別到圖片")
                }
            }
        }
        
        return result
    }
    
    private func extractImages(from page: PDFPage) async throws -> [(CGRect, CGImage)] {
        var images: [(CGRect, CGImage)] = []
        let pageRect = page.bounds(for: .mediaBox)
        
        guard let context = CGContext(
            data: nil,
            width: Int(pageRect.width),
            height: Int(pageRect.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return [] }
        
        page.draw(with: .mediaBox, to: context)
        
        if let cgImage = context.makeImage() {
            let request = VNDetectRectanglesRequest { request, error in
                guard let observations = request.results as? [VNRectangleObservation] else { return }
                
                for observation in observations {
                    let boundingBox = observation.boundingBox
                    let rect = CGRect(
                        x: boundingBox.origin.x * pageRect.width,
                        y: boundingBox.origin.y * pageRect.height,
                        width: boundingBox.width * pageRect.width,
                        height: boundingBox.height * pageRect.height
                    )
                    
                    if let croppedImage = cgImage.cropping(to: rect) {
                        images.append((rect, croppedImage))
                    }
                }
            }
            
            try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        }
        
        return images
    }
    
    private func detectRectangularStructure(_ image: CGImage) async throws -> Bool {
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 1.0
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results as? [VNRectangleObservation] else {
            return false
        }
        
        return observations.count >= 4
    }
    
    private func recognizeTable(_ image: CGImage) async throws -> [[String]]? {
        var tableContent: [[String]] = []
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hant", "en-US"]
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results else {
            return nil
        }
        
        let sortedObservations = observations.sorted { 
            guard let obs1 = $0 as? VNRecognizedTextObservation,
                  let obs2 = $1 as? VNRecognizedTextObservation else {
                return false
            }
            return obs1.boundingBox.origin.y > obs2.boundingBox.origin.y 
        }
        
        var currentRow: [String] = []
        var lastY: CGFloat = -1
        
        for observation in sortedObservations {
            guard let textObservation = observation as? VNRecognizedTextObservation,
                  let text = textObservation.topCandidates(1).first?.string else {
                continue
            }
            
            if lastY == -1 {
                lastY = textObservation.boundingBox.origin.y
            }
            
            if abs(textObservation.boundingBox.origin.y - lastY) > 0.1 {
                if !currentRow.isEmpty {
                    tableContent.append(currentRow)
                    currentRow = []
                }
                lastY = textObservation.boundingBox.origin.y
            }
            
            currentRow.append(text)
        }
        
        if !currentRow.isEmpty {
            tableContent.append(currentRow)
        }
        
        return tableContent.isEmpty ? nil : tableContent
    }
}

// 主程序
guard CommandLine.arguments.count > 1 else {
    print("""
    使用方法: 
    OCRService <PDF文件路徑> [輸出文件路徑]
    
    例如:
    OCRService input.pdf                  # 結果輸出到控制台
    OCRService input.pdf output.txt       # 結果保存到文件
    """)
    exit(1)
}

let pdfPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : nil
let analyzer = DocumentAnalyzer()

func showProgress(_ message: String) {
    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    print("[\(timestamp)] \(message)")
}

Task {
    do {
        let result = try await analyzer.analyzePDF(
            at: URL(fileURLWithPath: pdfPath),
            progress: showProgress
        )
        
        var report = """
        文件分析報告
        ============
        
        文字內容：
        ---------
        \(result.text)
        
        表格數量：\(result.tables.count)
        圖表數量：\(result.charts.count)
        圖片數量：\(result.images.count)
        
        表格內容：
        ---------
        """
        
        for (index, table) in result.tables.enumerated() {
            report += "\n表格 \(index + 1):\n"
            for row in table.content {
                report += row.joined(separator: "\t") + "\n"
            }
        }
        
        if let outputPath = outputPath {
            try report.write(toFile: outputPath, atomically: true, encoding: .utf8)
            showProgress("結果已保存到：\(outputPath)")
        } else {
            print("\n\(report)")
        }
        
        exit(0)
    } catch {
        print("錯誤: \(error.localizedDescription)")
        exit(1)
    }
}

RunLoop.main.run()