# 快速開始（Quick Start）

歡迎！這份文件帶你從 0 到 1 了解目前工程化骨架與基本操作。

## 我們已完成什麼
- 建立「免費優先」的工程骨架：
  - CI：`.github/workflows/ci.yml` 在 Ubuntu runner 上以 PowerShell 執行 `scripts/lint.ps1`、`scripts/test.ps1`，條件式設定必要語言環境，並上傳測試/覆蓋率產物（若存在）。
  - 安全：`.github/workflows/security.yml` 執行 Semgrep/Gitleaks/Trivy FS 並上傳 SARIF。
  - 相依更新：`.github/dependabot.yml` 每週檢查 `github-actions` 與常見生態系並發 PR。
  - 協作文件：`AGENTS.md`、`code_review.md`、`docs/engineering-workflow.md`、PR 模板。
  - 本機腳本：`scripts/lint.ps1`、`scripts/test.ps1`。

## 現在可以做什麼
- 本機先跑 Lint 與 Test，修正問題後提交。
- 建立 PR（會套用模板），由 CI 與安全掃描自動把關。
- 等待 Dependabot 每週提出相依更新 PR 並審閱。

## 建議第一步先看哪些文件
- `docs/file-guide.md`：快速理解每個檔案用途。
- `docs/engineering-workflow.md`：分支/PR/CI 的全貌。
- `AGENTS.md`：日常要遵循的原則與邊界。
- `code_review.md`：審查時的核對清單。

## 本機如何執行 Lint（scripts/lint.ps1）
要求：PowerShell 7+。

在專案根目錄執行：
- Windows：
  - `pwsh -File scripts/lint.ps1`
  - 或 `./scripts/lint.ps1`
- 參數：
  - `-NoInstall`：略過安裝步驟（若你已安裝依賴；CI 會預設使用此參數）。

退出碼：0 代表通過或安全略過；非 0 代表檢查失敗。

## 本機如何執行 Test（scripts/test.ps1）
在專案根目錄執行：
- `pwsh -File scripts/test.ps1`
- 或 `./scripts/test.ps1`

行為：自動偵測 Node/Python/.NET/Go/Rust 的常見測試命令；若未偵測到任何測試，會跳過並以成功結束。

## GitHub Actions 何時觸發
- `ci.yml`：
  - push 至 `main` / `master` / `develop` / `feature/**` / `fix/**`
  - pull_request 指向 `main` / `master` / `develop`
  - 手動 `workflow_dispatch`
- `security.yml`：
  - push / pull_request 指向 `main` / `master` / `develop`
  - 每週一 03:00 UTC 的排程
  - 手動 `workflow_dispatch`

## 下一步建議
- 建立最小可行的單元測試與語言專屬 lint 設定（例如 ESLint/pytest/Go toolchain 等）。
- 視需求擴充 `scripts/lint.ps1`、`scripts/test.ps1` 的規則與輸出（例如 JUnit/XML 報表位置）。
- 啟用分支保護與必要的審查規則，並設定 Code Scanning 警示門檻。
- 規劃 Secrets（僅在 Repo/Org 設定中配置；避免提交到版本控制）。
- 定期處理 Dependabot PR，維持安全與可維護性。

## 延伸閱讀
- [全流程總覽](full-process-flow.md)
- [工程作業流程](engineering-workflow.md)

