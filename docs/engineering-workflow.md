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

## CI 定位與策略補充（收斂後 / Phase 2）
- 目前 CI 採最小化策略，主要目的為驗證骨架與流程是否可用。
- 在 CI 內以 -NoInstall 執行 scripts/lint.ps1、scripts/test.ps1，避免重複安裝、縮短時間。
- 語言 setup 收斂為條件式 Node/Python（依目前檔案推定）；其他語言先由腳本偵測，暫不主動安裝。
- 本階段仍為 Phase 2 驗證，不進入 deploy/release。

## Security 定位與策略補充（收斂後 / Phase 2）
- 目標：在骨架驗證階段降低噪音、確保流程可用，再逐步加嚴。
- Semgrep：改以僅關注 ERROR 級，並排除 docs/.github/*.md 等非程式碼目錄，降低誤報（依目前檔案推定）。
- Gitleaks：維持檔案樹掃描與遮罩輸出（redact），先觀察是否產生誤報，再視需要加入 allowlist（後續擴充）。
- Trivy FS：聚焦 CRITICAL/HIGH 嚴重度，先觀察趨勢再決定是否擴大範圍。
- 仍屬 Phase 2：先可用，逐步調整與加嚴；尚未進入 deploy/release。

## 合併門檻（Gate）與驗證規則
- 本階段（Phase 2）以「先可用、再加嚴」為準則：Required/Recommended/Observation 的完整定義與門檻請見 `docs/phase2-gates.md`。
- 建議：PR Review 為必經流程；CI（lint_and_test）經 1–3 次 PR 驗證穩定後，設為必要狀態檢查；Security 先觀察噪音再逐步加嚴。

> 驗證計畫：請依 `docs/phase2-validation-plan.md` 進行最小 PR 驗證（A/B/C 案例），並將結果回寫至 `docs/phase2-gates.md`。
