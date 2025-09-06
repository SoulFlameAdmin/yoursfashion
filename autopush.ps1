# autopush.ps1 — авто commit/push към GitHub само при промени

# ----- НАСТРОЙКИ -----
$Branch = "main"
$RepoPath = "E:\MAGAZIN_SITE"
$IntervalSec = 20          # колко често да проверява (секунди)
$UserName = "SoulFlameAdmin"   # опц. за git config, ако не е сетнато
$UserEmail = "you@example.com" # опц. за git config, ако не е сетнато
# ----------------------

Set-Location $RepoPath

# Увери се, че git е конфигуриран локално (изпълнява се веднъж)
git config user.name  | Out-Null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace((git config user.name))) { git config user.name $UserName }
git config user.email | Out-Null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace((git config user.email))) { git config user.email $UserEmail }
# Запомняне на креденшъли (Git Credential Manager)
git config credential.helper manager-core | Out-Null

Write-Host " Стартирам наблюдение на $RepoPath (branch: $Branch). Ctrl+C за стоп."

while ($true) {
    # Има ли промени?
    $status = git status --porcelain

    if (-not [string]::IsNullOrWhiteSpace($status)) {
        # Добави всичко (вкл. трити файлове)
        git add -A | Out-Null

        # Проверка за разлики след add (може да няма реални)
        $diff = git diff --cached --name-status
        if (-not [string]::IsNullOrWhiteSpace($diff)) {
            $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $msg = "auto: $stamp"
            git commit -m $msg | Write-Host
            git push origin $Branch | Write-Host
            Write-Host "✅ Публикувано ➜ $msg"
        }
    }

    Start-Sleep -Seconds $IntervalSec
}
