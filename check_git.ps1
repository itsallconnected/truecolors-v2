Write-Host "===== Git Remote Information ====="
git remote -v

Write-Host "`n===== Git Origin URL ====="
git remote get-url origin

Write-Host "`n===== Repository Directory ====="
Get-Location

Write-Host "`n===== Git Log (Recent Commits) ====="
git log --oneline -n 5

Write-Host "`n===== Git Config ====="
git config --local --list 