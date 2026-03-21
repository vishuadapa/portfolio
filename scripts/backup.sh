#!/bin/bash
# backup.sh — Weekly backup script for vishuadapa/portfolio
# Clones/pulls from GitHub, creates a timestamped archive, retains last 7 copies.
#
# Setup (run once on Mac mini):
#   chmod +x ~/scripts/portfolio-backup/backup.sh
#   crontab -e
#   Add: 0 2 * * 0 ~/scripts/portfolio-backup/backup.sh >> ~/scripts/portfolio-backup/backup.log 2>&1

set -euo pipefail

REPO_URL="https://github.com/vishuadapa/portfolio.git"
WORK_DIR="$HOME/scripts/portfolio-backup"
CLONE_DIR="$WORK_DIR/repo"
ARCHIVE_DIR="$WORK_DIR/archives"
MAX_COPIES=7
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE_NAME="vishuadapa-portfolio-$TIMESTAMP.tar.gz"

mkdir -p "$ARCHIVE_DIR"

echo "=== Portfolio Backup — $TIMESTAMP ==="

# Clone on first run, pull on subsequent runs
if [ -d "$CLONE_DIR/.git" ]; then
    echo "Pulling latest from GitHub..."
    git -C "$CLONE_DIR" pull --quiet origin main
else
    echo "Cloning repository..."
    git clone --quiet "$REPO_URL" "$CLONE_DIR"
fi

# Get the latest commit hash for reference
COMMIT=$(git -C "$CLONE_DIR" rev-parse --short HEAD)
echo "Commit: $COMMIT"

# Create timestamped archive (excluding .git directory)
echo "Creating archive: $ARCHIVE_NAME"
tar -czf "$ARCHIVE_DIR/$ARCHIVE_NAME" -C "$CLONE_DIR" \
    --exclude='.git' \
    .

ARCHIVE_SIZE=$(du -sh "$ARCHIVE_DIR/$ARCHIVE_NAME" | cut -f1)
echo "Archive size: $ARCHIVE_SIZE"

# Retain only the last MAX_COPIES archives
ARCHIVE_COUNT=$(ls -1 "$ARCHIVE_DIR"/vishuadapa-portfolio-*.tar.gz 2>/dev/null | wc -l)
if [ "$ARCHIVE_COUNT" -gt "$MAX_COPIES" ]; then
    DELETE_COUNT=$((ARCHIVE_COUNT - MAX_COPIES))
    echo "Pruning $DELETE_COUNT old archive(s) (keeping last $MAX_COPIES)..."
    ls -1t "$ARCHIVE_DIR"/vishuadapa-portfolio-*.tar.gz | tail -n "$DELETE_COUNT" | xargs rm -f
fi

echo "Archives retained:"
ls -1t "$ARCHIVE_DIR"/vishuadapa-portfolio-*.tar.gz | while read -r f; do
    echo "  $(basename "$f")  ($(du -sh "$f" | cut -f1))"
done

echo "=== Backup complete ==="
echo ""
