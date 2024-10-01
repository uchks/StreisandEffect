#!/usr/bin/env bash

ARCHIVE_BRANCH='archive'
SOFTWARE_HERITAGE='true'

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $@"
}

init_git() {
    git config user.name 'github-actions[bot]'
    git config user.email 'github-actions[bot]@users.noreply.github.com'
    
    # Check if the archive branch exists or create it
    if ! git show-ref --verify --quiet "refs/heads/$ARCHIVE_BRANCH"; then
        log "Creating $ARCHIVE_BRANCH branch."
        git checkout -b "$ARCHIVE_BRANCH"
    else
        log "Switching to existing $ARCHIVE_BRANCH branch."
        git checkout "$ARCHIVE_BRANCH"
    fi

    # Clean up the working tree
    find . -not -name '*.bundle' -not -path './.git*' -exec git rm -rf "{}" \;
    git pull origin "$ARCHIVE_BRANCH" || log "Failed to pull $ARCHIVE_BRANCH"
}

repo_exist_not_empty() {
    git ls-remote --quiet --exit-code --heads "$1" &>/dev/null
}

is_comment() {
    [[ "$1" =~ ^\s*[#].*$ ]]
}

url_exist() {
    curl --silent --output /dev/null --write-out "%{http_code}" "$1" | grep -q "200"
}

get_latest_commit_hash() {
    git ls-remote "$1" HEAD | awk '{print $1}'
}

update_readme() {
    local repo_url="$1"
    local repo_name="$2"
    local current_date="$(date '+%d/%m/%Y')"
    local software_heritage_md='Not available'

    url_exist "$repo_url" && software_heritage_md="[Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=$repo_url)"

    if [[ ! -s README.md ]]; then
        cat <<EOF > README.md
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

    if ! grep --silent "$repo_url" README.md; then
        local status_icon='🟥'
        [[ $(url_exist "$repo_url") ]] && status_icon='🟩' || [[ -s "$repo_name.bundle" ]] && status_icon='🟨'
        echo "| $status_icon | [$repo_name]($repo_url) | $software_heritage_md | $current_date |" >> README.md
    fi
}

commit_and_push() {
    local repo_name="$1"
    git add README.md "$repo_name.bundle" 2>/dev/null
    git commit --message="Update $repo_name" && git push origin "$ARCHIVE_BRANCH"
}

# Read repository list from file
mapfile -t repos < list.txt
init_git

for entry in "${repos[@]}"; do
    [[ -n "$entry" && ! is_comment "$entry" ]] || continue

    local repo_name="$(basename "$entry")"
    log "---------------------------- Archiving ${repo_name}... ----------------------------"

    local latest_commit_hash
    latest_commit_hash=$(get_latest_commit_hash "$entry")
    local existing_hash
    [[ -f "$repo_name.bundle" ]] && existing_hash="$(git rev-parse "$repo_name.bundle" 2>/dev/null || echo '')"

    if repo_exist_not_empty "$entry"; then
        git clone --mirror --recursive -j8 "$entry" "$repo_name" || { log "Failed to clone $repo_name"; continue; }

        # Create or update the bundle if the latest commit hash differs
        if [[ -n "$latest_commit_hash" && "$latest_commit_hash" != "$existing_hash" ]]; then
            git -C "$repo_name" bundle create "../$repo_name.bundle" --all
            log "Updated bundle for $repo_name."
        else
            log "Bundle is up-to-date for $repo_name, skipping update."
        fi

        rm -rf "$repo_name"
        update_readme "$entry" "$repo_name"

        # Post to Software Heritage
        if [[ "$SOFTWARE_HERITAGE" == 'true' ]]; then
            local response
            response="$(curl --request POST "https://archive.softwareheritage.org/api/1/origin/save/git/url/$entry/" | jq --raw-output .save_request_status)"
            log "Software Heritage: $response"
        fi

        commit_and_push "$repo_name"
    else
        log "$entry does not exist or is empty."
    fi
done
