# Configure PSReadline options and colors
Set-PSReadlineOption -PredictionSource History
Set-PSReadlineOption -Colors @{
    "Command" = "Yellow"
    "Parameter" = "DarkCyan"
    "String" = "DarkGray"
    "Keyword" = "Magenta"
    "Variable" = "DarkYellow"
}

# Alias for 'touch' to create new files
Set-Alias touch New-Item


# Output current date in YYYYMMDD format
function today {
    return (Get-Date -Format "yyyyMMdd")
}

# Display the public IP address of the current machine
function myip {
    (Invoke-WebRequest http://ifconfig.me/ip).Content
}

# Display the disk information of the current machine
function df {
    Get-Volume
}

# Display system information
function sysinfo {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    $memory = Get-CimInstance -ClassName Win32_PhysicalMemory

    $totalMemoryGB = [math]::round(($memory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
    $freeMemoryMB = [math]::round($os.FreePhysicalMemory / 1KB, 2)
    $freeMemoryPercentage = [math]::round(($freeMemoryMB / ($totalMemoryGB * 1024)) * 100, 2)

    Write-Host "OS: $($os.Caption)"
    Write-Host "Architecture: $($os.OSArchitecture)"
    Write-Host "Uptime: $($uptime.Days) days"
    Write-Host "Total Physical Memory: $totalMemoryGB GB"
    Write-Host "Free Memory: $freeMemoryMB MB ($freeMemoryPercentage%)"
}

# Display tree structure for the current working directory, excluding certain folders which may clutter the view
function show-tree {
    $source = Get-Location 
    $output = "$source\out"

    if (Test-Path $output) { 
        Remove-Item -Recurse -Force -Path $output | Out-Null 
    }
    New-Item -ItemType Directory -Path $output | Out-Null

    robocopy $source $output /E /XD node_modules dist .git .nuxt .next .output .venv out /NFL /NDL /NJH /NJS /NC /NS /NP > $null

    Set-Location $output
    tree /F

    Set-Location $source
    Remove-Item -Recurse -Force -Path $output | Out-Null
}

# Sync all git repositories in the current directory to their origin/main branch
function sync-git-repos {
    $startDir = Get-Location
    $repos = Get-ChildItem -Directory
    $total = $repos.Count
    $count = 0

    Write-Host "`n--- Syncing Git Repositories ---`n" -ForegroundColor Cyan

    foreach ($repo in $repos) {
        $count++
        Set-Location $repo.FullName
        $status = ""

        Write-Host "[$count/$total] $($repo.Name): Syncing..." -ForegroundColor White

        $isGitRepo = (& git rev-parse --is-inside-work-tree 2>$null) -eq "true"

        if ($isGitRepo) {
            $hasOrigin = (& git remote 2>$null) -contains "origin"

            if ($hasOrigin) {
                try {
                    git fetch origin 2>$null
                    git reset --hard origin/main 2>$null

                    if ($LASTEXITCODE -eq 0) {
                        $status = "Done."
                        Write-Host "[$count/$total] $($repo.Name): $status`n" -ForegroundColor Green
                    } else {
                        $status = "Failed to sync (fetch/reset error)."
                        Write-Host "[$count/$total] $($repo.Name): $status`n" -ForegroundColor Red
                    }
                }
                catch {
                    $status = "Failed to sync (exception)."
                    Write-Host "[$count/$total] $($repo.Name): $status`n" -ForegroundColor Red
                }
            } else {
                $status = "Done (git repo not found)."
                Write-Host "[$count/$total] $($repo.Name): $status`n" -ForegroundColor Yellow
            }
        } else {
            $status = "Done (git repo not found)."
            Write-Host "[$count/$total] $($repo.Name): $status`n" -ForegroundColor Yellow
        }

        Set-Location $startDir
    }

    Write-Host "--- All Done ---`n" -ForegroundColor Cyan
}
