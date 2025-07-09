#!/bin/bash
# Script to remove all Swift-related files and keep Flutter files
# Prompts for confirmation before deleting

set -e

SWIFT_DIRS=("bitchat" "bitchatTests")

echo "This script will permanently delete the following Swift-related directories:"
for dir in "${SWIFT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "  - $dir"
    fi
done

echo "Flutter-related files and directories will be kept."
echo -n "Are you sure you want to proceed? (y/N): "
read -r confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    for dir in "${SWIFT_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            echo "Deleted $dir"
        else
            echo "$dir does not exist, skipping."
        fi
    done
    echo "Swift-related files removed. Flutter files are intact."
else
    echo "Aborted. No files were deleted."
fi
