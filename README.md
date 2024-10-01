# StreisandEffect

<details><summary>How to restore</summary>

## General instructions

1. Clone the `archive` branch

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
| 🟩 | [yt-dlp](https://github.com/yt-dlp/yt-dlp) | [Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=https://github.com/yt-dlp/yt-dlp) | 01/10/2024 |
