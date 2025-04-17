# iSmartOMO Flutter Project

這是一個使用 Flutter 開發的 iSmartOMO 電子商務應用程式。

## 專案描述

本應用程式提供一個現代化電子商務平台，讓使用者可以瀏覽商品、查看詳情、管理購物車與收藏、會員登入註冊、搜尋商品等，並支援多平台（Android/iOS/Web/桌面）。

## 功能特色

- **首頁展示**：最新、特價、熱銷商品與廣告橫幅。
- **商品列表**：依分類或搜尋結果顯示商品，支援多種排序。
- **商品詳情**：圖片輪播、描述、規格選項、價格、庫存、動態主圖。
- **多語言支援**：預設繁體中文 (zh-TW)，支援英文 (en-US)。
- **本地化日期/時間選擇器**。
- **互動式產品選項**：選擇顏色/尺寸會即時更新主圖。
- **價格顯示控制**：根據 API 狀態與商品狀態動態顯示價格與購物車按鈕。
- **購物車管理**：登入用戶可新增、查看、管理購物車。
- **收藏清單**：登入用戶可收藏/移除商品。
- **用戶登入/註冊**。
- **分享功能**：可分享產品連結。
- **WebView**：顯示網頁內容（如隱私政策、付款說明等）。

## 開始使用

### 環境要求

- Flutter SDK：請參考 pubspec.yaml 的 `environment.sdk` 版本需求。
- Dart SDK：隨 Flutter 安裝。
- 開發工具：建議 Android Studio 或 VS Code，並安裝 Flutter/Dart 插件。

### 安裝步驟

1. **複製儲存庫**：

```bash
git clone <您的儲存庫 URL>
cd test
```

2. **安裝依賴**：

```bash
flutter pub get
```

3. **配置啟動圖標**（如有修改 assets/ic_launcher.png）：

```bash
flutter pub run flutter_launcher_icons
```

### 運行應用程式

1. 連接設備或啟動模擬器。
2. 執行：

```bash
flutter run
```

## 主要依賴套件

- `flutter_localizations`：本地化
- `dio`、`http`：網路請求
- `provider`：狀態管理
- `carousel_slider`：圖片輪播
- `flutter_html`：HTML 內容渲染
- `shared_preferences`：本地資料儲存
- `url_launcher`：開啟外部連結
- `share_plus`：分享功能
- `webview_flutter`：網頁內容顯示
- `font_awesome_flutter`：圖示
- `permission_handler`：權限請求
- `crypto`：加密
- `flutter_launcher_icons`：App 啟動圖標

完整依賴請見 pubspec.yaml。

## 專案結構（概觀）

test/
├── android/            # Android 平台專案
├── ios/                # iOS 平台專案
├── macos/              # macOS 平台專案
├── linux/              # Linux 平台專案
├── windows/            # Windows 平台專案
├── web/                # Web 專案與資源
│   ├── index.html
│   ├── favicon.png
│   ├── manifest.json
│   └── icons/
├── assets/             # 靜態資源 (圖片、icon)
│   ├── ic_launcher.png
│   ├── logox512.png
│   ├── logox1024.png
│   ├── icon.png
│   └── images/
├── lib/
│   ├── main.dart       # 應用程式入口
│   ├── pages/          # 各功能頁面
│   │   ├── product_list_page.dart
│   │   ├── product_detail_page.dart
│   │   ├── cart_page.dart
│   │   ├── login_page.dart
│   │   ├── ...
│   ├── services/       # API 與用戶服務
│   │   ├── api_service.dart
│   │   ├── user_service.dart
│   │   └── ecpay_service.dart
│   └── widgets/        # 可重用 UI 組件
├── test/               # 測試檔案
│   └── widget_test.dart
├── pubspec.yaml        # 依賴與資源設定
├── README.md           # 專案說明
└── ...                 # 其他設定檔

## 注意事項

- API 端點預設為 `https://ismartomo.com.tw/api/`，如需更改請調整 lib/services/api_service.dart。
- 圖片路徑預設為 `https://ismartomo.com.tw/image/`。
- 價格顯示已統一為 `$` 開頭且不含小數點。
- 部分功能（如訂單流程、完整會員中心）可能尚未完全實作。

## 貢獻

歡迎提出 issue 或 pull request。

## 授權

（請依實際情況補充授權資訊） 