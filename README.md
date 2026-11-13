# pi-kit

Default [pi](https://pi.dev) setup for Artefactory: shared extensions, skills, prompts, themes, and base settings.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/artefactory/pi-kit/main/install.sh | sh
```

Requirements: `git`, `jq`, `npm`, and SSH access to GitHub (`ssh -T git@github.com`).

The script is idempotent. It:

1. installs pi if missing,
2. installs the packages listed in [`packages.txt`](packages.txt) plus this kit,
3. merges [`defaults.json`](defaults.json) into `~/.pi/agent/settings.json` — your existing values are never overwritten, only missing keys are added.

Use `./install.sh --dry-run` to see what would happen.

LLM access (provider, keys) is **not** handled here: use `atf pi`.

## What's inside

| Path | Purpose |
|---|---|
| `packages.txt` | Pi packages everyone gets |
| `defaults.json` | Base settings (UI, default tools…) |
| `extensions/` | Private extensions (`*.ts`) |
| `skills/` | Shared skills (one directory per skill with `SKILL.md`) |
| `prompts/` | Prompt templates (`*.md`) |
| `themes/` | Themes (`*.json`) |

This directory is itself a pi package, installed as `git:git@github.com:artefactory/pi-kit`.

## Update

```sh
pi update --extensions
```

Bump `version` in `package.json` and add a `CHANGELOG.md` entry when you change an extension: pi shows the entry to everyone on their next launch.

## Opt out of something

`pi config` lets each person disable individual extensions, skills, or prompts without forking the kit.

## Per-project settings

Project-specific packages or models belong in the project's `.pi/settings.json`, not here.
