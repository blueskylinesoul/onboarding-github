---
name: onboarding-github
description: >-
  新電腦（macOS / Windows）AI 工作環境設定的第一步：安裝 git 與 GitHub CLI（gh）、登入 GitHub、
  設定 git 作者（建議 noreply email），並建立 ~/AI_Workspace 與五個子資料夾，最後取回
  onboarding-env-config 技能並交棒給它。本技能為 Public repo，不含任何個人資訊。
  First step of onboarding a new Mac/Windows machine: install git and gh, log in to GitHub,
  set the git author, create the AI_Workspace folder tree, then hand off to onboarding-env-config.
---

# Onboarding（一）— GitHub 與資料夾

新電腦的設定分成兩個技能，依序執行：

| 順序 | 技能 | 做什麼 | Repo |
|---|---|---|---|
| 1 | **onboarding-github**（本技能） | 安裝 git / gh、登入 GitHub、建立 `AI_Workspace` 資料夾 | Public |
| 2 | **onboarding-env-config** | 取回設定 repo、全域設定檔連結、技能同步、YOLO alias、取回各 skill / project | Private |

本技能放在 Public repo，所以新電腦**不用登入**就能下載；登入之後才拿得到 Private 的第二個技能。

## 執行原則（必須遵守）
1. **未經同意不先執行**：凡是 AI 自行提出、但使用者尚未明確同意的「預設做法」或待決選項
   （例如選定作者資訊、覆蓋既有資料夾），一律先詢問並等待回覆。只有需求中明確、無歧義的部分可以直接做。
2. **本 repo 是 Public**：不可寫入任何個人資訊（帳號名稱、email、個人路徑、token）。範例一律用 `<帳號>` 等佔位字。
   本 repo 的 commit 作者 email 必須是 GitHub noreply email（見步驟 4），不可用個人 email。
3. 已完成的步驟（例如 `git --version`、`gh auth status` 正常）直接略過。

## 執行流程

整體順序：**0 取得本技能 → 1 判斷 OS → 2 安裝 git → 3 安裝 gh 並登入 → 4 git 作者 → 5 建立資料夾
→ 6 取回兩個 onboarding 技能 → 7 驗證並交棒**。

### 步驟 0. 取得本技能（全新電腦，由使用者手動執行）

全新電腦上還沒有 git，所以用系統內建的 `curl` + `tar` 下載 Public repo 的壓縮檔
（macOS 內建；Windows 10 1803 以後內建 `curl.exe` 與 `tar.exe`）：
```bash
# macOS
mkdir -p ~/Downloads/onboarding-github && cd ~/Downloads/onboarding-github
curl -fsSL https://github.com/<帳號>/onboarding-github/archive/refs/heads/main.tar.gz | tar xz --strip-components=1
```
```powershell
# Windows（PowerShell）
New-Item -ItemType Directory -Force "$env:USERPROFILE\Downloads\onboarding-github" | Out-Null
Set-Location "$env:USERPROFILE\Downloads\onboarding-github"
curl.exe -fsSL -o main.tar.gz https://github.com/<帳號>/onboarding-github/archive/refs/heads/main.tar.gz
tar.exe xzf main.tar.gz --strip-components=1; Remove-Item main.tar.gz
```
接著在 AI CLI（例如 Claude Code）中請 AI：「讀取 `~/Downloads/onboarding-github/SKILL.md` 並照著執行」。
下文的 `<本技能目錄>` 指的就是這個暫存位置；步驟 6 會把正式版本放進 `AI_Workspace`。

### 步驟 1. 判斷作業系統
- macOS（`uname` 為 `Darwin`）→ 以下使用 macOS 的做法與 `.sh` 腳本。
- Windows → 以下使用 winget 與 `.ps1` 腳本。

### 步驟 2. 安裝 git
以下每個小步驟都要先向使用者說明，並取得同意後才執行。
- macOS：檢查 `xcode-select -p`。若沒有安裝，請使用者執行 `! xcode-select --install`，
  在跳出的視窗按「安裝」，等它完成（約 5～15 分鐘）。之後用 `git --version` 確認。
- Windows：`winget install --id Git.Git -e`（可能跳出 UAC），完成後開新視窗，用 `git --version` 確認。
  建議設定 `git config --global core.autocrlf input`，避免換行符號被改動。

### 步驟 3. 安裝 GitHub CLI（`gh`）並登入

**3-1. 安裝 `gh`**
- macOS：**不要用 Homebrew**。它的安裝需要 sudo 密碼互動，在 AI 的非互動 shell（或使用者用 `!` 執行）
  會失敗，錯誤訊息是 `Insufficient permissions to install Homebrew`。
  改從 GitHub 官方 release 下載執行檔放到 `~/.local/bin`，不需要 sudo：
  ```bash
  ARCH=$( [ "$(uname -m)" = arm64 ] && echo arm64 || echo amd64 )
  V=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | grep -m1 '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  TMP=$(mktemp -d) && curl -fsSL -o "$TMP/gh.zip" "https://github.com/cli/cli/releases/download/v${V}/gh_${V}_macOS_${ARCH}.zip"
  unzip -oq "$TMP/gh.zip" -d "$TMP" && mkdir -p ~/.local/bin && cp "$TMP/gh_${V}_macOS_${ARCH}/bin/gh" ~/.local/bin/gh
  xattr -d com.apple.quarantine ~/.local/bin/gh 2>/dev/null; ~/.local/bin/gh --version
  ```
  若 `~/.zshrc` 沒有把 `~/.local/bin` 加入 PATH，詢問使用者後再補上 `export PATH="$HOME/.local/bin:$PATH"`。
- Windows：`winget install --id GitHub.cli -e`，完成後開新視窗，用 `gh --version` 確認。

**3-2. 登入 GitHub**
- AI 在**背景**執行：`gh auth login --hostname github.com --git-protocol https --web`
  （macOS 若 PATH 尚未生效，用 `~/.local/bin/gh`）。
- 讀取輸出中的 8 碼一次性驗證碼（One-time code，也會自動複製到剪貼簿），交給使用者，
  並請使用者開啟 https://github.com/login/device 貼上驗證碼、按 Authorize。
- 背景指令結束後，用 `gh auth status` 確認顯示 `Logged in` 和帳號名稱。
- 接著執行 `gh auth setup-git`，讓 `git push` / `git pull` 自動使用 gh 的登入資訊
  （會在 `~/.gitconfig` 加入 `credential.https://github.com.helper`）。
  沒做這步時，`gh repo create --push` 雖然能成功，但之後的 `git push` 會報錯
  `could not read Username for 'https://github.com'`。
  用 `git config --global --get-all credential.https://github.com.helper` 確認有指向 gh。

### 步驟 4. 設定 git 作者
commit 會記錄作者的名字與 email，Public repo 的訪客都看得到，所以建議使用 GitHub 提供的 **noreply email**。
1. 取得 noreply email（格式 `<數字 ID>+<帳號>@users.noreply.github.com`）：
   ```bash
   gh api user -q '"\(.id)+\(.login)@users.noreply.github.com"'
   ```
2. **詢問**使用者要用的名字，以及要用 noreply email 還是其他 email，不可自行假設。確認後才執行：
   ```bash
   git config --global user.name "<名字>"
   git config --global user.email "<email>"
   ```
3. 建議使用者到 GitHub「Settings → Emails」勾選「Keep my email addresses private」
   與「Block command line pushes that expose my email」，避免不小心用個人 email push。
4. 若全域設定使用個人 email，Public repo（例如本技能）內要另外設定 repo 專用的 noreply email：
   `git -C <repo> config user.email "<noreply email>"`。

### 步驟 5. 建立 AI_Workspace 資料夾結構
```bash
bash "<本技能目錄>/scripts/create_workspace.sh"
```
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<本技能目錄>\scripts\create_workspace.ps1"
```
建立在使用者資料夾（`~` / `%USERPROFILE%`）下，既有資料夾與內容不會被更動：
```
AI_Workspace/
├── 100_Project/
├── 200_Skill_OC/
├── 201_Skill_GitHub/
├── 300_LLM_wiki/
└── 400_Doc/
```

### 步驟 6. 取回兩個 onboarding 技能到正式位置
用 `gh api user -q .login` 取得帳號名稱，把兩個技能 clone 到 `AI_Workspace/200_Skill_OC/`。
目標資料夾已經是 git repo 就改用 `git -C <資料夾> pull`；資料夾存在但不是 git repo 時，先詢問使用者如何處理。
```bash
U=$(gh api user -q .login)
gh repo clone "$U/onboarding-github"     ~/AI_Workspace/200_Skill_OC/onboarding-github
gh repo clone "$U/onboarding-env-config" ~/AI_Workspace/200_Skill_OC/onboarding-env-config
```
```powershell
$U = gh api user -q .login
gh repo clone "$U/onboarding-github"     "$env:USERPROFILE\AI_Workspace\200_Skill_OC\onboarding-github"
gh repo clone "$U/onboarding-env-config" "$env:USERPROFILE\AI_Workspace\200_Skill_OC\onboarding-env-config"
```
完成後，詢問使用者是否刪除步驟 0 的暫存資料夾（`~/Downloads/onboarding-github`）。

### 步驟 7. 驗證並交棒
```bash
git --version; gh auth status; git config --global user.name; git config --global user.email
ls ~/AI_Workspace ~/AI_Workspace/200_Skill_OC
```
```powershell
git --version; gh auth status; git config --global user.name; git config --global user.email
Get-ChildItem $env:USERPROFILE\AI_Workspace, $env:USERPROFILE\AI_Workspace\200_Skill_OC
```
回報安裝了什麼、登入的帳號、git 作者設定，然後**接著執行 onboarding-env-config**：
此時各 CLI 還看不到它（它的技能同步步驟才會建立連結），請 AI 直接讀取
`~/AI_Workspace/200_Skill_OC/onboarding-env-config/SKILL.md` 並照著執行。
