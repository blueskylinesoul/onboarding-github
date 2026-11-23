# bootstrap.ps1 — 全新 Windows 電腦的一行啟動腳本（onboarding-github 步驟 0）
#
# 用法（PowerShell 貼上一行）：
#   irm https://raw.githubusercontent.com/<帳號>/onboarding-github/main/bootstrap.ps1 | iex
#
# 會做的事：
#   1. 下載 onboarding-github（Public repo 壓縮檔，不需要 git 或登入）到 %USERPROFILE%\Downloads\onboarding-github
#   2. 檢查 Git for Windows（Claude Code 在 Windows 需要 Git Bash），沒有就詢問後用 winget 安裝
#   3. 檢查 Claude Code，沒有就詢問後用官方安裝腳本安裝
#   4. 詢問後啟動 Claude Code，請它讀取 SKILL.md 並照著執行
#
# 環境變數（選用）：ONBOARDING_REPO、ONBOARDING_DEST、ONBOARDING_TARBALL（測試用）、ONBOARDING_YES=1
# 本檔不加 BOM（irm | iex 以 UTF-8 解碼）。全部包在函式裡：透過 `irm | iex` 執行時，用 return 結束而不會關掉使用者的 PowerShell 視窗。

function Invoke-OnboardingBootstrap {
  $ErrorActionPreference = 'Stop'
  $Repo    = if ($env:ONBOARDING_REPO)    { $env:ONBOARDING_REPO }    else { 'blueskylinesoul/onboarding-github' }
  $Dest    = if ($env:ONBOARDING_DEST)    { $env:ONBOARDING_DEST }    else { Join-Path $env:USERPROFILE 'Downloads\onboarding-github' }
  $Tarball = if ($env:ONBOARDING_TARBALL) { $env:ONBOARDING_TARBALL } else { "https://github.com/$Repo/archive/refs/heads/main.tar.gz" }

  function Say($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
  function Ask($q) {   # 預設 No
    if ($env:ONBOARDING_YES -eq '1') { return $true }
    try { $a = Read-Host "$q [y/N]" } catch { return $false }
    return ($a -match '^(y|yes)$')
  }
  function Refresh-Path {   # 讓剛安裝的程式在目前視窗就能使用
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user;$(Join-Path $env:USERPROFILE '.local\bin')"
  }

  # -------------------------------------------------------------------------
  Say "Step 1: 下載 onboarding-github → $Dest"
  if (Test-Path -LiteralPath (Join-Path $Dest '.git')) {
    Write-Warning "$Dest 是 git repo，為避免覆蓋請改用 git pull，或設定 ONBOARDING_DEST 指定其他位置。"; return
  }
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ("onboarding-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  $tgz = Join-Path $tmp 'main.tar.gz'
  & curl.exe -fsSL -o $tgz $Tarball
  if ($LASTEXITCODE -ne 0) { Write-Warning "下載失敗：$Tarball"; return }
  $src = Join-Path $tmp 'src'; New-Item -ItemType Directory -Force -Path $src | Out-Null
  & tar.exe xzf $tgz -C $src --strip-components=1
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $src 'SKILL.md'))) { Write-Warning '解壓縮失敗或找不到 SKILL.md'; return }
  if (Test-Path -LiteralPath $Dest) { Remove-Item -LiteralPath $Dest -Recurse -Force }
  New-Item -ItemType Directory -Force -Path (Split-Path $Dest) | Out-Null
  Move-Item -LiteralPath $src -Destination $Dest
  Remove-Item -LiteralPath $tmp -Recurse -Force
  Write-Host "  ok  $Dest\SKILL.md"

  # -------------------------------------------------------------------------
  Say 'Step 2: 檢查 Git for Windows（Claude Code 需要 Git Bash）'
  Refresh-Path
  if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "  ok  已安裝：$((Get-Command git).Source)"
  } elseif (Ask '尚未安裝 Git for Windows，要用 winget 安裝嗎？（可能跳出 UAC）') {
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
    Refresh-Path
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Warning '安裝後仍找不到 git，請開新的 PowerShell 視窗後重跑本腳本。'; return }
    Write-Host '  ok  已安裝 git'
  } else {
    Write-Warning '略過。Claude Code 在 Windows 需要 Git for Windows，請安裝後重跑本腳本。'; return
  }

  # -------------------------------------------------------------------------
  Say 'Step 3: 檢查 Claude Code'
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host "  ok  已安裝：$((Get-Command claude).Source)"
  } elseif (Ask '尚未安裝 Claude Code，要用官方安裝腳本（https://claude.ai/install.ps1）安裝嗎？') {
    Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
    Refresh-Path
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { Write-Warning '安裝後仍找不到 claude，請開新的 PowerShell 視窗後重跑本腳本。'; return }
    Write-Host '  ok  已安裝 Claude Code'
  } else {
    Write-Host "  略過。請自行安裝任一 AI CLI，再請它讀取 $Dest\SKILL.md 並照著執行。"; return
  }

  # -------------------------------------------------------------------------
  $prompt = "讀取 $Dest\SKILL.md 並照著執行，從步驟 1 開始（步驟 0 已由 bootstrap.ps1 完成）。<本技能目錄> 即 $Dest。"
  Say 'Step 4: 啟動 Claude Code'
  if (Ask '現在啟動 Claude Code 開始設定嗎？（第一次啟動會先要求登入 Claude 帳號）') {
    & claude $prompt
  } else {
    Write-Host '  之後可自行執行：'
    Write-Host "    claude `"$prompt`""
  }
}

Invoke-OnboardingBootstrap
