# PSReadLine Configuration
Set-PSReadlineOption -PredictionSource History
Set-PSReadlineOption -Colors @{
    Command   = "Yellow"
    Parameter = "DarkCyan"
    String    = "DarkGray"
    Keyword   = "Magenta"
    Variable  = "DarkYellow"
}

# Aliases
Set-Alias touch New-Item

# Utility Functions

# Display public IP address
function myip {
    try {
        Invoke-RestMethod 'https://api.ipify.org'
    }
    catch {
        Invoke-RestMethod 'https://ifconfig.me'
    }
}

# Display comprehensive system information
function sysinfo {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    $memory = Get-CimInstance -ClassName Win32_PhysicalMemory
    $totalMemoryGB = [math]::Round(($memory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
    $freeMemoryMB = [math]::Round($os.FreePhysicalMemory / 1KB, 2)
    $freeMemoryPercentage = [math]::Round(($freeMemoryMB / ($totalMemoryGB * 1024)) * 100, 2)

    Write-Host "OS: $($os.Caption)"
    Write-Host "Architecture: $($os.OSArchitecture)"
    Write-Host "Total Physical Memory: $totalMemoryGB GB"
    Write-Host "Free Memory: $freeMemoryMB MB ($freeMemoryPercentage%)"
    Write-Host "Uptime: $($uptime.Days) days, $($uptime.Hours) hours"
}

# Display tree structure for the current working directory, excluding folders which may clutter the view
function show-tree {
    param(
        [string]$Path = (Get-Location),
        [string[]]$Exclude = @('node_modules', 'dist', '.git', '.nuxt', '.next', '.output', '.venv', 'out', 'build', 'bin', 'obj')
    )

    function Print-Tree {
        param(
            [string]$BasePath,
            [string]$Indent = ""
        )

        $items = Get-ChildItem -Force -LiteralPath $BasePath -ErrorAction SilentlyContinue |
            Where-Object { $Exclude -notcontains $_.Name -and -not $_.Attributes.HasFlag([System.IO.FileAttributes]::Hidden) } |
            Sort-Object { -not $_.PSIsContainer }, Name

        for ($i = 0; $i -lt $items.Count; $i++) {
            $item = $items[$i]
            $isLast = ($i -eq $items.Count - 1)
            $connector = if ($isLast) { "└── " } else { "├── " }
            $newIndent = if ($isLast) { "$Indent    " } else { "$Indent│   " }

            if ($item.PSIsContainer) {
                Write-Host "$Indent$connector$($item.Name)" -ForegroundColor Yellow
                Print-Tree -BasePath $item.FullName -Indent $newIndent
            }
            else {
                Write-Host "$Indent$connector$($item.Name)" -ForegroundColor Yellow
            }
        }
    }

    Print-Tree $Path
}

# Check system status for various tools and internet connectivity
function fitter-happier {
    function Write-Status {
        param(
            [string]$Name,
            [bool]$IsAvailable,
            [string]$Details = ""
        )
        
        $status = if ($IsAvailable) { "✓" } else { "✗" }
        $color = if ($IsAvailable) { "Green" } else { "Red" }
        
        $output = "{0,-12} {1}" -f "${Name}:", $status
        if ($Details) {
            $output += " ($Details)"
        }
        
        Write-Host $output -ForegroundColor $color
    }

    Write-Host "`nSystem Check:" -ForegroundColor Cyan
    Write-Host ("=" * 20) -ForegroundColor DarkGray

    # Docker check
    try {
        $dockerVersion = (docker --version 2>$null) -replace 'Docker version ' -replace ', build.*'
        $dockerRunning = $LASTEXITCODE -eq 0
    } catch {
        $dockerRunning = $false
        $dockerVersion = $null
    }
    Write-Status -Name "Docker" -IsAvailable $dockerRunning -Details $dockerVersion

    # Git check
    $git = Get-Command git -ErrorAction SilentlyContinue
    $gitInstalled = $null -ne $git
    $gitVersion = if ($gitInstalled) { (git --version) -replace 'git version ' }
    Write-Status -Name "Git" -IsAvailable $gitInstalled -Details $gitVersion

    # Node.js check
    $node = Get-Command node -ErrorAction SilentlyContinue
    $nodeInstalled = $null -ne $node
    $nodeVersion = if ($nodeInstalled) { node --version }
    Write-Status -Name "Node.js" -IsAvailable $nodeInstalled -Details $nodeVersion

    # Bun check
    $bun = Get-Command bun -ErrorAction SilentlyContinue
    $bunInstalled = $null -ne $bun
    $bunVersion = if ($bunInstalled) { (bun --version) }
    Write-Status -Name "Bun" -IsAvailable $bunInstalled -Details $bunVersion

    # Go check
    $go = Get-Command go -ErrorAction SilentlyContinue
    $goInstalled = $null -ne $go
    $goVersion = if ($goInstalled) { (go version) -replace 'go version go' -replace ' .*' }
    Write-Status -Name "Go" -IsAvailable $goInstalled -Details $goVersion

    # Internet connectivity and latency check
    try {
        $pingResult = Test-Connection -ComputerName "8.8.8.8" -Count 1 -TimeoutSeconds 2
        $internet = $null -ne $pingResult
        $latency = if ($internet) { "Latency: $($pingResult.Latency)ms" }
    } catch {
        $internet = $false
        $latency = $null
    }
    Write-Status -Name "Internet" -IsAvailable $internet -Details $latency

    Write-Host ("=" * 20) -ForegroundColor DarkGray
    Write-Host ""
}

# Sync all git repositories in current directory to origin/main
function sync-git-repos {
    $startDir = Get-Location
    $repos = Get-ChildItem -Directory
    $total = $repos.Count
    $count = 0
    $results = @{
        Success = 0
        Failed  = 0
        Skipped = 0
    }

    Write-Host "`n--- Syncing Git Repositories ---`n" -ForegroundColor Cyan

    foreach ($repo in $repos) {
        $count++
        Set-Location $repo.FullName
        Write-Host "[$count/$total] $($repo.Name): " -ForegroundColor White -NoNewline
        $isGitRepo = (git rev-parse --is-inside-work-tree 2>$null) -eq "true"
        if (-not $isGitRepo) {
            Write-Host "Skipped (not a git repo)" -ForegroundColor DarkGray
            $results.Skipped++
            Set-Location $startDir
            continue
        }

        $hasOrigin = (git remote 2>$null) -contains "origin"
        if (-not $hasOrigin) {
            Write-Host "Skipped (no origin remote)" -ForegroundColor DarkGray
            $results.Skipped++
            Set-Location $startDir
            continue
        }

        try {
            git fetch origin 2>&1 | Out-Null
            git reset --hard origin/main 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Synced successfully" -ForegroundColor Green
                $results.Success++
            }
            else {
                Write-Host "Failed (branch 'main' not found)" -ForegroundColor Red
                $results.Failed++
            }
        }
        catch {
            Write-Host "Failed (exception: $($_.Exception.Message))" -ForegroundColor Red
            $results.Failed++
        }

        Set-Location $startDir
    }

    Write-Host "`n--- Summary: $($results.Success) synced, $($results.Failed) failed, $($results.Skipped) skipped ---`n" -ForegroundColor Cyan
}
