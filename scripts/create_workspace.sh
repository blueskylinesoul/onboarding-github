#!/bin/bash
# create_workspace.sh — 建立 ~/AI_Workspace 與五個子資料夾（可重複執行，既有資料夾不受影響）
set -euo pipefail
AI_WS="${AI_WS:-$HOME/AI_Workspace}"
for d in 100_Project 200_Skill_OC 201_Skill_GitHub 300_LLM_wiki 400_Doc; do
  mkdir -p "$AI_WS/$d" && echo "  ok  $AI_WS/$d"
done
