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

echo "https://github.com/pulls/inbox"
