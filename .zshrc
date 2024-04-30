# PartMan's .zshrc

# First-time setup:

## Enable git optimizations:
### git config core.fsmonitor true
### git config core.untrackedcache true

## Install GNU tools (ggrep, gsed, etc):
### brew install autoconf bash binutils coreutils diffutils ed findutils flex gawk gnu-indent gnu-sed gnu-tar gnu-which gpatch grep gzip less m4 make nano screen watch wdiff wget zip

## Setup config files:
### Configure REL_CODE_PATH and MAPPINGS_PATH

## Configure WebStorm for CLI use:
### https://www.jetbrains.com/help/webstorm/working-with-the-ide-features-from-command-line.html#arguments


# PROMPT
## Current timestamp (HH:MM:SS)
## Blue $ for regular shell, red # for administrative shell
## EDIT: The $ has been replaced with a 🥔 due to a cybercriminal colleague
## Lavender relative path to ~/Documents/Code (represented by relative path) if inside a code folder
## If not, green relative path to $HOME if inside the user directory
## In other cases, yellow absolute path

# RPROMPT
## If the folder matches a label in the code mappings file (@/code-mappings.md), display the appropriate label in cyan
## If inside a .git repository, show the current branch in purple
## If the revision ID isn't avilable (eg: merge conflict) show a red 'conflicts' message
## If there are git diffs, show:
## white # for modified diffs
## green + for no modified diffs but some added diffs
## red ! for no additions or modifications but some deleted diffs
## grey * for all other cases

## Every time a cmmand is run, PROMPT will be set to the timestamp from runtime, and RPROMPT is removed for the duration of the command

# Commands
## If the command takes more than 1s to complete, display the time taken


# Reload .zshrc
alias rzr="exec zsh"

# All code directories are stored under ~/Documents/Code; rename as-needed
REL_CODE_PATH='Documents/Code'
CODE_PATH="$HOME/$REL_CODE_PATH"
# The code-mappings file stores a list of all mappings in the code folder in tabular MD
# Example of a mappings file:
: '

| Editor | Use |
|----|----|
| **SU1** | Migrate forms-app |
| **SU2** | Integrate Codemod |
| **SU3** | Style Infra Migration |
| **SU4** | Ref |

'
MAPPINGS_PATH="$CODE_PATH/code-mappings.md"

preexec_functions=()
precmd_functions=()

# Enable tab-completion
autoload -Uz compinit && compinit

# Enable Git status
autoload -Uz vcs_info
zstyle ':vcs_info:git*' formats '%r' '%b' # Root folder, current branch
zstyle ':vcs_info:*' enable git

# Prompt formatting
setopt promptsubst
# PROMPT='%F{8}[%*]%f %(!.%F{red}#.🥔)%f %F{11}${${PWD//$HOME/%F{48\}~}//\~\/$REL_CODE_PATH\//%F{105\}}%f '
PROMPT='%F{8}[%*]%f %(!.%F{red}#.%F{50}§)%f %F{11}${${PWD//$HOME/%F{48\}~}//\~\/$REL_CODE_PATH\//%F{105\}}%f '

setopt appendhistory # Append to the common history file instead of overwriting it
setopt autocd # Automatically cd to the given path when it is a valid directory and not a command
setopt cdsilent # Disable the 'cd to' message when using cd -
setopt interactivecomments # Allow inline #
setopt correct # Enable autocorrection
setopt globdots # Enable dot-prefixed file indexing by default
setopt histignoredups # Ignore duplicate entries in history
setopt recexact # Don't autocomplete if an exact match is found

# Init Ruby Env
eval "$(rbenv init - zsh)"

# ls
alias ls="ls -G --color=auto"
alias l="ls -laGh --color=auto"
function lc() {
  if [ -d "$@" ]; then ls -laGh --color=auto $@;
  elif [ -f "$@" ]; then less -rf $@;
  else echo "Not found"; return 1
  fi
}

alias grec="grep --color=auto"

alias yeet="killall -15"
alias murder="killall -9"

alias whew="gco main && gpp && gbc |: && htr && yarn && remap"

alias yb="yarn build"
alias yarn-ddos="yarn docs:dev:only-spaceweb"

alias multicat="tail -n +1"

# git aliases
function gb() {
  git merge-base HEAD "${1:-origin/main}"
}
alias gbc="git branch | ggrep -vEe '^\\*|main' | xargs git branch -d " # Git Branch Clean
alias gbC="git branch | ggrep -vEe '^\\*|main' | xargs git branch -D " # Git Branch [C]lean
alias gbd="git branch -d" # Git Branch Delete
alias gbD="git branch -D" # Git Branch [D]elete
alias gbl="git branch" # Git Branch List
function gc() { # Git (chore) Commit
  htr
  git add .
  git commit -m "[SPACE-00] chore: $*"
  cd -
}
alias gcam="git commit -am" # Git Commit -AM
alias gcb="git checkout -b" # Git Checkout -B
alias gcl="git config --list" # Git Config --List
alias gcm="git checkout main" # Git Checkout Main
alias gco="git checkout" # Git CheckOut
alias gcp="git cherry-pick" # Git Cherry-Pick
alias gcpa="git cherry-pick --no-commit --strategy=recursive -X theirs" # Git Cherry-Pick Aggressive
function gcr() { # Git Checkout Remote
  git fetch origin "$1"
  git checkout "$1"
}
function gd() { # Git Diff
  if [ $# -eq 0 ]; then
    git diff
    return
  fi
  local ctx_ref=$1
  if [[ "$ctx_ref" =~ '^[0-9]+$' ]]; then
    ctx_ref="HEAD~$ctx_ref"
  fi
  git diff "$ctx_ref" "${@:2}"
}
function gds() { # Git Diff --Stat
  gd --stat $*
}
function gdss() { # Git Diff --ShortStat
  gd --shortstat $*
}
alias gfl="git ls-tree --name-only -r HEAD" # Git Files List
function glc() { # Git Lazy Commit
  htr
  git add .
  git commit -m "[SPACE-00] chore: $*" -n
  cd -
}
GIT_LOG_FORMAT=("--pretty=format:%C(8)%H%Creset %Cgreen%ad%Creset %C(8)[%Cred%><(16,trunc)%an%C(8)]%Creset %C(yellow)%<|($COLUMNS,trunc)%s%Creset" "--date=format-local:%F %R")
alias gl='git -c color.ui=always log $GIT_LOG_FORMAT' # Git Log
alias gln="$aliases[gl] -n" # Git Log -N
alias gmm="git fetch origin main; git merge origin/main"
function gmr() { # Git MR
  local merge_head=$(git merge-base HEAD "origin/${1:-main}")
  local git_commits=$(git -c color.ui=always -c core.pager= log $GIT_LOG_FORMAT "$merge_head..HEAD")
  local summary=$(gdss $(git merge-base HEAD main))
  local commit_count=$(echo "$git_commits" | wc -l)
  echo "$commit_count commit(s)"
  echo "$summary"
  echo "$git_commits"
}
alias gmrf='git diff $(git merge-base HEAD main)' # Git MR Full
alias gmrs='gds $(git merge-base HEAD main)' # Git MR Stat
alias gmrss='gdss $(git merge-base HEAD main)' # Git MR ShortStat
alias gph="git push origin HEAD" # Git Push origin Head Unsafe
alias gphf="git push origin HEAD --force-with-lease" # Git Push origin Head Force
alias gpu="git pull origin HEAD" # Git PUll
alias gpp="git fetch \$(git-head) && git merge FETCH_HEAD" # Git Pull Partial
alias gppf="git fetch \$(git-head) && git reset --hard FETCH_HEAD" # Git Pull Partial Forced
GIT_SED_COLORIZER='/\x1b\[31m/{/\x1b\[32m/{h};s/^/\x1b[31m/;s/$/\x1b[m/;s/\x1b\[31m\[-/\x1b[m\x1b[41m\x1b[1m/g;s/-]\x1b\[m/\x1b[49m\x1b[31m/g;s/\x1b\[32m[^\x1b]*\+}\x1b\[m//g;p;x};/\x1b\[32m/{s/^/\x1b[32m/;s/$/\x1b[m/;s/\x1b\[32m\{\+/\x1b[m\x1b[42m\x1b[1m/g;s/\+}\x1b\[m/\x1b[49m\x1b[32m/g;s/\x1b\[31m[^\x1b]*-]\x1b\[m//g};/^\x1b\[1m((diff --git)|(index )|(\+{3}))/d;s/^\x1b\[1m-{3} a\//\x1b[1m\x1b[2m/'
GIT_SED_STRIP_HUNKS='/^--$/{d};/\x1b\[2m/{n};/^\x1b\[((36m@@)|(1m\x1b\[2m))/!{H;$!d;};x;/\x1b\[3[12]m/!d'
GIT_SED_STRIP_FILENAMES='/\x1b\[2m/!{x;p;d;x;p};/\x1b\[2m/{h}'
function gqd() { # Git Quick Diff
  git -c core.whitespace=-trailing-space,-indent-with-non-tab,-tab-in-indent diff --color -w --word-diff-regex='[^[:space:]]' -U1 $* | gsed -re "$GIT_SED_COLORIZER" | gsed -re "$GIT_SED_STRIP_HUNKS" | gsed -nre "$GIT_SED_STRIP_FILENAMES"
}
function gqdf() { # Git Quick Diff Filtered
  local GQD_FILTER=${argv[-1]}
  unset 'argv[-1]'
  git -c core.whitespace=-trailing-space,-indent-with-non-tab,-tab-in-indent diff --color -w --word-diff-regex='[^[:space:]]' -U1 $* | ggrep -U1 -P "^\\x1b\\[1m-{3}|^\\x1b\\[36m|$GQD_FILTER" | gsed -re "$GIT_SED_COLORIZER" | gsed -re "$GIT_SED_STRIP_HUNKS" | gsed -nre "$GIT_SED_STRIP_FILENAMES"
}
alias grhcf="git reset --hard; git clean -f" # Git Reset --Hard; git Clean -F
alias grh="git reset --hard" # Git Reset --Hard
alias grm='git rebase origin/main' # Git Rebase Main
function grr() {
  git fetch origin "${1:-main}"
  git rebase "origin/${1:-main}"
}
alias grs='git reset --soft' # Git Reset --Soft
alias grum='git fetch origin main; git rebase origin/main' # Git Rebase with Updated Main
alias gs='git status' # Git Status
alias gum="git fetch origin main" # Git Update Main
alias gup="git log --branches --not --remotes --no-walk --decorate --pretty='format:%Cred%<(32,ltrunc)%S%Creset %C(8)%H%Creset %C(yellow)%<(40,trunc)%s%Creset'" # Git UnPushed
alias gust="git restore --staged ." # Git UnSTage
function git-head() {
  local git_head=$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2>/dev/null)
  if [ ! $? ]; then
    echo "$git_head" | sed 's!/! !'
  else
    echo "origin $(git branch --show-current)"
  fi
}
alias git-log="git log --graph --decorate --oneline \$(git rev-list -g --all)"
function git-lgtm() { # Git LGTM
  cd $(git rev-parse --show-toplevel)
  git add .
  git commit -m "[SPACE-00] chore: $@" -n
  git push
  cd -
}
alias git-yeet="git reset --hard; git clean -df"


# cd to Code
function cdc() {
  if [ $@ ]; then cd "$CODE_PATH/$@"; else cd "$CODE_PATH"; fi
}

# Color helpers
alias color="parallel -ukq print -P"
alias nocolor="gsed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'"

# Show current mappings
function mappings() {
  local list_of_mappings=$(ggrep -E '\*\* \| [^-]' "$MAPPINGS_PATH")
  if [ $@ ]; then
    list_of_mappings=$(echo "$list_of_mappings" | ggrep -Ei "$@")
  fi
  echo "$list_of_mappings" | gsed -r -e 's/\*\*/%F{62}/1' -e 's/\*\*/%F{8}:%F{cyan} /1' -e 's/\s?\|\s?//g' -e 's/$/%f/' | color
}

# Rename current mapping
function remap() {
  htr && gsed -ri "/\*\*$(basename $PWD)\*\*/{s/[^\\|]*\\|\$/ ${*:-Ref} |/}" "$MAPPINGS_PATH" && cd -
}

function get_code_context() {
  local mapped=$(mappings "$@")
  local number_of_lines=$(echo "$mapped" | nocolor | ggrep -cvEe '^\s*$')
  if [ $number_of_lines -eq 0 ]; then
    mapped=$(find "$CODE_PATH" -maxdepth 1 -type d -mindepth 1 | cut -d '/' -f 6 | ggrep -Ei "$@")
    number_of_lines=$(echo "$mapped" | nocolor | ggrep -cvEe '^\s*$')
  fi
  if [ $number_of_lines -eq 0 ]; then
    echo 'No matches found'
    return 1
  elif [ $number_of_lines -eq 1 ]; then
    local dir_to_go_to=$(echo "${mapped%:*}" | nocolor)
    CODE_CONTEXT="$dir_to_go_to"
  else
    echo "$mapped" | grep -n '.' | gsed -re 's/^([0-9]:)/ \1/1' -e 's/^/%F{8}/' -e 's/:/: %f/1' | color
    read project_num
    while [ $project_num -a $project_num -gt $number_of_lines -o $project_num -lt 1 ]; do
      echo "Invalid index"
      read project_num
    done
    local dir_to_go_to=$(echo "$mapped" | gsed -n "${project_num}p" | nocolor)
    CODE_CONTEXT="${dir_to_go_to%:*}"
  fi
}

# Quickly CheckOut a project
function co() {
  get_code_context "$@"
  cdc "$CODE_CONTEXT"
}

# Hop to a project with the same relative path; eg: S2/packages/docs -> S3/packages/docs
function hop() {
  get_code_context "$@"
  local file_path=(${(s:/:)PWD})
  local src_folder=(${file_path[5]})
  cd "$(echo "$PWD" | sed "s/$src_folder/$CODE_CONTEXT/")"
}

# Get project Root
function gr() {
  unset CODE_ROOT
  if [ $vcs_info_msg_0_ ]; then
    # Git conflicts break this...
    if [[ ! $vcs_info_msg_0_ == *']-' ]]; then
      # In a repo; use the root
      CODE_ROOT=$vcs_info_msg_0_
    fi
  fi
  if [ ! $CODE_ROOT ]; then
    # Check if we're in Code - if so, use the Code/* folder
    local file_path=(${(s:/:)PWD})
    local src_folder=(${file_path[4]})
    local base_folder=(${file_path[5]})
    if [[ $src_folder && $base_folder && $src_folder == "Code" ]]; then
      CODE_ROOT=$base_folder
    fi
  fi

  if [ $CODE_ROOT ]; then
    CODE_ROOT="$CODE_PATH/$CODE_ROOT"
  fi
}

# Hop To project Root
function htr() {
  gr
  if [ $CODE_ROOT ]; then
    cd "$CODE_ROOT"
  else
    echo "Not in repository/codefolder"
    return 1
  fi
}

function wheeee() {
  gr
  if [[ "$1" == force ]]
    then local force_wheeee=1
    else local force_wheeee=0
  fi
  local project_name=$(jq '.name' "$CODE_ROOT/package.json" -r)
  case $project_name in
    spaceweb)
      htr
      if [[ $force_wheeee -eq 1 ]]; then yarn build --scope=spaceweb-themes; fi
      yarn docs:dev:only-spaceweb
    ;;
    sprinklr-app-client)
      htw
      if [[ $force_wheeee -eq 1 ]]; then yarn prebuild; fi
      yarn next-dev:only
    ;;
    *)
      echo "Uhh no idea how to handle $project_name sorry"
    ;;
  esac
}
alias wheeeee='wheeee force'

# Yarn Workspace
function yw() {
  local mapped=$(yarn workspaces list --json | jq -r '[.location,.name] | join(" ")' | grep "$@")
  local number_of_lines=$(echo "$mapped" | nocolor | ggrep -cvEe '^\s*$')
  if [ $number_of_lines -eq 0 ]; then
    echo 'No matches found'
    return 1
  elif [ $number_of_lines -eq 1 ]; then
    local dir_to_go_to=$(echo "${mapped%:*}" | nocolor)
    local workspace_context="$dir_to_go_to"
  else
    echo "$mapped" | grep -n '.' | gsed -re 's/^([0-9]:)/ \1/1' -e 's/^/%F{8}/' -e 's/:/: %F{63}/1' -e 's/ ([^ ]+$)/ %F{50}\1/' -e 's/@sprinklrjs\//%F{8}@sprinklrjs%F{50}\//' -e 's/$/%f/' | color
    read project_num
    while [ $project_num -a $project_num -gt $number_of_lines -o $project_num -lt 1 ]; do
      echo "Invalid index"
      read project_num
    done
    local dir_to_go_to=$(echo "$mapped" | gsed -n "${project_num}p" | nocolor)
    local workspace_context="${dir_to_go_to%:*}"
  fi
  htr
  cd $(echo "$workspace_context" | cut -d' ' -f 1)
}

alias htw="yw spr-main-web" # Hop To apps/spr-main-Web
alias hts="htr; cd packages/spaceweb" # Hop To Spaceweb

# Debug VRT
alias vrt-debug="yarn ts-node internals/vrt/scripts/preVrt.ts && node internals/vrt/scripts/lostPixelCopyFolder.js && node internals/vrt/scripts/lostPixelJson.js && yarn docs:dev:only-spaceweb"

# Launch WebStorm
function ws() {
  if [ $# -eq 0 ]; then
    local file_path=(${(s:/:)PWD})
    local src_folder=(${file_path[5]})
    webstorm "$CODE_PATH/$src_folder"
  elif [ $@ -a -d "$CODE_PATH/$@" ]; then
    webstorm "$CODE_PATH/$@"
  else
    echo "No valid folder passed"
  fi
}

# Launch Webstorm in the relevant context
function cows() {
  get_code_context "$@"
  ws "$CODE_CONTEXT"
}

# Run the current repository/workspace
function go() {
  # if [[ $PWD ~= ]]
}

# Show Longest Running Process(es) (LRP)
function lrp() {
  if [[ $1 && $1 =~ '^[0-9]+$' ]]; then
    local amount_of_processes="-$1"
  fi
  local list_of_processes=$(ps -So 'etime,command')
  list_of_processes=$(echo "$list_of_processes" |
    tail -n +2 |
    ggrep -Ev '\bzsh|fsmonitor--daemon' |
    sort -rk1 |
    gsed -r 's/^\s+//'
  )
  local formatted_list=$(echo "$list_of_processes" |
    gsed -re 's/[^ ]*\/(yarn|node)([^ ,]*\..?js)/\1/' \
      -e 's/--max-old-space-size=([0-9]+)[0-9]{3}/%F{8}\1GB%f/' \
      -e 's/ [^ ]+\// %F{8}#%f/g' -e 's/^[0-9:.-]+/%F{50}\0%f/' \
      -e 's/log --pretty(.(\?! --))*/log %F{8}pretty%f\1/' \
      -e 's/--pretty/%F{8}pretty%f/' \
      -e 's/%F\{8}#%f(yarn|node|tsc) /\1 /g' |
    uniq -c |
    gawk '{ freq=$1; $1=""; print $0 (freq == "1" ? " " : " %F{62}x" freq "%f") }'
  )
  if [ $amount_of_processes ]; then formatted_list=$(echo "$formatted_list" | head "$amount_of_processes"); fi
  if echo "$formatted_list" | grep -qE 'node %F\{8}\d+.B.*tsc'; then
    formatted_list=$(echo "$formatted_list" | grep -v 'node yarn tsc')
  fi
  if [ $formatted_list ]; then
    echo "$formatted_list" | color
  else
    return 1
  fi
}

function reset_prompt_time() {
  unset RPROMPT
  zle reset-prompt
  zle accept-line
}
zle -N reset_prompt_time
bindkey "^M" reset_prompt_time

# Command timers
function preexec_cmd_timer() {
  CMD_TIMER=$(print -P %D{%s%3.})
}
function precmd_cmd_timer() {
  if [ $CMD_TIMER ]; then
    local now=$(print -P %D{%s%3.})
    local d_ms=$(($now - $CMD_TIMER))
    local d_s=$((d_ms / 1000))
    local ms=$((d_ms % 1000))
    local s=$((d_s % 60))
    local m=$(((d_s / 60) % 60))
    local h=$((d_s / 3600))

    if   ((h > 0)); then CMD_TIMER_STRING="${h}h ${m}m ${s}s" # 1h 2m 3s
    elif ((m > 0)); then CMD_TIMER_STRING="${m}m ${s}s" # 1m 12s
    elif ((s > 9)); then CMD_TIMER_STRING="${s}.$(printf %02d $(($ms / 10)))s" # 12.34s
    elif ((s > 0)); then CMD_TIMER_STRING="${s}.$(printf %03d $ms)s" # 1.234s
    else unset CMD_TIMER_STRING
    fi
    unset CMD_TIMER
    if [ $CMD_TIMER_STRING ]; then print -P "%F{60}Command executed in %F{62}$CMD_TIMER_STRING%f\n"; fi
  fi
}


# VCS RPROMPT

function precmd_vcs_info() {
  vcs_info # Check VCS status
  unset RPROMPT

  # RPROMPT purpose
  local code_root
  local rprompt_warning
  if [ $vcs_info_msg_0_ ]; then
    # Git conflicts break this...
    if [[ $vcs_info_msg_0_ == *']-' ]]; then
      rprompt_warning='conflicts'
    else
      unset rprompt_warning
      # In a repo; use the root
      code_root=$vcs_info_msg_0_
    fi
  fi
  if [ ! $code_root ]; then
    # Check if we're in Code - if so, use the Code/* folder
    local file_path=(${(s:/:)PWD})
    local src_folder=(${file_path[4]})
    local base_folder=(${file_path[5]})
    if [[ $src_folder && $base_folder && $src_folder == "Code" ]]; then
      code_root=$base_folder
    fi
  fi
  if [ $code_root ]; then
    # Check for folder in mappings file
    local repo_label=$(cat "$MAPPINGS_PATH" | grep -E "^\\| \\*\\*${code_root}\\*\\* \\| .*? \\|$" -om 1 | cut -d "|" -f 3 | awk '{$1=$1};1')
    if [ $repo_label -a $repo_label != "-" ]; then
      RPROMPT+="%F{50}$repo_label%f"
    fi
  fi

  # RPROMPT branch
  if [ $vcs_info_msg_1_ ]; then
    local git_status=$(git status --porcelain)
    local diff_char
    if echo "$git_status" | grep -qE '^ ?M'; then
      diff_char='%f# '
    elif echo "$git_status" | grep -qE '^ ?A'; then
      diff_char='%F{green}+ '
    elif echo "$git_status" | grep -qE '^ ?D'; then
      diff_char='%F{red}! '
    elif echo "$git_status" | grep -qE '^\?\?'; then
      diff_char='%F{8}* '
    else
      unset diff_char
    fi
    RPROMPT="$diff_char$RPROMPT%F{8}<%F{63}$vcs_info_msg_1_%F{8}>%f"
  elif [ $rprompt_warning ]; then
    RPROMPT+="%F{8}<%F{red}$rprompt_warning%F{8}>%f"
  fi

  if [ $RPROMPT ]; then RPROMPT=" $RPROMPT"; fi
}

ASCII_MESSAGES_WALK="\n   ____          __                                    _ _    \n  / ___| ___    / _| ___  _ __    __ _  __      ____ _| | | __\n | |  _ / _ \\  | |_ / _ \\| '__|  / _\` | \\ \\ /\\ / / _\` | | |/ /\n | |_| | (_) | |  _| (_) | |    | (_| |  \\ V  V / (_| | |   < \n  \\____|\\___/  |_|  \\___/|_|     \\__,_|   \\_/\\_/ \\__,_|_|_|\\_\\ \n                                                              \n"
ASCII_MESSAGES_HYDRATION="\n  ______                     _               _                             _ \n / _____) _                 | |             | |              _            | |\n( (____ _| |_ _____ _   _   | |__  _   _  __| | ____ _____ _| |_ _____  __| |\n \\____ (_   _|____ | | | |  |  _ \\| | | |/ _  |/ ___|____ (_   _) ___ |/ _  |\n _____) )| |_/ ___ | |_| |  | | | | |_| ( (_| | |   / ___ | | |_| ____( (_| |\n(______/  \\__)_____|\\__  |  |_| |_|\\__  |\\____|_|   \\_____|  \\__)_____)\\____|\n                   (____/         (____/                                     \n\n"

# Hydration Reminders
LAST_HYDRATION_REMINDER=$SECONDS

function precmd_hydration() {
  local current_time=$SECONDS
  if (( current_time - LAST_HYDRATION_REMINDER >= 3600 )); then
    echo "$ASCII_MESSAGES_HYDRATION"
    LAST_HYDRATION_REMINDER=$current_time
  fi
}


precmd_functions+=(precmd_cmd_timer precmd_vcs_info precmd_hydration)
preexec_functions+=(preexec_cmd_timer)


# NVM setup
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Command completions
source ~/.zshcompletions
