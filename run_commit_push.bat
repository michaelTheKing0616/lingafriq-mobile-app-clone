@echo off
cd /d "C:\Users\HP\Desktop\LingAfriqMobile\mobile-app-safe-push-michael"
git reset HEAD COMMIT_MSG.txt
git reset HEAD run_commit_push.bat
git commit -F COMMIT_MSG.txt
del COMMIT_MSG.txt
git push michael main
