# partzsh

Portable zsh setup for Mac (office), Bazzite KDE, and Ubuntu SSH.

## Install / update

```sh
curl -fsSL https://raw.githubusercontent.com/PartMan7/.zshrc/main/install.sh | sh
```

Installs to `~/.partzsh` (git clone), writes `~/.partzsh/conf/zsh.conf` on first run, and appends a source block to `~/.zshrc`. Re-run the same command to update.

## Layout

```text
~/.partzsh/
  install.sh
  zshrc                 # loader
  conf/zsh.conf         # local (not committed)
  conf/repos/*.conf     # per-repo matchers
  lib/core.zsh          # shared shell
  lib/mac.zsh | linux.zsh
  lib/work.zsh          # if work=yes
  scripts/diffaxe.sh
  data/code-mappings.md
```

## `.part` helper

- `.part default-branch` — resolved default branch for current repo
- `.part install-deps` — run install command from repo config (e.g. `yarn`)
- `.part copy` / `.part paste` — clipboard (pbcopy / wl-copy)

Repo configs live in `conf/repos/*.conf`:

```sh
match=spaceweb|SU[0-9]+
default_branch=main
install_deps=yarn
```

## GNU tools (`ggrep`, `gsed`, …)

- **macOS:** Homebrew installs `ggrep`, `gsed`, `gawk`, etc. (brew required).
- **Linux:** `lib/linux.zsh` aliases `ggrep`→`grep`, `gsed`→`sed`, `gawk`→`awk`.

## Breaking / hard-to-decouple

1. **Mac requires brew** for GNU `g*` tools.
2. **work=yes** loads Sprinklr helpers (`wheeee`, `git-ticket`, `branches`/`repos`, Rancher PATH).
3. **Clipboard / beep / notifications** differ by OS.
4. **IDE paths** (WebStorm, Sublime) are Mac-oriented.
5. **Bazzite:** login shell stays bash; installer adds bash→zsh `exec` to `~/.bashrc` ([why not chsh](https://tim.siosm.fr/blog/2023/12/22/dont-change-defaut-login-shell/)).
6. **`find -E`** is BSD; Linux work helpers use `-regextype posix-extended`.
7. **Existing `~/.zshrc`** gets a marker block appended; back up once if needed.
