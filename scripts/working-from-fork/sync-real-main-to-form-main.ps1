# Stop if there are uncommitted changes
$status = git status --porcelain
if ($status) {
  Write-Error 'Uncommitted changes detected. Please commit or stash your changes before syncing.'
  Write-Host ''
  Write-Host 'To stash:  git stash'
  Write-Host "To commit: git add -A && git commit -m 'WIP'"
  exit 1
}

# Remember current branch
$currentBranch = git rev-parse --abbrev-ref HEAD

# Find or register the upstream remote pointing to the real repo
$upstreamUrl = 'https://github.com/joshsmithxrm/power-platform-developer-suite.git'
$existingRemote = git remote -v | Select-String $upstreamUrl | Select-Object -First 1

if ($existingRemote) {
  $upstreamName = ($existingRemote -split '\s+')[0]
  Write-Host "Found remote '$upstreamName' pointing to the real repo."
} else {
  Write-Host "No remote found for the real repo. Adding as 'upstream'..."
  git remote add upstream $upstreamUrl
  $upstreamName = 'upstream'
}

# Fetch latest from the real repo
Write-Host "Fetching from '$upstreamName'..."
git fetch $upstreamName

# Switch to main if not already there
if ($currentBranch -ne 'main') {
  Write-Host 'Switching to main...'
  git checkout main
}

# Merge upstream/main into fork's main
Write-Host "Merging $upstreamName/main into main..."
git merge "$upstreamName/main" --no-edit

if ($LASTEXITCODE -ne 0) {
  Write-Error 'Merge failed — there are conflicts that must be resolved manually.'
  Write-Host ''
  Write-Host 'To resolve:'
  Write-Host "  1. Run 'git status' to see conflicting files"
  Write-Host '  2. Edit each conflicting file and resolve the conflict markers (<<<<<<<, =======, >>>>>>>)'
  Write-Host "  3. Run 'git add <file>' for each resolved file"
  Write-Host "  4. Run 'git merge --continue' to complete the merge"
  Write-Host "  5. Run 'git push origin main' to push the result"
  Write-Host ''
  Write-Host 'To abort and return to your previous state: git merge --abort'
  exit 1
}

# Push updated main to fork on GitHub
# Write-Host "Pushing to origin main..."
# git push origin main

# If the user was on a different branch, offer to sync it too
if ($currentBranch -ne 'main') {
  Write-Host ''
  $response = Read-Host "You were on branch '$currentBranch'. Merge updated main into it? (y/N)"
  if ($response -match '^[Yy]$') {
    Write-Host "Switching back to '$currentBranch'..."
    git checkout $currentBranch

    Write-Host "Merging main into '$currentBranch'..."
    git merge main --no-edit

    if ($LASTEXITCODE -ne 0) {
      Write-Error "Merge into '$currentBranch' failed — resolve conflicts manually, then run 'git merge --continue'."
      exit 1
    }

    Write-Host "Branch '$currentBranch' is now up to date with main."
  } else {
    Write-Host "Switching back to '$currentBranch'..."
    git checkout $currentBranch
    Write-Host "Done. '$currentBranch' was not updated."
  }
}
