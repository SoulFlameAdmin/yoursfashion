# autopush.ps1 — auto commit/push към GitHub само при промени

$Branch   = "main"
$RepoPath = "E:\MAGAZIN_SITE"

Set-Location $RepoPath

Write-Host "Start watching $RepoPath (branch: $Branch). Press Ctrl+C to stop."

while ($true) {
    $status = git status --porcelain
    if (-not [string]::IsNullOrWhiteSpace($status)) {
        git add -A | Out-Null
        $diff = git diff --cached --name-status
        if (-not [string]::IsNullOrWhiteSpace($diff)) {
            $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $msg = "auto: $stamp"
            git commit -m $msg | Out-Host
            git push origin $Branch | Out-Host
            Write-Host "Published: $msg"
        }
    }
    Start-Sleep -Seconds 20
}
