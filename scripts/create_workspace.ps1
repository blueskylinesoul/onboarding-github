# create_workspace.ps1 — 建立 %USERPROFILE%\AI_Workspace 與五個子資料夾（可重複執行，既有資料夾不受影響）
# 執行方式：powershell -NoProfile -ExecutionPolicy Bypass -File .\create_workspace.ps1
$ErrorActionPreference = 'Stop'
$AiWs = if ($env:AI_WS) { $env:AI_WS } else { Join-Path $env:USERPROFILE 'AI_Workspace' }
foreach ($d in '100_Project','200_Skill_OC','201_Skill_GitHub','300_LLM_wiki','400_Doc') {
  New-Item -ItemType Directory -Force -Path (Join-Path $AiWs $d) | Out-Null
  Write-Host "  ok  $AiWs\$d"
}
