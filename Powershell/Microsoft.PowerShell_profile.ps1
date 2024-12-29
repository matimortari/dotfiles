# Configure PSReadline options and colors
Set-PSReadlineOption -PredictionSource History
Set-PSReadlineOption -Colors @{
    "Command" = "Yellow"
    "Parameter" = "DarkCyan"
    "String" = "DarkGray"
    "Keyword" = "Magenta"
    "Variable" = "DarkYellow"
}

# Alias for 'touch' to create new items (files)
Set-Alias touch New-Item

# Remove the existing alias for 'rm' if it exists
Remove-Item Alias:rm -ErrorAction SilentlyContinue

# Custom 'rm' function with confirmation prompt and Force flag
function rm {
    param([string]$path)
    
    if (Test-Path $path) {
        $confirmation = Read-Host "Are you sure you want to delete '$path'? (y/n)"
        If ($confirmation -eq 'y') {
            Remove-Item $path -Force
            Write-Host "'$path' has been deleted."
        } else {
            Write-Host "Deletion of '$path' aborted."
        }
    } else {
        Write-Host "'$path' does not exist."
    }
}

# List all files and directories in the current directory
function dirs {
    if ($args.Count -gt 0) {
        Get-ChildItem -Recurse -Include "$args" | Foreach-Object FullName
    } else {
        Get-ChildItem -Recurse | Foreach-Object FullName
    }
}

# Shortcut for Git operations: add, commit, and push
function lazygit {
    git add .
    git commit -a -m "$args" 
    git push
}

# Get the public IP address of the current machine
function myip {
    (Invoke-WebRequest http://ifconfig.me/ip).Content
}

# Display disk information
function df {
    Get-Volume
}

# Find processes by name
function pgrep ($name) {
    Get-Process $name
}

# Kill a process by name
function pkill {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}
