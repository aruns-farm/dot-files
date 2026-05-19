# dot-files

Arun's macOS dev setup. Run `setup.sh` on a fresh Mac and it handles everything.

---

## What's in here

| File / Script | Purpose |
|---|---|
| `setup.sh` | **Main bootstrapper** — run this first on a fresh Mac |
| `dot_zshrc` | Zsh config → applied to `~/.zshrc` |
| `dot_aerospace.toml` | AeroSpace window manager config → applied to `~/.aerospace.toml` |
| `Brewfile` | All Homebrew packages + casks |
| `macos.sh` | macOS system defaults (Finder, Dock, keyboard speed, etc.) |
| `folder-structure.sh` | Creates `~/dev/` and `~/Documents/` folder layout |
| `ssh-config.example` | SSH config template for office + personal GitHub keys |
| `save-ssh-to-bitwarden.sh` | Saves SSH keys to Bitwarden (run on existing machine before migrating) |
| `enable-bitwarden-ssh-agent.sh` | Wires up Bitwarden as your SSH agent |

---

## How dotfiles are managed (chezmoi)

This repo uses **[chezmoi](https://chezmoi.io)** to apply dotfiles to `$HOME`.

### Naming convention
Files starting with `dot_` in this repo map to hidden files in `$HOME`:
- `dot_zshrc` → `~/.zshrc`
- `dot_aerospace.toml` → `~/.aerospace.toml`

Scripts (`setup.sh`, `macos.sh`, etc.) are **not** managed by chezmoi — they stay in the repo and run directly.

### chezmoi config
`~/.config/chezmoi/chezmoi.toml` tells chezmoi to use this repo as its source:
```toml
sourceDir = "/Users/<you>/Documents/dot-files"
```
`setup.sh` writes this file automatically when it runs, with `$HOME` expanded to your actual home directory. (chezmoi does NOT expand `~` in this config, so an absolute path is required.)

### Daily workflow

**Edit a dotfile:**
```sh
# Option A — edit in the repo directly, then apply
nvim ~/Documents/dot-files/dot_zshrc
chezmoi apply

# Option B — let chezmoi open the source file for you
chezmoi edit ~/.zshrc
chezmoi apply
```

**See what would change before applying:**
```sh
chezmoi diff
```

**Check what files chezmoi is managing:**
```sh
chezmoi managed
```

**Add a new dotfile to chezmoi:**
```sh
chezmoi add ~/.some-new-config
# chezmoi copies it into ~/Documents/dot-files as dot_some-new-config
# then git add / commit it
```

**After pulling repo changes on another machine:**
```sh
git pull
chezmoi apply
```

---

## Fresh Mac setup

```sh
# 1. Clone this repo
git clone git@github.com:<your-username>/dot-files.git ~/Documents/dot-files

# 2. Run the bootstrapper
cd ~/Documents/dot-files
zsh setup.sh
```

`setup.sh` will:
1. Install Xcode CLI tools
2. Install Homebrew + everything in `Brewfile` (including chezmoi)
3. Pull SSH keys from Bitwarden (currently commented out — see Step 3 in setup.sh)
4. Install Oh My Zsh + plugins
5. Install Node (nvm), Python (pyenv)
6. Apply dotfiles via `chezmoi apply`
7. Configure git interactively (prompts for personal / office / freelance emails)
8. Set up Cloudflare tunnel config skeleton
9. Create `~/dev/` and `~/Documents/` folder structure
10. Optionally apply macOS system defaults
11. Run a health check showing all tools

**Before running on a new machine**, make sure you've run `save-ssh-to-bitwarden.sh` on your old machine so your SSH keys are in Bitwarden, then uncomment Step 3 in `setup.sh`.

---

## Git identities

`setup.sh` configures three git identities that switch automatically by folder:

| Folder | Identity used |
|---|---|
| `~/dev/office/` or `~/Documents/office/` | office email |
| `~/dev/personal/` or `~/Documents/personal/` | personal email |
| `~/dev/professional/` or `~/Documents/professional/` | freelance email |

Verify with: `git config user.email` inside any repo.

---

## Adding a new config to the repo

1. Add the file via chezmoi: `chezmoi add ~/.new-config`
2. chezmoi copies it to this repo as `dot_new-config`
3. Add it to git: `git add dot_new-config && git commit -m "add new-config"`
4. Add any non-`$HOME` files (scripts, etc.) to `.chezmoiignore`
