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

```bash
git clone https://github.com/eren-olympic/mac-ocr-service.git
cd mac-ocr-service
swiftc Sources/OCRService.swift -o ocr
```

## 使用方法

1. 直接顯示識別結果：
```bash
./ocr input.png
```

2. 將結果保存到文件：
```bash
./ocr input.png output.txt
```

## 目錄結構

```
mac-ocr-service/
├── Sources/
│   └── OCRService.swift    # 主程序源碼
├── Tests/                  # 測試目錄
├── Examples/              # 示例圖片
├── README.md             # 說明文件
├── LICENSE              # 授權文件
└── .gitignore          # Git 忽略配置
```

## 授權

MIT License

## 贊助

如果這個項目對您有幫助，歡迎給個 Star ⭐️