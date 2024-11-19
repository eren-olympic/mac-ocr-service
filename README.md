# Mac OCR Service

基於 Apple Vision 框架的 macOS OCR 服務，支持中英文識別。

## 功能特點

- 支持繁體中文和英文識別
- 高精度文字識別
- 進度實時顯示
- 支持輸出到文件
- 使用 Apple Vision 框架，無需額外依賴

## 系統要求

- macOS 10.15 或更高版本
- Xcode 命令行工具或完整的 Xcode
- Swift 5.5 或更高版本

## 安裝

1. 克隆倉庫：
```bash
git clone https://github.com/eren-olympic/mac-ocr-service.git
cd mac-ocr-service
```

2. 編譯：
```bash
# 方法 1：編譯為可執行文件
swiftc Sources/OCRService.swift -o ocr

# 方法 2：直接通過 swift 運行（無需編譯）
swift Sources/OCRService.swift
```

## 使用方法

### 如果已編譯（方法 1）：

1. 直接顯示識別結果：
```bash
./ocr path/to/image.png
```

2. 將結果保存到文件：
```bash
./ocr path/to/image.png output.txt
```

### 直接運行（方法 2）：

1. 直接顯示識別結果：
```bash
swift Sources/OCRService.swift path/to/image.png
```

2. 將結果保存到文件：
```bash
swift Sources/OCRService.swift path/to/image.png output.txt
```

## 示例

使用示例圖片進行測試：
```bash
# 如果已編譯
./ocr Examples/test.png

# 直接運行
swift Sources/OCRService.swift Examples/test.png
```

預期輸出：
```
[15:30:45] 正在載入圖像...
[15:30:45] 準備進行文字識別...
[15:30:46] 開始識別文字...
[15:30:47] 處理識別結果...
[15:30:47] 文字識別完成！

識別結果:
[識別出的文字內容]
```

## 目錄結構

```
mac-ocr-service/
├── Sources/
│   └── OCRService.swift    # 主程序源碼
├── Tests/                  # 測試目錄
├── Examples/              # 示例圖片
│   └── test.png          # 測試用圖片
├── README.md             # 說明文件
├── LICENSE              # 授權文件
└── .gitignore          # Git 忽略配置
```

## 常見問題

1. 如果遇到權限問題，請確保可執行文件有執行權限：
```bash
chmod +x ocr
```

2. 如果遇到 "無法載入圖像" 錯誤，請確保：
   - 圖片路徑正確
   - 圖片格式支持（支持 PNG、JPEG、HEIC 等常見格式）
   - 有讀取圖片的權限

## 貢獻指南

1. Fork 本倉庫
2. 創建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 開啟 Pull Request

## 授權

MIT License

## 贊助

如果這個項目對您有幫助，歡迎給個 Star ⭐️