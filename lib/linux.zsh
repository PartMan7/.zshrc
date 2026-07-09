# Linux profile: g* aliases → system GNU, ls, clipboard, beep

alias ggrep='grep'
alias gsed='sed'
alias gawk='awk'
alias gfind='find'

alias ls="ls --color=auto"
alias l="ls -laGh --color=auto"

function beep {
  if command -v paplay >/dev/null 2>&1; then
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || printf '\a'
  else
    printf '\a'
  fi
}

function part_clipboard_copy {
  if [[ $# -gt 0 ]]; then
    if command -v wl-copy >/dev/null 2>&1; then
      print -r -- "$@" | wl-copy
    elif command -v xclip >/dev/null 2>&1; then
      print -r -- "$@" | xclip -selection clipboard
    else
      echo "part: no clipboard tool (wl-copy or xclip)" >&2
      return 1
    fi
    return
  fi
  if command -v wl-copy >/dev/null 2>&1; then
    wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
  else
    echo "part: no clipboard tool (wl-copy or xclip)" >&2
    return 1
  fi
}

function part_clipboard_paste {
  if command -v wl-paste >/dev/null 2>&1; then
    wl-paste
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard -o
  else
    echo "part: no clipboard tool (wl-paste or xclip)" >&2
    return 1
  fi
}

function part_notify_long_command {
  local notification_message="$1"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "partzsh" "$notification_message"
  fi
}
