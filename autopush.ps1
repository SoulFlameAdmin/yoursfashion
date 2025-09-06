# simple auto-commit & push loop for Vercel (ASCII only)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath 'E:\MAGAZIN_SITE'

while ($true) {
  $status = git status --porcelain
  if ($status) {
    git add -A | Out-Null
    $msg = 'auto ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    git commit -m $msg | Out-Null
    try { git push origin main | Out-Null } catch { }
    Write-Host ('pushed ' + $msg)
  }
  Start-Sleep -Seconds 3
}
