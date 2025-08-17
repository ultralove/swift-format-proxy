#!/bin/bash

# Script to generate CHANGELOG.md from git history
# Usage: ./generate-changelog.sh [version] [output_file]

set -e

VERSION=${1:-"Unreleased"}
OUTPUT_FILE=${2:-"CHANGELOG.md"}
REPO_URL="https://github.com/${GITHUB_REPOSITORY:-ultralove/swift-format-proxy}"

echo "Generating CHANGELOG.md for version: $VERSION"

# Function to get commit messages between two refs
get_commits() {
    local from_ref=$1
    local to_ref=$2

    if [ -z "$from_ref" ]; then
        # Get all commits if no previous tag
        git log --pretty=format:"%h %s" "$to_ref"
    else
        # Get commits between tags
        git log --pretty=format:"%h %s" "$from_ref..$to_ref"
    fi
}

# Function to categorize commits
categorize_commits() {
    while read -r line; do
        local hash=$(echo "$line" | cut -d' ' -f1)
        local message=$(echo "$line" | cut -d' ' -f2-)

        # Skip merge commits
        if [[ $message == Merge* ]]; then
            continue
        fi

        # Categorize based on conventional commit format or keywords
        if [[ $message =~ ^feat(\(.+\))?:.*|^add.*|^implement.*|^new.*|Add.* ]]; then
            echo "### ✨ Features" >> "$OUTPUT_FILE.tmp"
            echo "- $message ([${hash}](${REPO_URL}/commit/${hash}))" >> "$OUTPUT_FILE.tmp"
        elif [[ $message =~ ^fix(\(.+\))?:.*|^bug.*|^resolve.*|Fix.* ]]; then
            echo "### 🐛 Bug Fixes" >> "$OUTPUT_FILE.tmp"
            echo "- $message ([${hash}](${REPO_URL}/commit/${hash}))" >> "$OUTPUT_FILE.tmp"
        elif [[ $message =~ ^docs(\(.+\))?:.*|^doc.*|Update.*README|.*documentation.* ]]; then
            echo "### 📚 Documentation" >> "$OUTPUT_FILE.tmp"
            echo "- $message ([${hash}](${REPO_URL}/commit/${hash}))" >> "$OUTPUT_FILE.tmp"
        elif [[ $message =~ ^style(\(.+\))?:.*|^format.*|.*formatting.* ]]; then
            echo "### 💅 Style" >> "$OUTPUT_FILE.tmp"
            echo "- $message ([${hash}](${REPO_URL}/commit/${hash}))" >> "$OUTPUT_FILE.tmp"
        elif [[ $message =~ ^refactor(\(.+\))?:.*|^refac.*|.*refactor.* ]]; then
            echo "### ♻️ Refactoring" >> "$OUTPUT_FILE.tmp"
            echo "- $message ([${hash}](${REPO_URL}/commit/${hash}))" >> "$OUTPUT_FILE.tmp"
        elif [[ $message =~ ^test(\(.+\))?:.*|^tests.*|.*test.* ]]; then
            echo "### 🧪 Tests" >> "$OUTPUT_FILE.tmp"
            echo "- $message ([${hash}](${REPO_URL}/commit/${hash}))" >> "$OUTPUT_FILE.tmp"
        elif [[ $message =~ ^chore(\(.+\))?:.*|^ci.*|^build.*|.*workflow.*|.*dependencies.* ]]; then
            echo "### 🔧 Maintenance" >> "$OUTPUT_FILE.tmp"
            echo "- $message ([${hash}](${REPO_URL}/commit/${hash}))" >> "$OUTPUT_FILE.tmp"
        elif [[ $message =~ ^perf(\(.+\))?:.*|.*performance.*|.*optimize.* ]]; then
            echo "### ⚡ Performance" >> "$OUTPUT_FILE.tmp"
            echo "- $message ([${hash}](${REPO_URL}/commit/${hash}))" >> "$OUTPUT_FILE.tmp"
        else
            echo "### 📝 Other Changes" >> "$OUTPUT_FILE.tmp"
            echo "- $message ([${hash}](${REPO_URL}/commit/${hash}))" >> "$OUTPUT_FILE.tmp"
        fi
    done
}

# Create the changelog header
cat > "$OUTPUT_FILE" << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

EOF

# Get all tags sorted by version
TAGS=$(git tag -l "v*" --sort=-version:refname)

# If we have a specific version, generate only for that version
if [ "$VERSION" != "Unreleased" ]; then
    echo "## [$VERSION] - $(date +%Y-%m-%d)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Find the previous tag
    CURRENT_TAG="$VERSION"
    PREVIOUS_TAG=$(echo "$TAGS" | grep -A1 "^$VERSION$" | tail -n1)

    if [ "$PREVIOUS_TAG" = "$VERSION" ]; then
        PREVIOUS_TAG=""
    fi

    # Get commits for this version
    if [ -n "$PREVIOUS_TAG" ]; then
        get_commits "$PREVIOUS_TAG" "$CURRENT_TAG" | categorize_commits
    else
        get_commits "" "$CURRENT_TAG" | categorize_commits
    fi

    # Process the temporary file to group by categories and remove duplicates
    if [ -f "$OUTPUT_FILE.tmp" ]; then
        # Sort and group the entries
        {
            grep "^### ✨ Features" "$OUTPUT_FILE.tmp" | head -1
            grep "^- " "$OUTPUT_FILE.tmp" | grep -A1000 "^### ✨ Features" | grep -B1000 "^### " | grep "^- " | head -n -1
            echo ""

            grep "^### 🐛 Bug Fixes" "$OUTPUT_FILE.tmp" | head -1
            grep "^- " "$OUTPUT_FILE.tmp" | grep -A1000 "^### 🐛 Bug Fixes" | grep -B1000 "^### " | grep "^- " | head -n -1
            echo ""

            grep "^### 📚 Documentation" "$OUTPUT_FILE.tmp" | head -1
            grep "^- " "$OUTPUT_FILE.tmp" | grep -A1000 "^### 📚 Documentation" | grep -B1000 "^### " | grep "^- " | head -n -1
            echo ""

            grep "^### ♻️ Refactoring" "$OUTPUT_FILE.tmp" | head -1
            grep "^- " "$OUTPUT_FILE.tmp" | grep -A1000 "^### ♻️ Refactoring" | grep -B1000 "^### " | grep "^- " | head -n -1
            echo ""

            grep "^### 🔧 Maintenance" "$OUTPUT_FILE.tmp" | head -1
            grep "^- " "$OUTPUT_FILE.tmp" | grep -A1000 "^### 🔧 Maintenance" | grep -B1000 "^### " | grep "^- " | head -n -1
            echo ""

            grep "^### 📝 Other Changes" "$OUTPUT_FILE.tmp" | head -1
            grep "^- " "$OUTPUT_FILE.tmp" | grep -A1000 "^### 📝 Other Changes" | grep -B1000 "^### " | grep "^- " | head -n -1
        } | grep -v "^$" | sed '/^### /{ N; /\n$/d; }' >> "$OUTPUT_FILE"

        rm -f "$OUTPUT_FILE.tmp"
    fi
else
    # Generate changelog for all versions
    if [ -z "$TAGS" ]; then
        echo "## [Unreleased]" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        get_commits "" "HEAD" | categorize_commits

        if [ -f "$OUTPUT_FILE.tmp" ]; then
            cat "$OUTPUT_FILE.tmp" >> "$OUTPUT_FILE"
            rm -f "$OUTPUT_FILE.tmp"
        fi
    else
        # Add unreleased section if there are commits since last tag
        LATEST_TAG=$(echo "$TAGS" | head -n1)
        UNRELEASED_COMMITS=$(get_commits "$LATEST_TAG" "HEAD")

        if [ -n "$UNRELEASED_COMMITS" ]; then
            echo "## [Unreleased]" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            echo "$UNRELEASED_COMMITS" | categorize_commits

            if [ -f "$OUTPUT_FILE.tmp" ]; then
                cat "$OUTPUT_FILE.tmp" >> "$OUTPUT_FILE"
                rm -f "$OUTPUT_FILE.tmp"
                echo "" >> "$OUTPUT_FILE"
            fi
        fi

        # Generate for each tag
        PREVIOUS_TAG=""
        for TAG in $TAGS; do
            echo "## [$TAG] - $(git log -1 --format=%ai $TAG | cut -d' ' -f1)" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"

            get_commits "$PREVIOUS_TAG" "$TAG" | categorize_commits

            if [ -f "$OUTPUT_FILE.tmp" ]; then
                cat "$OUTPUT_FILE.tmp" >> "$OUTPUT_FILE"
                rm -f "$OUTPUT_FILE.tmp"
                echo "" >> "$OUTPUT_FILE"
            fi

            PREVIOUS_TAG="$TAG"
        done
    fi
fi

echo "CHANGELOG.md generated successfully: $OUTPUT_FILE"
