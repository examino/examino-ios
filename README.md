# 澳門藥物庫 (Examino) — iOS 版

examino.github.io(澳門藥物監督管理局 ISAF 登記藥品資料庫)的原生 iOS 移植版。

- 語言:Swift 5 + SwiftUI,最低 iOS 16.0,無任何第三方依賴
- 數據:與 Android 版同源的內嵌 JSON(9,126 種登記藥品),完全離線
- 界面:與 Android 版一致的重新設計(無密碼攔截、即時搜尋、篩選彈窗、詳情頁、CSV 匯出、搜尋歷史)

## 功能對照

| 功能 | 說明 |
|------|------|
| 即時搜尋 | 輸入 250ms 防抖即出結果,無需回車 |
| 多詞組合搜尋 | 空格分隔、每詞都須匹配(子串即前綴),`amox clav` → AUGMENTIN/AMOKSIKLAV |
| 篩選彈窗 | 固定高度不跳動;一/二/三級 ATC(全部中文名)+ 劑型 + 法律分類 |
| 詳情頁 | 全字段、資料修正標記、外部藥物資訊鏈接(Drugs.com/OpenDrug/Medscape) |
| CSV 匯出 | 帶 BOM UTF-8,經系統分享面板分享,Excel 直接開啟 |
| 搜尋歷史 | 輸入停頓 1.2s 自動記錄(最近 12 條),可清除 |
| 應用圖標 | 青藍漸變 + 白色藥丸(單尺寸 1024,系統自動裁切圓角) |

## 構建(iOS 需要 macOS + Xcode 15+)

1. 用 Xcode 開啟 `Examino.xcodeproj`
2. 在 Signing & Capabilities 中選擇你的開發團隊(`DEVELOPMENT_TEAM`)
3. 選擇模擬器或真機,⌘R 運行

或命令行:

```bash
xcodebuild -project Examino.xcodeproj -scheme Examino -destination 'generic/platform=iOS Simulator' build
```

> 注意:本工程在 Windows 上編寫,無法在此環境編譯驗證;首次在 Xcode 中打開後如有籤名或部署版本提示,按上文步驟調整即可。

## 目錄結構

```
Examino.xcodeproj/       Xcode 工程
Examino/
  ExaminoApp.swift       入口 + 根視圖 + 分享面板橋接
  Models/Drug.swift      數據模型
  Data/DrugRepository.swift  載入/搜尋/ATC 樹/CSV/鏈接
  Data/*.json            內嵌數據(與 Android 版同源)
  ViewModels/AppViewModel.swift  狀態 + 雙通道防抖
  Views/HomeView.swift   首頁(搜索/歷史/結果/匯出)
  Views/FilterSheet.swift 篩選彈窗(固定高度)
  Views/DetailView.swift 藥品詳情
  Views/Theme.swift      主題色/格式輔助
  Assets.xcassets        應用圖標
  Info.plist
```

## 與 Android 版的差異(iOS 平台適配)

- SwiftUI 原生組件替代 Material 3;彈窗用 `.presentationDetents([.height(560)])` 固定高度
- 下拉選擇用 `Menu` 實現(ExposedDropdownMenu 的 SwiftUI 對等)
- 分享面板:UIActivityViewController 橋接
- 歷史存儲:UserDefaults(對等 SharedPreferences)

## 數據更新

替換 `Examino/Data/*.json` 後重新構建即可(結構與網站 mirror 提取腳本一致)。
## 用 GitHub Actions 構建(無需本機 Mac)

`.github/workflows/ios-build.yml` 提供兩個 job:

1. **build-simulator**(預設執行):macOS runner 上 `xcodebuild` 編譯模擬器版,產出 `Examino-simulator.app` 工件(artifact),用於驗證代碼可編譯、可在模擬器安裝。✅ 已在真实 Xcode 環境通過驗證。
2. **build-ipa**(可選):配置 Apple Developer 證書後自動產出真機安裝用的 `Examino.ipa`(ad-hoc)。

使用步驟:

```bash
git init && git add . && git commit -m "Examino iOS"
# 推到 GitHub 後,在 repo 的 Actions 頁面就會看到 iOS Build
```

模擬器驗證(無需任何證書):

- 推到 GitHub → Actions → iOS Build → build-simulator 完成 → 下載 `Examino-simulator.app`
- 在 Mac 上:`xcrun simctl install booted Examino-simulator.app`

真機 .ipa(需要 Apple Developer 帳號):

> 先到 repo Settings → Secrets and variables → Actions → **Variables** 添加 `BUILD_IPA=true`,否則 build-ipa job 會自動跳過。

1. 在 repo Settings → Secrets and variables → Actions 添加:
   - `IOS_CERT_BASE64`:發佈/開發證書 p12 的 base64(`base64 -i cert.p12 -o cert.b64` 後複製內容)
   - `IOS_CERT_PASSWORD`:p12 密碼
   - `IOS_PROVISIONING_B64`:包含你設備 UDID 的 ad-hoc 描述檔 base64
   - `IOS_TEAM_ID`:團隊 ID(如 ABCDE12345)
2. 重新推送或手動觸發 workflow,`build-ipa` job 會自動運行,下載 `.ipa`,用 Apple Configurator / Xcode 安裝到真機。

> 免費套餐的 macOS runner 按 10 倍計費(1 分鐘 macOS = 10 分鐘額度),個人倉庫每月 2,000 分鐘額度約可跑 5–8 次完整構建;`build-ipa` 依賴 `build-simulator`(needs),跳過模擬器 job 可省一半時間(改 `needs: []`)。
