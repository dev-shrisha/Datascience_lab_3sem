
$folder = "C:\Users\HP\OneDrive\Documents\DS_LAB1"
$branch = "main"
$delayMinutes = 30

# Check that the folder is a Git repository
git -C $folder rev-parse --is-inside-work-tree
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: This folder is not a Git repository!" -ForegroundColor Red
    exit
}

# Allow the first detected change to push immediately
$lastPushTime = (Get-Date).AddMinutes(-30)

Write-Host "Git Auto-Sync is running!" -ForegroundColor Green
Write-Host "Watching: $folder"
Write-Host "Checking for changes every 10 seconds..."

while ($true) {
    try {
        # Check for tracked and untracked changes
        $changes = git -C $folder status --porcelain

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Could not check Git status." -ForegroundColor Red
        }
        elseif ($changes) {
            $elapsed = ((Get-Date) - $lastPushTime).TotalMinutes

            if ($elapsed -ge $delayMinutes) {
                Write-Host "Changes detected. Pushing to GitHub..." -ForegroundColor Cyan

                git -C $folder add -A

                if ($LASTEXITCODE -eq 0) {
                    git -C $folder commit -m "Auto-sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

                    if ($LASTEXITCODE -eq 0) {
                        git -C $folder push origin $branch

                        if ($LASTEXITCODE -eq 0) {
                            $lastPushTime = Get-Date
                            Write-Host "Push successful!" -ForegroundColor Green
                        }
                        else {
                            Write-Host "Push failed. Check Git output." -ForegroundColor Red
                        }
                    }
                    else {
                        Write-Host "Commit failed. Check Git output." -ForegroundColor Red
                    }
                }
            }
            else {
                $remaining = [math]::Ceiling($delayMinutes - $elapsed)
                Write-Host "Changes waiting. Push in about $remaining minute(s)." -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }

    Start-Sleep -Seconds 10
}
