# Auto-commit & push on file changes (HTML/CSS/JS) for Vercel
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $path

$filter = "*.*"
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $path
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# debounce флаг, за да не пушва по 10 пъти
$script:pending = $false
$extensions = @(".html",".css",".js",".json",".png",".jpg",".jpeg",".svg",".ico",".webp",".txt")

Register-ObjectEvent -InputObject $watcher -EventName Changed -SourceIdentifier FSChanged -Action {
    if ($script:pending) { return }

    $eventFile = $Event.SourceEventArgs.FullPath.ToLower()
    if ($eventFile -like "*\.git*") { return }

    $isTracked = $false
    foreach ($ext in $extensions) {
        if ($eventFile.EndsWith($ext)) { $isTracked = $true; break }
    }
    if (-not $isTracked) { return }

    $script:pending = $true
    Start-Sleep -Seconds 2  # debounce

    try {
        git add -A | Out-Null
        $msg = "auto: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $status = git status --porcelain
        if ($status.Length -gt 0) {
            git commit -m $msg | Out-Null
            git push origin main | Out-Null
            Write-Host "✓ Deployed: $msg"
        } else {
            Write-Host "• No changes to commit"
        }
    } catch {
        Write-Host ("⚠️ Git error: " + $_.Exception.Message)
    } finally {
        $script:pending = $false
    }
}

Write-Host ("Watching '" + $path + "' ... Press Ctrl+C to stop.")
while ($true) { Start-Sleep -Seconds 1 }
