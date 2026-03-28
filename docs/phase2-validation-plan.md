# Phase 2 最小 PR 驗證方案

> 依目前檔案推定（2026-03-28）：本專案處於 Phase 2（骨架驗證）階段，CI 與 Security 已收斂為「先可用、再加嚴」。本文件提供 1～3 個最小變更 PR 的驗證方案，讓你用真實 PR 觀察 CI / Security / Gate 的可用性與穩定度。

---

## 驗證目的
- 以最小、可回滾的變更觸發 CI 與 Security，觀察：
  - 執行時間（CI、Security）
  - 成功率與失敗原因（是否為真實問題）
  - 安全掃描誤報情況
  - artifact 是否正確上傳/忽略
- 驗證後，據以更新 Gate 分類（Required/Recommended/Observation），判定 Phase 2 是否可完成。

---

## 建議 PR 驗證案例（1～3 個）

### 案例 A：文件微調（Baseline 成功路徑）
- 變更內容：對 `docs/quick-start.md` 或 `docs/file-guide.md` 做小幅度語句潤飾（不引入行尾空白、不新增可疑字串）。
- 為什麼適合驗證：
  - 對代碼零影響、易於回滾。
  - 可驗證 CI/ Security 的「成功」基線執行時間與輸出（通常無 artifact 亦應正常忽略）。
- 預期會觸發：CI 工作（lint/test，-NoInstall）、Security 工作（Semgrep ERROR 級、Trivy CRITICAL/HIGH、Gitleaks）。
- 要觀察：
  - CI 總耗時（目標 ≤10 分鐘）。
  - Security 總耗時（目標 ≤15 分鐘）。
  - 是否產生任何警示或誤報（預期無）。
- 成功條件：CI/ Security 皆成功，無阻擋性警示。
- 失敗判讀：
  - 若 CI 失敗：看 lint/test 步驟輸出，多半為格式或腳本環境問題。
  - 若 Security 出現警示：檢查是否為誤報；若是，記錄原因與後續調整方向（暫不改工作流）。

### 案例 B：刻意引發並修復 Lint 失敗（Gate 驗證）
- 變更內容：
  1) PR 的第一個 commit 在某一個 `.md` 檔案尾端故意加行尾空白，讓 `scripts/lint.ps1` 失敗。
  2) 第二個 commit 移除行尾空白，使 Lint 恢復通過。
- 為什麼適合驗證：
  - 驗證 CI 的失敗/恢復流程是否清楚，Reviewer 是否能快速定位問題與回復綠燈。
- 預期會觸發：CI 工作（lint 先紅再綠）；Security 工作（應不受影響）。
- 要觀察：
  - 失敗 Job 的錯誤訊息是否易懂（能指出檔案與行數）。
  - 修正後重新跑的耗時與穩定度。
- 成功條件：
  - 第一次跑因 Lint 失敗而紅。
  - 修正後重新跑即綠，無額外干擾。
- 失敗判讀：
  - 若紅燈原因不明或訊息不清，紀錄為改善點（例如：增加摘要內容、或未來引入更明確報表）。

### 案例 C：artifact 上傳驗證（最小人工產物）
- 變更內容：在 PR 中新增一個極小的占位檔案 `artifacts/test-results/.keep`（文字檔），不影響業務，僅用於驗證 `actions/upload-artifact` 的「有檔案→應被上傳」。
- 為什麼適合驗證：
  - 目前專案多為文件，預設無測試報表；此法能最小成本驗證 artifact 上傳路徑與權限是否正確。
- 預期會觸發：CI 工作（artifact 上傳應顯示成功）；Security 工作不受影響。
- 要觀察：
  - CI 步驟「Upload test results」是否顯示已上傳 1 個 artifact，並可於 Job 頁下載。
- 成功條件：可在 CI artifacts 看到 `.keep`（或同名占位檔）。
- 失敗判讀：
  - 若無上傳：檢查路徑 `artifacts/test-results/**` 是否正確；或檔案是否被忽略。

---

## 每個案例的步驟（範例流程）
1. 建立 feature 分支（例如 `feature/phase2-validate-a`）。
2. 套用對應案例的最小變更，推到遠端並開 PR 指向 `develop` 或 `main`（依目前檔案推定）。
3. 等待 CI/Security 全數跑完，記錄耗時、輸出與是否成功。
4. 對案例 B：在同一 PR 追加修復 commit，觀察重新執行結果。
5. 對案例 C：確認 artifact 是否可下載且內容正確。

---

## 觀察指標（建議量化）
- CI：總耗時、失敗率、主要失敗原因類型（lint/test/環境）。
- Security：總耗時、警示數量（Semgrep ERROR、Trivy CRITICAL/HIGH、Gitleaks）、誤報比例。
- artifact：是否有正確上傳/顯示可下載；若無報表，是否如預期被忽略（不報錯）。

---

## 驗證完成後如何更新 Gate 分類
- 若連續 ≥2（建議 2～3）個 PR 均達成：
  - CI：將「lint_and_test」加入分支保護的必要狀態檢查（由 Repo 設定完成）。
  - Security：維持 Observation；若警示量低且可信度高，再討論是否逐步納入必要條件（可先從 Trivy CRITICAL/HIGH 開始）。
- 在 `docs/phase2-gates.md` 更新：
  - 將 CI 標記為 Required（若符合條件）。
  - 記錄 Security 的觀察結果、誤報處理與下一步收斂。

---

## 何時可以判定 Phase 2 完成
- 滿足 `docs/phase2-gates.md` 中的「Phase 2 完成條件」，並完成上述 Gate 更新。
- 建議觀察窗口：至少 1～2 週、≥3 個 PR 具代表性的結果。

---

## 哪些情況代表還不能進入 Phase 3
- CI 不穩定或平均耗時過長（超過目標）且未找到原因。
- Security 誤報比例偏高，尚未有清楚的忽略策略或規則調整方向。
- PR Review 未常態化（模板未使用、無所需核准）。
- 文件不足以讓新手 30 分鐘內入門。
