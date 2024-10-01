#!/usr/bin/env bash

ARCHIVE_BRANCH='archive'
SOFTWARE_HERITAGE='true'

# Initialize Git configuration and create an orphan branch
init_git() {
    git config --global user.name 'github-actions[bot]'
    git config --global user.email 'github-actions[bot]@users.noreply.github.com'
    git checkout --orphan "$ARCHIVE_BRANCH"
    find . -not -name '*.bundle' -not -path './.git*' -exec git rm -rf "{}" \;
    git pull origin "$ARCHIVE_BRANCH"
}

# Check if a specific branch exists in the remote repository
repo_exist_not_empty() {
    local url="$1"
    local ref="$2"
    git ls-remote --quiet --exit-code --heads "$url" | grep -q "refs/heads/$ref"
}

# Check if the line is a comment
is_comment() {
    [[ "$1" =~ ^\s*#.*$ ]]
}

# Check if a URL exists and is reachable
url_exist() {
    local http_code
    http_code="$(curl --silent --output /dev/null --write-out "%{http_code}\n" "$1")"
    [ "$http_code" = '200' ]
}

# Append repository information to README.md
add_to_readme() {
    local repo_url="$1"
    local repo_name="$2"
    
    # Initialize README.md if it doesn't exist or is empty
    if [ ! -s README.md ]; then
        cat <<EOF >>README.md
# StreisandEffect

<details><summary>How to restore</summary>

## General instructions

1. Clone the \`archive\` branch

\`\`\`bash
git clone --branch archive https://github.com/your-username/your-repo streisandeffect
\`\`\`

2. Restore from bundle

\`\`\`bash
git clone streisandeffect/FILE.bundle
\`\`\`

## Download only a specific backup

\`\`\`bash
git clone --no-checkout --depth=1 --no-tags --branch archive https://github.com/your-username/your-repo streisandeffect
git -C streisandeffect restore --staged FILE.bundle
git -C streisandeffect checkout FILE.bundle
git clone streisandeffect/FILE.bundle
\`\`\`

</details>

| Status | Name | Software Heritage | Last Update |
| - | - | - | - |
EOF
    fi

    # Check Software Heritage link availability
    local software_heritage_md='Not available'
    if url_exist "$repo_url"; then
        software_heritage_md="[Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=$repo_url)"
    fi

    # Append repository status if not already present in README.md
    if ! grep -q "$repo_url" README.md; then
        local current_date
        current_date="$(date '+%d/%m/%Y')"
        if url_exist "$repo_url"; then
            echo "| 🟩 | [$repo_name]($repo_url) | $software_heritage_md | $current_date |" >>README.md
        elif [ -s "$repo_name.bundle" ]; then
            echo "| 🟨 | [$repo_name]($repo_url) | $software_heritage_md | $current_date |" >>README.md
        else
            echo "| 🟥 | [$repo_name]($repo_url) | $software_heritage_md | never |" >>README.md
        fi
    fi
}

# Update the last update date for a specific repository in README.md
update_repo_date() {
    local repo_url="$1"
    local current_date
    current_date="$(date '+%d/%m/%Y')"
    
    awk --assign url="$repo_url" --assign date="$current_date" '
    BEGIN {FS=OFS="|"} 
    $3 ~ url {$5 = " "date" "} 1' README.md >README.md.temp && mv --force README.md.temp README.md
}

# Set the status color for a specific repository in README.md
set_repo_status() {
    local repo_url="$1"
    local repo_name="$2"
    local color

    if url_exist "$repo_url"; then
        color='🟩'
    elif [ -s "$repo_name.bundle" ]; then
        color='🟨'
    else
        color='🟥'
    fi

    awk --assign url="$repo_url" --assign status="$color" '
    BEGIN {FS=OFS="|"} 
    $3 ~ url {$2 = " "status" "} 1' README.md >README.md.temp && mv --force README.md.temp README.md
    [ "$repo_name" = 'test-repo' ] && cat README.md
}

# Commit and push changes to the repository
commit_and_push() {
    local repo_name="$1"
    git add README.md
    git add "$repo_name.bundle" >/dev/null 2>&1

    if git diff --cached --quiet; then
        echo "No changes to commit for $repo_name."
        return
    fi

    if ! git commit --message="Update $repo_name" >/dev/null 2>&1; then
        echo "Failed to commit changes for $repo_name."
        exit 1
    fi

    # Enhanced error reporting for push
    if ! git push origin "$ARCHIVE_BRANCH" 2> >(tee /dev/stderr); then
        echo "Failed to push to $ARCHIVE_BRANCH."
        exit 1
    fi
}

# Main execution block
list="$(cat list.txt)"
init_git

# Loop through each entry in the list
while IFS= read -r entry; do
    # Check if entry is non-empty and not a comment
    if [[ -n "$entry" ]]; then
        if ! is_comment "$entry"; then
            repo_name="$(basename "$entry")"
            echo -e "\n\n---------------------------- Archiving ${repo_name}... ----------------------------\n\n"

            # Save the current bundle hash
            current_hash=''
            if [ -s "$repo_name.bundle" ]; then
                current_hash="$(sha256sum "$repo_name.bundle" | awk '{print $1}')"
            fi

            # Create a bundle if the repository exists and is not empty
            if repo_exist_not_empty "$entry"; then
                git clone --mirror --recursive -j8 "$entry" "$repo_name"
                git -C "$repo_name" bundle create "../$repo_name.bundle" --all
                rm -rf "$repo_name"
            fi

            # Update README.md with repository info
            echo "Adding repository info to README.md for $repo_name..."
            if ! add_to_readme "$entry" "$repo_name"; then
                echo "Failed to add to README.md"; exit 1
            fi
            set_repo_status "$entry" "$repo_name"

            # Save the new bundle hash
            new_hash='default_value'
            if [ -s "$repo_name.bundle" ]; then
                new_hash="$(sha256sum "$repo_name.bundle" | awk '{print $1}')"
            fi

            # If the bundle has changed, update the date and post to Software Heritage if enabled
            if [ "$new_hash" != "$current_hash" ]; then
                if [ "$new_hash" != 'default_value' ]; then
                    update_repo_date "$entry"
                fi

                # Post to Software Heritage
                if [ "$SOFTWARE_HERITAGE" = 'true' ]; then
                    response="$(curl --request POST "https://archive.softwareheritage.org/api/1/origin/save/git/url/$entry/" | jq --raw-output .save_request_status)"
                    echo "Software Heritage: $response"
                fi
            fi
            
            # Commit and push changes
            commit_and_push "$repo_name"
        fi
    fi
done <<<"$list"
