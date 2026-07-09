# Mac profile: brew GNU tools, BSD ls, clipboard, beep, IDE paths

if command -v brew >/dev/null 2>&1; then
  for _part_gnubin in \
    "$(brew --prefix grep)/libexec/gnubin" \
    "$(brew --prefix gnu-sed)/libexec/gnubin" \
    "$(brew --prefix gawk)/libexec/gnubin" \
    "$(brew --prefix findutils)/libexec/gnubin" \
    "$(brew --prefix coreutils)/libexec/gnubin"
  do
    [[ -d "$_part_gnubin" ]] && export PATH="$_part_gnubin:$PATH"
  done
  unset _part_gnubin
fi

alias ls="ls -G --color=auto"
alias l="ls -laGh --color=auto"

alias beep='afplay /System/Library/Sounds/Glass.aiff'

function part_clipboard_copy {
  if [[ $# -gt 0 ]]; then
    print -r -- "$@" | pbcopy
  else
    pbcopy
  fi
}

function part_clipboard_paste {
  pbpaste
}

function part_notify_long_command {
  osascript -e "display notification \"$1\""
}

export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"
