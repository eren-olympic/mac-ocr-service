import Foundation
import Vision

// 創建錯誤類型
enum OCRError: Error {
    case imageLoadFailed
    case recognitionFailed(String)
}

class OCRService {
    // 使用 async/await 來處理異步操作
    func recognizeText(from url: URL) async throws -> String {
        // 讀取圖像數據
        guard let imageData = try? Data(contentsOf: url),
              let cgImage = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(cgImage, 0, nil) else {
            throw OCRError.imageLoadFailed
        }
        
        // 創建文字識別請求
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hant", "en-US"]
        
        // 執行識別
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        
        // 處理結果
        guard let observations = request.results else {
            throw OCRError.recognitionFailed("無法獲取識別結果")
        }
        
        // 組合所有識別的文字
        let recognizedStrings = observations.compactMap { observation in
            (observation as? VNRecognizedTextObservation)?.topCandidates(1).first?.string
        }
        
        return recognizedStrings.joined(separator: "\n")
    }
}

// 主程序邏輯
// 檢查命令行參數
guard CommandLine.arguments.count > 1 else {
    print("使用方法: OCRService <圖片路徑>")
    exit(1)
}

let imagePath = CommandLine.arguments[1]
let ocr = OCRService()

// 創建任務執行 OCR
Task {
    do {
        let text = try await ocr.recognizeText(from: URL(fileURLWithPath: imagePath))
        print("識別結果:\n\(text)")
        exit(0)
    } catch OCRError.imageLoadFailed {
        print("錯誤: 無法載入圖像")
        exit(1)
    } catch {
        print("錯誤: \(error.localizedDescription)")
        exit(1)
    }
}

// 保持程序運行直到完成
RunLoop.main.run()