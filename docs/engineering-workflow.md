# 工程作業流程（Engineering Workflow）

## 目標
- 以免費優先（Free-first）建立穩健的 CI / 安全 / 審查 / 文件骨架。
- 不修改業務邏輯；變更僅限流程、文件與 PowerShell 腳本。

## 分支策略
- `main`：受保護分支，僅透過 Pull Request 合併。
- 功能/修正分支：`feature/*`、`fix/*`、`chore/*`、`docs/*`。

## Pull Request 流程
1. 建立分支並提交最小可用變更。
2. 本地執行 `scripts/lint.ps1`、`scripts/test.ps1`。
3. 以 PR 模板撰寫摘要、風險、測試說明並送出審查。
4. 確認 CI（`ci.yml`）與安全掃描（`security.yml`）皆通過。

## CI 與安全
- `.github/workflows/ci.yml`：
  - 觸發於 Push/PR/手動。
  - Ubuntu Runner + PowerShell；呼叫 `scripts/lint.ps1`、`scripts/test.ps1`。
  - 上傳測試與覆蓋率產物（若存在）。
- `.github/workflows/security.yml`：
  - Weekly 排程與 PR 觸發。
  - Semgrep / Gitleaks / Trivy FS，產生 SARIF 並上傳至 Code Scanning。

## 依賴更新
- 使用 `.github/dependabot.yml` 每週檢查 `github-actions` 與常見生態系。

## 提交訊息
- 建議遵循 Conventional Commits。範例：
  - `feat(ci): 新增 CI 工作流`
  - `chore(docs): 補充工程流程`

---
文件維護者：工程化維運。更新日期：2026-03-28。
