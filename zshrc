# partzsh loader — sourced from ~/.zshrc
export PARTZSH="${PARTZSH:-$HOME/.partzsh}"

if [[ -f "$PARTZSH/conf/zsh.conf" ]]; then
  source "$PARTZSH/conf/zsh.conf"
fi

: "${work:=no}"
: "${mac:=no}"
: "${linux:=no}"
: "${code_path:=Documents/Code}"

source "$PARTZSH/lib/core.zsh"

if [[ "$mac" == yes ]]; then
  source "$PARTZSH/lib/mac.zsh"
elif [[ "$linux" == yes ]]; then
  source "$PARTZSH/lib/linux.zsh"
fi

if [[ "$work" == yes ]]; then
  source "$PARTZSH/lib/work.zsh"
fi

[[ -f "$PARTZSH/completions/.zshcompletions" ]] && source "$PARTZSH/completions/.zshcompletions"
