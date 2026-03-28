# Phase 2 檢核門檻（Gate）與驗證規則

> 依目前檔案推定（2026-03-28）：本專案處於 Phase 2（骨架驗證）階段，CI 與 Security 已收斂為「先可用、再加嚴」。本文件定義各檢查的門檻分類、通過標準與何時可以進入 Phase 3。

---

## A. 目前 Gate 分類
- 必要檢查（Required）：合併前必須通過的檢查（流程或分支保護強制）。
- 建議檢查（Recommended）：強烈建議執行並通過，但暫未強制。
- 觀察中檢查（Observation）：先觀察噪音與價值，待穩定後再升級門檻。
- 未建置檢查（Not Yet Implemented）：未提供對應流程或門檻。

| 檢查 | 分類 | 說明 |
|---|---|---|
| PR Review | Required | 依 `code_review.md` 清單與 PR 模板；Phase 2 建議即視為必經流程。 |
| CI（lint_and_test） | Recommended →（驗證通過後）升級 Required | 先以 1–3 個 PR 驗證穩定，再設為必須通過的狀態檢查。 |
| Security（Semgrep/Trivy/Gitleaks） | Observation | 已收斂為高價值掃描；先觀察噪音並調整。 |
| 本機 lint / test | Recommended | 提交前自檢，減少 CI 回合。 |
| Release / Deploy Gates | Not Yet Implemented | 屬 Phase 3 規劃，不在本階段。 |

---

## B. 目前可用 Gate（用途 / 通過條件 / 失敗處理 / 是否建議設為必要）

### 1) 本機 lint（scripts/lint.ps1）
- 用途：基礎格式/語法/靜態分析，降低 PR 問題。
- 通過條件：腳本退出碼為 0。
- 失敗處理：依訊息修正檔案後重跑。
- 是否建議設為必要：Recommended（提交前自律要求；不在分支保護內強制）。

### 2) 本機 test（scripts/test.ps1）
- 用途：執行各語言的單元/整合測試（若存在）。
- 通過條件：腳本退出碼為 0；若偵測不到測試則視為成功。
- 失敗處理：修正測試或程式後重跑。
- 是否建議設為必要：Recommended（提交前自律）。

### 3) CI workflow（.github/workflows/ci.yml）
- 用途：在 Ubuntu runner 以 `-NoInstall` 執行 lint/test，條件式設定 Node/Python，並上傳產物（若存在）。
- 通過條件：job 綠燈、無步驟失敗。
- 失敗處理：依步驟輸出修正後重推。
- 是否建議設為必要：先 Recommended；在 1–3 個 PR 均穩定後，改為 Required（於分支保護「必要狀態檢查」中勾選）。

### 4) Security workflow（.github/workflows/security.yml）
- 用途：Semgrep（僅 ERROR、排除 docs/.github/*.md）、Trivy FS（CRITICAL/HIGH）、Gitleaks（redact）。
- 通過條件：無 CRITICAL/HIGH 未處理風險；Semgrep ERROR 新議題已分類（有效/誤報/延後）。
- 失敗處理：修正代碼或調整忽略清單，再重跑；誤報以規則或 allowlist 記錄。
- 是否建議設為必要：Observation（待噪音穩定後，再評估將「Security Scan」加入必要狀態檢查）。

### 5) PR Review
- 用途：依 `code_review.md` 清單進行審查，確保正確性/安全性/可維護性。
- 通過條件：達到所需核准數、未留阻擋性意見。
- 失敗處理：依意見修正後再請審。
- 是否建議設為必要：Required（流程必經；未來可在分支保護中啟用「最少審查者數量」）。

---

## C. Phase 2 完成條件（Definition of Done）
達成以下條件，即可視為 Phase 2 完成：
1. CI 穩定：連續 ≥3 個 PR，CI 成功率 ≥90%，單次執行時間通常 ≤10 分鐘（依目前檔案推定）。
2. Security 噪音可控：
   - Trivy：無未處理的 CRITICAL/HIGH；若為誤報，已記錄原因與處置。
   - Semgrep：ERROR 新議題皆完成分類（有效/誤報/延後），誤報比例可接受（例如 ≤20%）。
   - Gitleaks：無有效憑證外洩；如為誤報已列入忽略策略。
3. PR Review 常態化：所有 PR 皆使用模板並完成自我檢查，至少 1 名審查者核准。
4. 文件可用：`docs/quick-start.md`、`docs/file-guide.md`、`docs/engineering-workflow.md`、`docs/full-process-flow.md`、`docs/phase2-gates.md` 內容一致、可讓新手 30 分鐘內入門。
5. 分支保護設定：將 CI（lint_and_test）設為必要狀態檢查，並要求至少 1 名審查者（以 Repo 設定完成，而非程式碼）。

---

## D. Phase 3 進入條件（何時開始規劃/實作）
僅在下列條件滿足後，才開始 Phase 3（仍屬後續階段，尚未建置）：
- 滿足「Phase 2 完成條件」。
- 最近 ≥3 個 PR 的 CI/Security 維持穩定與可接受噪音。
- 已明確決定發佈渠道（例如行動應用或後端/Web），並完成風險/回滾策略討論。

> 提醒：本文件不代表已經有 GCP/Google Play/Release 流程，僅定義何時「開始規劃」較合理。

---

## E. 驗證建議（下一步如何驗證）
1. 以 1–3 次最小變更 PR 觸發 CI 與 Security；觀察：
   - 執行時間（CI ≤10 分鐘；Security ≤15 分鐘為佳，依目前檔案推定）。
   - 失敗原因（是否為真實問題）。
   - 安全掃描誤報比例。
2. 若結果穩定：將 CI 設為必要狀態檢查；Security 保持觀察並逐步加嚴（例如擴充規則、調整嚴重度）。
3. 記錄決策：把「忽略規則/allowlist/限縮範圍」寫回文件，降低團隊認知成本。

---

## F. 文件同步與導覽
- 本文件為 Gate 與驗證規則的單一來源（SSoT）。
- 延伸閱讀：
  - `docs/engineering-workflow.md`（流程說明）
  - `docs/full-process-flow.md`（總覽圖與檢核點）
  - `docs/quick-start.md`、`docs/file-guide.md`（新手導覽）

> 驗證步驟與案例請參考：`docs/phase2-validation-plan.md`（最小 PR 驗證方案）。
