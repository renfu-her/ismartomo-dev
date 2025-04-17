# iSmartOmo Flutter App

這是一個使用 Flutter 開發的電子商務應用程式。

## 功能

*   瀏覽商品分類與列表
*   查看產品詳細資訊，包含圖片、價格、描述與選項
*   將商品加入購物車
*   使用者登入與註冊
*   管理收藏清單
*   查看個人資料與訂單資訊 (部分功能待實作)
*   商品搜尋

## 使用技術

*   Flutter
*   Dart
*   Provider (狀態管理)
*   ApiService (與後端 API 互動)
*   UserService (管理使用者狀態)
*   WebView (顯示部分網頁內容)
*   Carousel Slider (圖片輪播)
*   Font Awesome Icons (圖示)

## 開始使用

1.  確保您已安裝 Flutter SDK。
2.  克隆此儲存庫。
3.  在專案根目錄執行 `flutter pub get` 安裝依賴。
4.  執行 `flutter run` 啟動應用程式。

## 專案結構 (部分)

*   `lib/`
    *   `main.dart`: 應用程式進入點，包含首頁、底部導航等。
    *   `services/`: 包含 API 請求 (`api_service.dart`) 和使用者狀態管理 (`user_service.dart`)。
    *   `pages/`: 包含各個頁面的 UI 和邏輯 (如 `category_page.dart`, `product_list_page.dart`, `product_detail_page.dart`, `cart_page.dart`, `profile_page.dart` 等)。
    *   `widgets/`: (可選) 包含可重用的 UI 組件。

## 注意事項

*   部分功能可能仍在開發中。
*   API 端點和行為可能需要根據實際後端進行調整。
*   價格顯示已統一格式為 `$` 開頭且不含小數點。 