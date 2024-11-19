import Foundation
import Vision

// 創建錯誤類型
enum OCRError: Error {
    case imageLoadFailed
    case recognitionFailed(String)
    case writeError(String)
}

class OCRService {
    // 進度回調
    typealias ProgressHandler = (String) -> Void
    
    // 使用 async/await 來處理異步操作，並添加進度回調
    func recognizeText(from url: URL, progress: ProgressHandler) async throws -> String {
        progress("正在載入圖像...")
        
        // 讀取圖像數據
        guard let imageData = try? Data(contentsOf: url),
              let cgImage = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(cgImage, 0, nil) else {
            throw OCRError.imageLoadFailed
        }
        
        progress("準備進行文字識別...")
        
        // 創建文字識別請求
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hant", "en-US"]
        
        progress("開始識別文字...")
        
        // 執行識別
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        
        progress("處理識別結果...")
        
        // 處理結果
        guard let observations = request.results else {
            throw OCRError.recognitionFailed("無法獲取識別結果")
        }
        
        // 組合所有識別的文字
        let recognizedStrings = observations.compactMap { observation in
            (observation as? VNRecognizedTextObservation)?.topCandidates(1).first?.string
        }
        
        progress("文字識別完成！")
        
        return recognizedStrings.joined(separator: "\n")
    }
    
    // 將結果保存到文件
    func saveToFile(_ text: String, at path: String) throws {
        do {
            try text.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw OCRError.writeError("無法寫入文件：\(error.localizedDescription)")
        }
    }
}

// 檢查命令行參數
guard CommandLine.arguments.count > 1 else {
    print("""
    使用方法: 
    OCRService <圖片路徑> [輸出文件路徑]
    
    例如:
    OCRService input.png                  # 結果輸出到控制台
    OCRService input.png output.txt       # 結果保存到文件
    """)
    exit(1)
}

let imagePath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : nil
let ocr = OCRService()

// 創建進度顯示函數
func showProgress(_ message: String) {
    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    print("[\(timestamp)] \(message)")
}

// 創建任務執行 OCR
Task {
    do {
        // 執行識別
        let text = try await ocr.recognizeText(
            from: URL(fileURLWithPath: imagePath), 
            progress: showProgress
        )
        
        // 根據是否指定輸出文件來處理結果
        if let outputPath = outputPath {
            showProgress("正在保存結果到文件...")
            try ocr.saveToFile(text, at: outputPath)
            showProgress("結果已保存到：\(outputPath)")
        } else {
            print("\n識別結果:\n\(text)")
        }
        
        exit(0)
    } catch OCRError.imageLoadFailed {
        print("錯誤: 無法載入圖像")
        exit(1)
    } catch OCRError.writeError(let message) {
        print("錯誤: \(message)")
        exit(1)
    } catch {
        print("錯誤: \(error.localizedDescription)")
        exit(1)
    }
}

// 保持程序運行直到完成
RunLoop.main.run()