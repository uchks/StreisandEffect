#!/usr/bin/env bash

ARCHIVE_BRANCH='archive'
SOFTWARE_HERITAGE='true'

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $@"
}

init_git() {
    git config user.name 'github-actions[bot]'
    git config user.email 'github-actions[bot]@users.noreply.github.com'
    git checkout --orphan "$ARCHIVE_BRANCH" || { log "Failed to create orphan branch"; exit 1; }
    find . -not -name '*.bundle' -not -path './.git*' -exec git rm -rf "{}" \;
    git pull origin "$ARCHIVE_BRANCH" || log "Failed to pull $ARCHIVE_BRANCH"
}

repo_exist_not_empty() {
    git ls-remote --quiet --exit-code --heads "$1" | grep --max-count 1 "refs/heads/$2" &>/dev/null
    return $?
}

is_comment() {
    [[ "$1" =~ ^\s*[#].*$ ]]
}

url_exist() {
    [[ "$(curl --silent --output /dev/null --write-out "%{http_code}" "$1")" == "200" ]]
}

add_to_readme() {
    local repo_url="$1"
    local repo_name="$2"

    if [[ ! -s README.md ]]; then
        cat <<EOF > README.md
# StreisandEffect

<details><summary>How to restore</summary>

## General instructions

1. Clone the \`archive\` branch

```bash
git clone --branch archive https://github.com/your-username/your-repo streisandeffect
```

2. Restore from bundle

```bash
git clone streisandeffect/FILE.bundle
```

## Download only a specific backup

```bash
git clone --no-checkout --depth=1 --no-tags --branch archive https://github.com/your-username/your-repo streisandeffect
git -C streisandeffect restore --staged FILE.bundle
git -C streisandeffect checkout FILE.bundle
git clone streisandeffect/FILE.bundle
```

</details>

| Status | Name | Software Heritage | Last Update |
| - | - | - | - |
EOF
    fi

    local software_heritage_md='Not available'
    url_exist "$repo_url" && software_heritage_md="[Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=$repo_url)"

    if ! grep --silent "$repo_url" README.md; then
        current_date="$(date '+%d/%m/%Y')"
        echo "| 🟩 | [$repo_name]($repo_url) | $software_heritage_md | $current_date |" >> README.md
    fi
}

update_repo_date() {
    local repo_url="$1"
    local current_date="$(date '+%d/%m/%Y')"

    awk --assign url="$repo_url" --assign date="$current_date" 'BEGIN {FS=OFS="|"} $3 ~ url {$5=" "date" "} 1' README.md > README.md.temp && mv --force README.md.temp README.md
}

set_repo_status() {
    local repo_url="$1"
    local repo_name="$2"
    local color='🟥'

    if url_exist "$repo_url"; then
        color='🟩'
    elif [[ -s "$repo_name.bundle" ]]; then
        color='🟨'
    fi

    awk --assign url="$repo_url" --assign status="$color" 'BEGIN {FS=OFS="|"} $3 ~ url {$2=" "status" "} 1' README.md > README.md.temp && mv --force README.md.temp README.md
    [ "$repo_name" = 'test-repo' ] && cat README.md
}

commit_and_push() {
    local repo_name="$1"

    log "Adding README.md to the commit"
    git add README.md || { log "Failed to add README.md"; return 1; }

    log "Adding $repo_name.bundle to the commit"
    git add "$repo_name.bundle" || { log "Failed to add $repo_name.bundle"; return 1; }

    log "Committing changes"
    git commit --message="Update $repo_name" || { log "Failed to commit changes"; return 1; }

    log "Pushing changes to $ARCHIVE_BRANCH"
    git push origin "$ARCHIVE_BRANCH" || { log "Failed to push changes to $ARCHIVE_BRANCH"; return 1; }
}

mapfile -t repos < list.txt
init_git
for entry in "${repos[@]}"; do
    if [[ -n "$entry" ]] && ! is_comment "$entry"; then
        repo_name="$(basename "$entry")"
        log "---------------------------- Archiving ${repo_name}... ----------------------------"

        current_hash=''
        if [[ -s "$repo_name.bundle" ]]; then
            current_hash="$(sha256sum "$repo_name.bundle" | awk '{print $1}')"
        fi

        if repo_exist_not_empty "$entry" "$ARCHIVE_BRANCH"; then
            git clone --mirror --recursive -j8 "$entry" "$repo_name" || { log "Failed to clone $repo_name"; continue; }
            git -C "$repo_name" bundle create "../$repo_name.bundle" --all || { log "Failed to create bundle for $repo_name"; continue; }
            rm -rf "$repo_name"
        fi

        add_to_readme "$entry" "$repo_name"
        set_repo_status "$entry" "$repo_name"

        new_hash='default_value'
        if [[ -s "$repo_name.bundle" ]]; then
            new_hash="$(sha256sum "$repo_name.bundle" | awk '{print $1}')"
        fi

        if [[ "$new_hash" != "$current_hash" ]]; then
            if [[ "$new_hash" != 'default_value' ]]; then
                update_repo_date "$entry"
            fi

            if [[ "$SOFTWARE_HERITAGE" == 'true' ]]; then
                response="$(curl --request POST "https://archive.softwareheritage.org/api/1/origin/save/git/url/$entry/" | jq --raw-output .save_request_status)"
                log "Software Heritage: $response"
            fi
        fi

        commit_and_push "$repo_name"
    fi
done