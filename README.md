# StreisandEffect

This project is for automatically archiving Git repositories using GitHub Actions. It creates a [bundle](https://git-scm.com/docs/git-bundle) for each repository in a list, and hosts them in a separate branch.

See this [demo](https://github.com/uchks/StreisandEffect/tree/archive).

## Features

- Backup repositories to a GitHub repository
- Automatically update the archived repos
- Supports posting to the [Software Heritage](https://www.softwareheritage.org/)

## Usage

> [!TIP]  
> If you want to host your archives privately, you can also import this repo using [GitHub Importer](https://docs.github.com/en/migrations/importing-source-code/using-github-importer/importing-a-repository-with-github-importer#importing-a-repository-with-github-importer)

1. Fork this repository
2. Edit [`list.txt`](list.txt) with the URLs of the repositories you want to archive, one per line
3. Trigger the manual run by going to `Actions` -> `Update Archives` -> `Run Workflow`
4. (Optional) Change the update schedule in [`main.yml`](.github/workflows/main.yml)

> [!NOTE]  
> The results are stored in the `archive` branch by default
| 🟩 | [yt-dlp](https://github.com/yt-dlp/yt-dlp) | [Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=https://github.com/yt-dlp/yt-dlp) | 01/10/2024 |
| 🟩 | [ani-cli](https://github.com/pystardust/ani-cli) | [Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=https://github.com/pystardust/ani-cli) | 01/10/2024 |
| 🟩 | [stalker](https://github.com/marios-commissions/stalker) | [Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=https://github.com/marios-commissions/stalker) | 01/10/2024 |
| 🟩 | [Microsoft-Activation-Scripts](https://github.com/massgravel/Microsoft-Activation-Scripts) | [Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=https://github.com/massgravel/Microsoft-Activation-Scripts) | 01/10/2024 |
| 🟩 | [gibMacOS](https://github.com/corpnewt/gibMacOS) | [Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=https://github.com/corpnewt/gibMacOS) | 01/10/2024 |
| 🟩 | [PC-Tuning](https://github.com/valleyofdoom/PC-Tuning) | [Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=https://github.com/valleyofdoom/PC-Tuning) | 01/10/2024 |
| 🟩 | [limit-nvpstate](https://github.com/valleyofdoom/limit-nvpstate) | [Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=https://github.com/valleyofdoom/limit-nvpstate) | 01/10/2024 |
| 🟩 | [TimerResolution](https://github.com/valleyofdoom/TimerResolution) | [Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=https://github.com/valleyofdoom/TimerResolution) | 01/10/2024 |
