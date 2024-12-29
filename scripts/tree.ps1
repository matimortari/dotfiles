# Display the working directory file structure, excluding specified directories that are too large.

# Initialize variables
$source = Get-Location
$treeOutput = "$source\out"

# Ensure the temporary directory is empty, then create it
if (Test-Path -Path $treeOutput) { Remove-Item -Recurse -Force -Path $treeOutput }
New-Item -ItemType Directory -Path $treeOutput

# Copy the directory, excluding the specified directories (and tree-output)
robocopy $source $treeOutput /E /XD node_modules dist .git .venv tree-output

# Run the tree command to display the directory structure
Set-Location $treeOutput
tree /f

# Change back to the original directory before attempting cleanup
Set-Location $source

# Clean up the temporary directory
Remove-Item -Recurse -Force -Path $treeOutput
