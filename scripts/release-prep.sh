#!/bin/bash

# Uncomment the next line to set bash debug mode
# set -x

# Note: this was adapted from FormSG's release prep script 
# See https://github.com/opengovsg/FormSG/blob/develop/scripts/release_prep.sh

# Pre-requisites:
# - Install the GitHub CLI: https://github.com/cli/cli#installation

# Assumptions:
# - This script is placed in a `scripts` folder at the root of your project
# - This script is run from the root of the project

# 1. Check that there are no local modifications before release
has_local_changes=$(git status --porcelain --untracked-files=no --ignored=no)
if [[ ${has_local_changes} ]]; then
  echo ==========
  echo "ABORT: You have local modifications. Please stash or commit changes and run again."
  echo ==========
  exit 1
fi

# 2. Checkout develop and pull latest changes
git fetch --all --tags
git reset --hard
git pull
git checkout develop
git reset --hard origin/develop

# 3. Select the release type
echo -e "\n\nSelect the release type: major, minor, patch"
read releaseType

if [[ "$releaseType" != "major" && "$releaseType" != "minor" && "$releaseType" != "patch" ]]; then
  echo ==========
  echo "ABORT: Invalid release type. Please select major, minor or patch."
  echo ==========
  exit 1
fi

# 4. Bump version
# - Note that the `npm --no-git-tag-version version` command will bump the version in your package.json
# and package-lock.json files
release_version=$(npm --no-git-tag-version version $releaseType | grep -E '^v\d')
release_version_number=$(echo "$release_version" | sed 's/^v//')
release_branch=release/${release_version}
echo -e "\n\nRelease branch name: $release_branch"

# 4a. Check whether tags and release branch already exist
if git rev-parse $release_version >/dev/null 2>&1; then
  echo "Tag $release_version already exists! Aborting release..."
  exit 1
fi

if git rev-parse $release_branch >/dev/null 2>&1; then
  echo "Branch $release_branch already exists! Aborting release..."
  exit 1
fi

# 4b. Create release branch and push to remote
git checkout -b ${release_branch}
git push --set-upstream origin ${release_branch}

# 4b. Commit and push version bump to develop
git add package.json package-lock.json
git commit -m "$release_version_number"
git push -f

# 4c. Push tags
git tag ${release_version}
git push origin ${release_version}

# 5. Authenticate with GitHub CLI
gh auth login

# 5a. Create release PR to master
# - gh pr create docs: https://cli.github.com/manual/gh_pr_create
# - Note: please update the PR description yourself after the script has been run
gh pr create \
  -w \
  -H ${release_branch} \
  -B master \
  -t "Release $release_version"

# 5b. Create release PR to develop
gh pr create \
  -w \
  -H ${release_branch} \
  -B develop \
  -t "(develop) Release $release_version"

# 6. Cleanup 
git checkout develop
