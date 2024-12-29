# Quickstart a Next.js-powered web application, along with a GitHub repository.

<#
    For this script to work, you need to have a GitHub token set as an environment variable. To set it up on Windows:
        1. Open the Environment Variables settings on your system.
        2. Under "User variables", click "New".
        3. Set "Variable name" to GITHUBTOKEN and "Variable value" to your GitHub personal access token.
        4. Click OK to save and restart your terminal.
#>

# Initialize variables from user input
$projectName = Read-Host -Prompt "Enter the name for the project"
$repoName = Read-Host -Prompt "Enter the name for the GitHub repository"

# Create new Next.js project & install dependencies
git clone https://github.com/matimortari/nextjs-boilerplate $projectName
Set-Location $projectName

# Clean up boilerplate repository metadata and add necessary files
Remove-Item .git, README.md -Recurse -Force
New-Item README.md, .env.local, .env.production # Create placeholder files for README and environment variables
npm install --verbose

# Initialize Git repository for the project
git init

# Prepare JSON data for GitHub API request to create a new repository
$jsonData = @{
    name    = $repoName
    private = $true
} | ConvertTo-Json

# Prepare headers for the API request, including the GitHub token for authentication
$headers = @{
    Authorization = "token $($env:GITHUBTOKEN)"
    Accept        = "application/vnd.github.v3+json" # Specify the GitHub API version
}

# Send the API request to create a new repository on GitHub
$response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $jsonData

# Extract the clone URL for the newly created repository and add it as a remote
$cloneUrl = $response.clone_url
git remote add origin $cloneUrl
git remote -v
