#!/bin/bash

set -eu

# Change this configuration to suit your needs
# Paths are relative to this script

# Where the control repository is stored (= the list of websites)
CONTROL_REPOSITORY=control

# Control repository remote URL
CONTROL_REMOTE_URL=/tmp/control2

# Where the website repositories are kept
REPOSITORIES=repositories

# Where the websites are put (should be the directory served by your web server)
WEB_ROOT=www

# End configuration


# Go to location of this script
cd "$(dirname "$0")"

# Update control repository
if [ ! -d "$CONTROL_REPOSITORY/.git" ]; then
    # Directory does not exist, first setup?
    echo "Warning: Control repository does not exist, cloning..." >&2
    rm -rf -- "$CONTROL_REPOSITORY"
    git clone --quiet --single-branch "$CONTROL_REMOTE_URL" -- "$CONTROL_REPOSITORY"
elif [ "$CONTROL_REMOTE_URL" = "$(cd "$CONTROL_REPOSITORY" && git config --get remote.origin.url)" ]; then
    # Just pull
    (cd "$CONTROL_REPOSITORY" && git fetch -p --quiet origin HEAD:refs/heads/origin-head && git checkout --quiet origin-head~0)
else
    # Directory exists but has different remote, recreate it
    echo "Warning: Control repository URL has changed! Recreating..." >&2
    rm -rf -- "$CONTROL_REPOSITORY"
    git clone --quiet --single-branch "$CONTROL_REMOTE_URL" -- "$CONTROL_REPOSITORY"
fi

# Go over list
UPDATED=
exec 3<"$CONTROL_REPOSITORY/list.txt"
while read line <&3; do
    # Parse line
    regex='^\([^ ]\+\) \+\([^ ]\+\)$'
    name=$(printf "%s" "$line" | sed 's/'"$regex"'/\1/')
    url=$(printf "%s" "$line" | sed 's/'"$regex"'/\2/')

    # Update repository
    if [ ! -d "$REPOSITORIES/$name" ]; then
        echo "Warning: Creating new repository $name from $url" >&2
        git clone --quiet --single-branch --separate-git-dir "$REPOSITORIES/$name" -- "$url" "$WEB_ROOT/$name"
        rm "$WEB_ROOT/$name/.git"
    elif [ "$url" = "$(cd "$REPOSITORIES/$name" && git config --get remote.origin.url)" ]; then
        # Just pull
        git --git-dir "$REPOSITORIES/$name" --work-tree "$WEB_ROOT/$name" fetch -p --quiet origin HEAD:refs/heads/origin-head
        git --git-dir "$REPOSITORIES/$name" --work-tree "$WEB_ROOT/$name" checkout --quiet origin-head~0
    else
        echo "Warning: Repository $name had its URL changed, recreating from $url" >&2
        rm -rf -- "$REPOSITORIES/$name" "$WEB_ROOT/$name"
        git clone --quiet --single-branch --separate-git-dir "$REPOSITORIES/$name" -- "$url" "$WEB_ROOT/$name"
        rm "$WEB_ROOT/$name/.git"
    fi
    UPDATED="$name
$UPDATED"
done

# Remove repositories no longer in the list
for name in $(comm -13 <(printf "%s" "$UPDATED" | sort) <(ls -1 -- "$WEB_ROOT" | sort)); do
    echo "Warning: Repository $name removed, deleting" >&2
    rm -rf -- "$REPOSITORIES/$name" "$WEB_ROOT/$name"
done
