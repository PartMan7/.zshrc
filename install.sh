#!/bin/sh
# partzsh installer — POSIX sh
# curl -fsSL https://raw.githubusercontent.com/PartMan7/.zshrc/main/install.sh | sh
#
# Re-run to update (git pull + re-check deps).
#
# Breaking / hard-to-decouple notes:
# - Mac requires Homebrew (brew) for GNU g* tools (ggrep, gsed, etc.)
# - Linux uses system GNU grep/sed/gawk; ggrep/gsed are aliases in lib/linux.zsh
# - work=yes profile loads Sprinklr-specific helpers (wheeee, git-ticket, branches/repos)
# - Clipboard/beep/notifications differ by OS (pbcopy vs wl-copy, afplay vs paplay)
# - IDE paths (WebStorm, Sublime) are Mac-oriented; Cursor uses ~/.local/bin
# - Bazzite: login shell stays bash; installer appends bash→zsh exec to ~/.bashrc
# - Does not run chsh; see https://tim.siosm.fr/blog/2023/12/22/dont-change-defaut-login-shell/

set -e

PARTZSH="${PARTZSH:-$HOME/.partzsh}"
REPO_URL="${PARTZSH_REPO_URL:-https://github.com/PartMan7/.zshrc.git}"
MARKER_BEGIN="# >>> partzsh >>>"
MARKER_END="# <<< partzsh <<<"
BASH_MARKER="# partzsh: exec zsh from bash"

die() {
  echo "partzsh install: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

need_cmd git
need_cmd curl

OS=$(uname -s)
case "$OS" in
  Darwin) IS_MAC=1; IS_LINUX=0 ;;
  Linux) IS_MAC=0; IS_LINUX=1 ;;
  *) IS_MAC=0; IS_LINUX=0 ;;
esac

install_mac_deps() {
  command -v brew >/dev/null 2>&1 || die "brew not found (required on macOS)"
  brew install autoconf bash binutils coreutils diffutils ed findutils flex gawk \
    gnu-indent gnu-sed gnu-tar gnu-which gpatch grep gzip less m4 make nano parallel \
    patchutils screen watch wdiff wget zip
}

install_linux_deps() {
  for cmd in grep sed awk find parallel git curl zsh; do
    command -v "$cmd" >/dev/null 2>&1 || die "required command not found on Linux: $cmd"
  done
  # Verify GNU grep (ggrep alias target)
  grep --version 2>/dev/null | head -1 | grep -qi gnu || \
    echo "partzsh install: warning: grep may not be GNU; ggrep alias expects GNU grep" >&2
}

if [ "$IS_MAC" -eq 1 ]; then
  install_mac_deps
elif [ "$IS_LINUX" -eq 1 ]; then
  install_linux_deps
fi

if [ -d "$PARTZSH/.git" ]; then
  if ! git -C "$PARTZSH" diff --quiet 2>/dev/null || ! git -C "$PARTZSH" diff --cached --quiet 2>/dev/null; then
    die "$PARTZSH has local changes; commit or stash before updating"
  fi
  git -C "$PARTZSH" pull --ff-only origin main || git -C "$PARTZSH" pull --ff-only
else
  if [ -d "$PARTZSH" ]; then
    die "$PARTZSH exists but is not a git repo; remove it or set PARTZSH elsewhere"
  fi
  git clone "$REPO_URL" "$PARTZSH"
fi

CONF="$PARTZSH/conf/zsh.conf"
if [ ! -f "$CONF" ]; then
  mkdir -p "$PARTZSH/conf"
  if [ "$IS_MAC" -eq 1 ]; then
    MAC_VAL=yes
    LINUX_VAL=no
  elif [ "$IS_LINUX" -eq 1 ]; then
    MAC_VAL=no
    LINUX_VAL=yes
  else
    MAC_VAL=no
    LINUX_VAL=no
  fi

  printf "Enable work profile (Sprinklr helpers)? [y/N] "
  read -r work_ans
  case "$work_ans" in
    [yY]|[yY][eE][sS]) WORK_VAL=yes ;;
    *) WORK_VAL=no ;;
  esac

  printf "Code path relative to HOME [Documents/Code]: "
  read -r code_path_ans
  [ -z "$code_path_ans" ] && code_path_ans="Documents/Code"

  cat >"$CONF" <<EOF
work=$WORK_VAL
mac=$MAC_VAL
linux=$LINUX_VAL
code_path=$code_path_ans
mappings_path=
EOF
  echo "partzsh install: wrote $CONF"
fi

mkdir -p "$PARTZSH/data"

ZSHRC="$HOME/.zshrc"
SOURCE_LINE='source "$HOME/.partzsh/zshrc"'

append_zshrc_marker() {
  if [ -f "$ZSHRC" ] && grep -qF "$MARKER_BEGIN" "$ZSHRC" 2>/dev/null; then
    return 0
  fi
  {
    echo ""
    echo "$MARKER_BEGIN"
    echo "$SOURCE_LINE"
    echo "$MARKER_END"
  } >>"$ZSHRC"
  echo "partzsh install: appended source block to $ZSHRC"
}

append_zshrc_marker

append_bashrc_snippet() {
  BASHRC="$HOME/.bashrc"
  [ -f "$BASHRC" ] || return 0
  grep -qF "$BASH_MARKER" "$BASHRC" 2>/dev/null && return 0

  ZSH_BIN=$(command -v zsh 2>/dev/null || echo /bin/zsh)
  [ -x "$ZSH_BIN" ] || return 0

  {
    echo ""
    echo "$BASH_MARKER"
    echo "# https://tim.siosm.fr/blog/2023/12/22/dont-change-defaut-login-shell/"
    echo "if [ -z \"\${BASH_EXECUTION_STRING:-}\" ] && [ -x \"$ZSH_BIN\" ]; then"
    echo "  case \"\$(ps -o comm= -p \"\$PPID\" 2>/dev/null | tr -d ' ')\" in"
    echo "    zsh|*/zsh) ;;"
    echo "    *)"
    echo "      if shopt -q login_shell 2>/dev/null; then LOGIN_OPTION='--login'; else LOGIN_OPTION=''; fi"
    echo "      exec \"$ZSH_BIN\" \$LOGIN_OPTION"
    echo "      ;;"
    echo "  esac"
    echo "fi"
  } >>"$BASHRC"
  echo "partzsh install: appended bash→zsh snippet to $BASHRC"
}

append_bashrc_snippet

echo ""
echo "partzsh install: done. Open a new shell or run: exec zsh"
echo "Update anytime: curl -fsSL https://raw.githubusercontent.com/PartMan7/.zshrc/main/install.sh | sh"
