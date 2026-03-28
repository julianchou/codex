# 檔案用途指南（File Guide）

本文件說明目前工程化骨架中每個關鍵檔案的用途、何時使用、主要讀者、修改頻率，以及與其他檔案之間的關係，協助新手快速建立整體觀念。

---

## AGENTS.md
1) 這個檔案是做什麼的
- 專案的協作與工程化指引。定義「免費優先」原則、只新增流程/文件/PowerShell 腳本、不提交 Secrets、分支與提交訊息建議等。

2) 什麼時候會用到
- 新人加入或開始動手修改流程/文件/腳本前先閱讀。
- 調整 CI / 安全掃描 / 審查規範時。

3) 主要是誰會看/會用
- 全體開發者、維運人員、審閱者。

4) 是否需要常修改
- 低到中。只有在流程或規範有重大調整時才更新。

5) 和其他檔案有什麼關係
- 作為整體規範的入口，涵蓋下列所有檔案的定位與使用方式。

---

## .github/workflows/ci.yml
1) 這個檔案是做什麼的
- GitHub Actions 的 CI 工作流：在 Ubuntu runner 上以 PowerShell 執行 `scripts/lint.ps1` 與 `scripts/test.ps1`，並條件式安裝常見語言環境；上傳測試/覆蓋率產物（如存在）。

2) 什麼時候會用到
- 觸發時機：push（main/master/develop/feature/**/fix/**）、pull_request（至 main/master/develop）以及手動（workflow_dispatch）。

3) 主要是誰會看/會用
- 開發者與審閱者（看 CI 是否為綠）；CI/機器會自動執行。

4) 是否需要常修改
- 中。新增語言、調整安裝版本或改變 Lint/Test 行為時會更新。

5) 和其他檔案有什麼關係
- 呼叫 `scripts/lint.ps1`、`scripts/test.ps1`；PR 建立時會與 `.github/pull_request_template.md`、`code_review.md` 搭配使用。

---

## .github/workflows/security.yml
1) 這個檔案是做什麼的
- 免費安全掃描工作流：Semgrep（SAST）、Gitleaks（Secrets 掃描）、Trivy FS（檔案/相依弱點），並上傳 SARIF 至 GitHub Code Scanning。

2) 什麼時候會用到
- 觸發時機：push、pull_request（至 main/master/develop）、每週一 03:00 UTC 的排程，以及手動觸發。

3) 主要是誰會看/會用
- 維運/審閱者與開發者，用於檢視安全報告與趨勢。

4) 是否需要常修改
- 中。新增/調整規則、調整嚴重度或忽略清單時會更新。

5) 和其他檔案有什麼關係
- 與 CI 同屬自動化流程；其結果會影響 PR 審查（參考 `code_review.md` 與 PR 模板）。

---

## .github/dependabot.yml
1) 這個檔案是做什麼的
- 定義 Dependabot 的更新策略（每週）。涵蓋 `github-actions` 與常見生態系，集中管理相依更新 PR。

2) 什麼時候會用到
- 排程到時自動發 PR；或手動觸發 Dependabot 檢查時。

3) 主要是誰會看/會用
- 維運者與負責相依更新的開發者（審閱/合併 PR）。

4) 是否需要常修改
- 低到中。依專案實際使用的生態系與更新頻率調整即可。

5) 和其他檔案有什麼關係
- Dependabot 產生的 PR 會套用 PR 模板並觸發 CI 與安全掃描工作流。

---

## .github/pull_request_template.md
1) 這個檔案是做什麼的
- PR 的固定模板與自我檢查清單，提醒作者描述變更、測試方式、風險與回滾方案，並確認已跑 lint/test、無敏感資訊。

2) 什麼時候會用到
- 建立 PR 時自動載入。

3) 主要是誰會看/會用
- PR 作者與審閱者。

4) 是否需要常修改
- 低。可依團隊文化微調欄位與語氣。

5) 和其他檔案有什麼關係
- 要求作者先執行 `scripts/lint.ps1`、`scripts/test.ps1`；審閱時搭配 `code_review.md` 與工作流結果。

---

## code_review.md
1) 這個檔案是做什麼的
- 統一的程式碼審查清單與流程建議，涵蓋正確性、安全性、可讀性、效能與回滾策略。

2) 什麼時候會用到
- 進行 PR 審查前與審查過程中。

3) 主要是誰會看/會用
- 審閱者、PR 作者。

4) 是否需要常修改
- 低到中。當團隊對品質門檻有調整時更新。

5) 和其他檔案有什麼關係
- 與 CI/Security 工作流結果密切相關；PR 模板會提示遵循此清單。

---

## docs/engineering-workflow.md
1) 這個檔案是做什麼的
- 工程作業流程：分支策略、PR 流程、CI/安全掃描責任、依賴更新節奏與提交訊息建議。

2) 什麼時候會用到
- 新人上手、規劃需求/分支、送出 PR 前的核對。

3) 主要是誰會看/會用
- 全體開發者與維運者。

4) 是否需要常修改
- 中。當流程或策略更新時同步修訂。

5) 和其他檔案有什麼關係
- 全面性說明 `ci.yml`、`security.yml`、`dependabot.yml` 的定位與觸發時機，並連動 `AGENTS.md` 的原則。

---

## scripts/lint.ps1
1) 這個檔案是做什麼的
- 跨語言 Lint 腳本：行尾空白偵測、PowerShell（PSScriptAnalyzer）、Node/TS（npm/yarn/pnpm + eslint）、.NET（dotnet format）、Go（gofmt）、Python（ruff）。工具不存在時盡量降級或略過。

2) 什麼時候會用到
- 本機提交前自檢；CI 的 `ci.yml` 會自動呼叫。

3) 主要是誰會看/會用
- 開發者與 CI。

4) 是否需要常修改
- 中。隨專案語言/工具增加而擴充規則或行為。

5) 和其他檔案有什麼關係
- 被 `ci.yml` 呼叫；PR 模板要求作者先執行它。

---

## scripts/test.ps1
1) 這個檔案是做什麼的
- 跨語言 Test 腳本：偵測並執行 Node/Python/.NET/Go/Rust 常見測試命令；若未偵測到測試則跳過但回傳成功，避免阻擋 CI。

2) 什麼時候會用到
- 本機驗證與 CI 自動化測試階段。

3) 主要是誰會看/會用
- 開發者與 CI。

4) 是否需要常修改
- 中。依專案測試框架與報告輸出方式調整。

5) 和其他檔案有什麼關係
- 被 `ci.yml` 呼叫；測試與覆蓋率成果（若有）會上傳為 CI 產物。

---

## 建議新手閱讀順序
- 1) `docs/quick-start.md`：先了解能做什麼與如何操作。
- 2) `docs/file-guide.md`：理解每個檔案的定位。
- 3) `docs/engineering-workflow.md`：掌握分支/PR/CI 流程。
- 4) `AGENTS.md`、`code_review.md`：日常遵循的規範與審查清單。
- 5) `.github/pull_request_template.md`：建立 PR 時照表填寫。

## 先不要亂改的檔案
- `.github/workflows/*.yml`：除非明確需要或經維運者同意。
- `.github/dependabot.yml`：若不清楚影響，先以 Issue/PR 討論調整。
- `scripts/*.ps1` 的共用段落：避免破壞跨語言偵測與退出碼邏輯。

## 未來會持續擴充的檔案
- `scripts/lint.ps1`、`scripts/test.ps1`：隨語言與框架擴充。
- `docs/engineering-workflow.md`、`code_review.md`：隨流程成熟調整。
- `AGENTS.md`：當規範有重大更新時同步。
