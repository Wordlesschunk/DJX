#!/bin/bash

# alise: qcp

branch=$(git branch --show-current)

if [ -z "$branch" ]; then
    echo "Error: Not in a git repository or no branch checked out"
    exit 1
fi

if [ -n "$1" ]; then
    message="$1"
else
    read -p "Enter commit message: " message
fi

git add .
git commit -m "$branch $message" --no-verify
git push --no-verify

echo
echo "────────────────────────────────────────────"
echo -e "  \033[1;36mGitHub Pull Requests\033[0m"
echo -e "  \033[4;34mhttps://github.com/pulls/inbox\033[0m"
echo "────────────────────────────────────────────"
echo
