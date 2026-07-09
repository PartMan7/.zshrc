# PartMan's partzsh core

REL_CODE_PATH="${code_path:-Documents/Code}"
export CODE_PATH="$HOME/$REL_CODE_PATH"
if [[ -n "$mappings_path" ]]; then
  export MAPPINGS_PATH="$mappings_path"
else
  export MAPPINGS_PATH="$PARTZSH/data/code-mappings.md"
fi

# region part — repo config + .part helper #

function _part_load_repo_conf {
  local conf="$1"
  [[ -f "$conf" ]] || return 1
  local line key val
  PART_DEFAULT_BRANCH=main
  PART_INSTALL_DEPS=yarn
  while IFS= read -r line; do
    [[ "$line" =~ '^[[:space:]]*#' ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue
    key="${line%%=*}"
    val="${line#*=}"
    case "$key" in
      default_branch) PART_DEFAULT_BRANCH="$val" ;;
      install_deps) PART_INSTALL_DEPS="$val" ;;
    esac
  done < "$conf"
}

function part_part_resolve_repo {
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    unset PART_RESOLVED_ROOT PART_DEFAULT_BRANCH PART_INSTALL_DEPS
    return 1
  }
  if [[ "$PART_RESOLVED_ROOT" == "$git_root" && -n "$PART_DEFAULT_BRANCH" ]]; then
    return 0
  fi
  PART_RESOLVED_ROOT="$git_root"
  local name=$(basename "$git_root")
  local conf_dir="$PARTZSH/conf/repos"
  local conf_file match_line pattern

  for conf_file in "$conf_dir"/*.conf(N); do
    [[ "$(basename "$conf_file")" == "default.conf" ]] && continue
    match_line=$(grep '^match=' "$conf_file" 2>/dev/null | head -1)
    [[ -z "$match_line" ]] && continue
    pattern="${match_line#match=}"
    if [[ "$pattern" == '*' ]]; then
      continue
    fi
    if [[ "$name" == "$pattern" ]] || [[ "$name" =~ $pattern ]]; then
      _part_load_repo_conf "$conf_file"
      return 0
    fi
  done
  _part_load_repo_conf "$conf_dir/default.conf"
}

function .part {
  case "$1" in
    default-branch)
      part_part_resolve_repo 2>/dev/null
      echo "${PART_DEFAULT_BRANCH:-main}"
      ;;
    install-deps)
      part_part_resolve_repo 2>/dev/null
      local cmd="${PART_INSTALL_DEPS:-yarn}"
      [[ -n "$cmd" ]] && eval "$cmd"
      ;;
    copy)
      shift
      if [[ $# -gt 0 ]]; then
        part_clipboard_copy "$@"
      else
        part_clipboard_copy
      fi
      ;;
    paste)
      part_clipboard_paste
      ;;
    *)
      echo "usage: .part default-branch|install-deps|copy|paste" >&2
      return 1
      ;;
  esac
}

function _part_main_branch {
  part_part_resolve_repo 2>/dev/null
  echo "${PART_DEFAULT_BRANCH:-main}"
}

function _part_code_base_idx {
  echo $((${#${(s:/:)CODE_PATH}} + 1))
}

# endregion #

# region config #

autoload -Uz compinit && compinit

autoload -Uz vcs_info
zstyle ':vcs_info:git*' formats '%r' '%b'
zstyle ':vcs_info:*' enable git

setopt promptsubst
PROMPT='%F{8}[%*]%f %(!.%F{red}#.%F{50}§)%f %F{11}${${PWD//$HOME/%F{48\}~}//\~\/$REL_CODE_PATH\//%F{105\}}%f '

setopt appendhistory autocd cdsilent interactivecomments correct globdots extendedglob histignoredups recexact

bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
bindkey '\ef' forward-word
bindkey '\eb' backward-word

function reset_prompt_time {
  unset RPROMPT
  zle reset-prompt
  zle accept-line
}
zle -N reset_prompt_time
bindkey "^M" reset_prompt_time

# endregion #

# region utils #

alias rzr='exec zsh'

alias color="parallel -q --keep-order print -P"
alias nocolor="gsed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'"

export LESS='--quit-if-one-screen -R'

alias ll='lc'
function lc {
  if [ -d "$@" ]; then ls -laGh --color=auto "$@";
  elif [ -f "$@" ]; then less -rxf "$@";
  else echo "Not found"; return 1
  fi
}

alias grec="grep --color=auto"

alias yeet="killall -15"
alias murder="killall -9"

alias multicat="tail -n +1"
alias count="sort | uniq -c | sort"

function js {
  node -p "$*"
}

alias docker-yeet="docker container prune --force && docker image prune --all --force && docker builder prune --all --force"

function lrp {
  if [[ $1 && $1 =~ '^[0-9]+$' ]]; then
    local amount_of_processes="-$1"
  fi
  local list_of_processes=$(ps -So 'pid,etime,command')
  list_of_processes=$(echo "$list_of_processes" |
    tail -n +2 |
    ggrep -Ev '\bzsh|fsmonitor--daemon' |
    sort -rk2 |
    gsed -r 's/^\s+//'
  )
  local enriched=""
  local code_leaf="${CODE_PATH##*/}"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local pid=${line%% *}
    local rest=${line#* }
    local cwd=$(lsof -p "$pid" -w 2>/dev/null | awk '$4=="cwd" {print $9}')
    local root=""
    if [[ -n "$cwd" ]]; then
      local cwd_parts=(${(s:/:)cwd})
      local code_idx=$(_part_code_base_idx)
      if [[ "${cwd_parts[$((code_idx - 1))]}" == "$code_leaf" ]]; then
        root="${cwd_parts[$code_idx]}"
      fi
    fi
    enriched+="${rest}"$'\t'"${root}"$'\n'
  done <<< "$list_of_processes"
  enriched="${enriched%$'\n'}"
  local formatted_list=$(echo "$enriched" |
    gsed -re 's/^\s+//' \
      -e 's/[^ ]*\/(yarn|node)([^ ,]*\..?js)/\1/' \
      -e 's/--max-old-space-size=([0-9]+)[0-9]{3}/%F{8}\1GB%f/' \
      -e 's/ [^ ]+\// %F{8}#%f/g' \
      -e 's/^[0-9:.-]+/%F{50}&%f/' \
      -e 's/log --pretty(.(\?! --))*/log %F{8}pretty%f\1/' \
      -e 's/--pretty/%F{8}pretty%f/' \
      -e 's/%F\{8}#%f(yarn|node|tsc) /\1 /g' \
      -e 's/node yarn /yarn /g' |
    uniq -c |
    gawk -F'\t' '{ match($1, /^ *([0-9]+) (.*)/, m); freq=m[1]; cmd=m[2]; root=$2; i=index(cmd," "); tc=(i>0 ? substr(cmd,1,i-1) : cmd); cc=(i>0 ? substr(cmd,i+1) : ""); print " " tc "," (length(root)>0 ? "%F{105}" root "%f" : "%F{240}???%f") "," cc "," (freq+0==1 ? "" : "%F{62}x" freq "%f") }'
  )
  if [ $amount_of_processes ]; then formatted_list=$(echo "$formatted_list" | head "$amount_of_processes"); fi
  if echo "$formatted_list" | grep -qE 'node %F\{8}\d+.B.*tsc'; then
    formatted_list=$(echo "$formatted_list" | grep -v 'node yarn tsc')
  fi
  if [ $formatted_list ]; then
    echo "$formatted_list" | color | column -t -s ','
  else
    return 1
  fi
}

# endregion #

# region git #

function git-prefix { echo "" }
function git-ticket { : }

alias branch-to-name="gsed -r 's#^.*/[^-]*-[^-]*-##;s/-/ /g;s/^.| ./\\U\\0/g;s/\\b[AU]i\\b/\\U\\0/g'"

function g {
  local repo_path=$(git rev-parse --git-dir 2>/dev/null)
  local nohooks=()
  if [ -n "$NOHOOKS" ]; then nohooks=(-c core.hooksPath=/dev/null); fi
  local sequencer_arg=--continue
  case "$1" in
    c) sequencer_arg=--continue ;;
    s) sequencer_arg=--skip ;;
    a|x) sequencer_arg=--abort ;;
    q) sequencer_arg=--quit ;;
    ?*) sequencer_arg="--$1" ;;
  esac

  if [ -d "${repo_path}/rebase-merge" ]; then
    git "${nohooks[@]}" rebase "$sequencer_arg"
  elif [ -d "${repo_path}/rebase-apply" ]; then
    git "${nohooks[@]}" rebase "$sequencer_arg"
  elif [ -f "${repo_path}/MERGE_HEAD" ]; then
    git "${nohooks[@]}" merge "$sequencer_arg"
  elif [ -f "${repo_path}/CHERRY_PICK_HEAD" ]; then
    git "${nohooks[@]}" cherry-pick "$sequencer_arg"
  elif [ -f "${repo_path}/REVERT_HEAD" ]; then
    git "${nohooks[@]}" revert "$sequencer_arg"
  else
    echo No sequencer in progress
  fi
}

function gac {
  git add `gtf $*`
}

function gb {
  local branch=$(_part_main_branch)
  git merge-base HEAD "${1:-origin/$branch}"
}

function gbc {
  local branch=$(_part_main_branch)
  git branch | ggrep -vEe "^\*|${branch}" | xargs git branch -d
}

function gbC {
  local branch=$(_part_main_branch)
  git branch | ggrep -vEe "^\*|${branch}" | xargs git branch -D
}

alias gbd="git branch -d"
alias gbD="git branch -D"
alias gbl="git branch"

function gbn {
  git rev-parse --abbrev-ref ${@:-@} 2>/dev/null
}

function gc {
  htr
  git add `gtf`
  git commit -m "$(git-prefix)$(git-commit-message $*)"
  cd -
}

alias gcam="git commit -am"

function gcb {
  git checkout -b $*
  remap `echo $* | branch-to-name`
}

function gch {
  .part copy "$(git rev-parse @)"
}

alias gcl="git config --list"

function gcm {
  local branch=$(_part_main_branch)
  git checkout "$branch"
  git fetch origin "$branch"
  git merge FETCH_HEAD
  .part install-deps
}

function gcpl {
  git log --pretty=format:%H --reverse ${*:-`gb`...@} | gsed -zE 's/\n/ /g'
  echo
}

alias gco="git checkout"
alias gcp="git cherry-pick"
alias gcpa="git cherry-pick --no-commit --strategy=recursive -X theirs"

function gcpr {
  git fetch origin "$@"
  git cherry-pick "$@"
}

function gcr {
  gcrny "$1"
  remap `echo $1 | branch-to-name`
  .part install-deps
}

function gcrny {
  git fetch origin "$1"
  git checkout "$1"
  git reset --hard FETCH_HEAD
}

alias gcrt='git commit --amend -n -m "$(git log -1 --pretty=%B | gsed -r "s/\\[\w*-[[:digit:]]*\\]//")"'

function gd {
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

function gds { gd --stat $* }
function gdss { gd --shortstat $* }

alias gf="git fetch origin"
alias gfc="git commit --no-verify --no-edit"
alias gfl="git ls-tree --name-only -r HEAD"
alias gflg="git ls-tree --name-only -r HEAD | ggrep"

function glc {
  htr
  git add `gtf`
  git commit -m "$(git-prefix)$(git-commit-message $*)" -n
  cd -
}

GIT_LOG_FORMAT=("--pretty=format:%C(8)%h%Creset %Cgreen%ad%Creset %C(8)[%Cred%><(16,trunc)%an%C(8)]%Creset %C(yellow)%<|(-1,trunc)%s%Creset" "--date=format-local:%F %R")
alias gl='git -c color.ui=always log $GIT_LOG_FORMAT'
alias gln="$aliases[gl] -n"

function gmm {
  local branch=$(_part_main_branch)
  git fetch origin "$branch"
  git merge "origin/$branch"
}

function gmr {
  local branch="${1:-$(_part_main_branch)}"
  local merge_head=$(git merge-base HEAD "origin/$branch")
  local git_commits=$(git -c color.ui=always -c core.pager= log ${GIT_LOG_FORMAT//-1/$COLUMNS} "$merge_head..HEAD")
  local summary=$(gdss $merge_head)
  local commit_count=$([[ -n "$git_commits" ]] && (echo "$git_commits" | wc -l) || echo No)
  echo "$commit_count commit(s)"
  if [[ -n "$summary" ]]; then echo "$summary"; fi
  if [[ -n "$git_commits" ]]; then echo "$git_commits"; fi
  git merge-tree HEAD "origin/$branch" | sed -n '/CONFLICT/p'
}

function gmrf {
  local branch=$(_part_main_branch)
  git diff $(git merge-base HEAD "origin/$branch")
}

function gmrs {
  local branch=$(_part_main_branch)
  gds $(git merge-base HEAD "origin/$branch")
}

function gmrss {
  local branch=$(_part_main_branch)
  gdss $(git merge-base HEAD "origin/$branch")
}

function gnac {
  htr
  git commit -m "$(git-prefix)$(git-commit-message $*)"
  cd -
}

alias gp='npx prettier -w `gtf | grep -E -e "\.tsx?" -e "\.[cm]?jsx?" -e "\.json"`'
alias gph="git push origin HEAD"
alias gphf="git push origin HEAD --force-with-lease"
alias gpu="git pull origin HEAD"

function gpp {
  local branch=$(_part_main_branch)
  git fetch origin "$branch" && git fetch $(git-head) && git merge FETCH_HEAD
}

function gppf {
  local branch=$(_part_main_branch)
  git fetch origin "$branch" && git fetch $(git-head) && git reset --hard FETCH_HEAD
}

GIT_SED_COLORIZER='/\x1b\[31m/{/\x1b\[32m/{h};s/^/\x1b[31m/;s/$/\x1b[m/;s/\x1b\[31m\[-/\x1b[m\x1b[41m\x1b[30;1m/g;s/-]\x1b\[m/\x1b[49m\x1b[31m/g;s/\x1b\[32m[^\x1b]*\+}\x1b\[m//g;p;x};/\x1b\[32m/{s/^/\x1b[32m/;s/$/\x1b[m/;s/\x1b\[32m\{\+/\x1b[m\x1b[42m\x1b[30;1m/g;s/\+}\x1b\[m/\x1b[49m\x1b[32m/g;s/\x1b\[31m[^\x1b]*-]\x1b\[m//g};/^\x1b\[1m((diff --git)|(index )|(\+{3}))/d;s/^\x1b\[1m-{3} a\//\x1b[30;1m\x1b[2m/'
GIT_SED_STRIP_HUNKS='/^--$/{d};/\x1b\[2m/{x;/\x1b\[3[12]m/p;s/.*//;x;n};/^\x1b\[((36m@@)|(1m\x1b\[2m))/!{H;$!d;};x;/\x1b\[3[12]m/!d'
GIT_SED_STRIP_FILENAMES='/\x1b\[2m/{h;d};x;/\x1b\[2m/{p;s/.*//};x;p'

function gqd {
  git -c core.whitespace=-trailing-space,-indent-with-non-tab,-tab-in-indent diff --color -w --word-diff-regex='[^[:space:]]' -U1 $* | gsed -re "$GIT_SED_COLORIZER" | gsed -re "$GIT_SED_STRIP_HUNKS" | gsed -nre "$GIT_SED_STRIP_FILENAMES"
}

function gqdf {
  local GQD_FILTER=${argv[-1]}
  unset 'argv[-1]'
  git -c core.whitespace=-trailing-space,-indent-with-non-tab,-tab-in-indent diff --color -w --word-diff-regex='[^[:space:]]' -U1 $* | ggrep -U1 -P "^\\x1b\\[1m-{3}|^\\x1b\\[36m|$GQD_FILTER" | gsed -re "$GIT_SED_COLORIZER" | gsed -re "$GIT_SED_STRIP_HUNKS" | gsed -nre "$GIT_SED_STRIP_FILENAMES"
}

function grc {
  git commit --amend -n -m "$(git log -1 --pretty=%B | sed $*)"
}

alias grhcf="git reset --hard; git clean -f"
alias grh="git reset --hard"

function grhr {
  git fetch origin $1
  git reset --hard FETCH_HEAD
}

alias gri='git rebase --interactive'

function grm {
  local branch=$(_part_main_branch)
  git rebase "origin/$branch"
}

function grmr {
  local branch="${1:-$(_part_main_branch)}"
  git rebase --interactive `git merge-base HEAD "origin/$branch"`
}

function gro {
  htr
  git stash
  local branch="${1:-$(_part_main_branch)}"
  git fetch origin "$branch"
  git rebase "origin/$branch"
  git stash pop
  cd -
}

function grob {
  local branch="${1:-$(_part_main_branch)}"
  git fetch origin "$branch"
  git rebase "origin/$branch"
}

function gror {
  git fetch origin "$1"
  git rebase --onto "origin/$1" "origin/$1@{${2:-1}}"
}

function grp {
  git -c color.ui=always log -n 1 ${GIT_LOG_FORMAT//\%h/\%H} $*
}

alias grs='git reset --soft'

function grum {
  local branch=$(_part_main_branch)
  git fetch origin "$branch"
  git rebase "origin/$branch"
}

alias grvp='git rev-parse'

function gryl {
  .part install-deps
  git add :/yarn.lock && g continue
}

alias gs='git status'
alias gsp='git status --porcelain'
alias gspno='git status --porcelain | sed "s/^ . //"'

function gsr {
  local editor="gsed -i -e $1"
  GIT_SEQUENCE_EDITOR="$editor" git -c core.hooksPath=/dev/null rebase --interactive "${@:2}"
}

alias gtf="git status --short | sed 's/^.. //;s/.* -> //;/_test.tsx/d'"
alias guar='htr; git fetch $(git-head); git stash; git reset --hard FETCH_HEAD; git stash pop; cd -'

function gum {
  local branch=$(_part_main_branch)
  git fetch origin "$branch"
}

alias gup="git log --branches --not --remotes --no-walk --decorate --pretty='format:%Cred%<(32,ltrunc)%S%Creset %C(8)%H%Creset %C(yellow)%<(40,trunc)%s%Creset'"
alias gust="git restore --staged ."

function vimg {
  local files=($(gflg "$@"))
  if (( ${#files[@]} == 0 )); then echo "No results..."; return; fi
  if (( ${#files[@]} == 1 )); then vim "$files"; return; fi
  select file in "${files[@]}"; do
    if [[ -f "$file" ]]; then vim "$file"; fi
    break
  done
}

function git-axe {
  GREPDIFF_REGEX="${@[$#]}" GIT_EXTERNAL_DIFF="$PARTZSH/scripts/diffaxe.sh" git -c color.ui=always log -p --ext-diff -S $*
}

function git-head {
  git_head="$(git rev-parse --verify --quiet --symbolic-full-name --abbrev-ref '@{upstream}')"
  local res="$?"
  local git_head
  if [ $res -eq 0 ] && [ -n "$git_head" ]; then
    echo "$git_head" | sed 's!/! !'
  else
    echo "origin $(git branch --show-current)"
  fi
}

alias git-log="git log --graph --decorate --oneline \$(git rev-list -g --all)"

function git-lgtm {
  cd $(git rev-parse --show-toplevel)
  git add `gtf`
  git commit -m "$(git-prefix)$(git-commit-message $*)" -n
  git push
  cd -
}

function git-sed {
  for file in `git grep  --name-only "$1"`
  do
    gsed -i -r -e "$2" $file
  done
}

function git-commit-message {
  local git_message="${*:-Update}"
  if ! [[ "$git_message" =~ ':' ]]
  then
    echo "chore: $git_message"
  else
    echo "$git_message"
  fi
}

alias git-nohooks='git -c core.hooksPath=/dev/null'
alias git-yeet="git reset --hard; git clean -df"

# endregion #

# region navigation #

function cdc {
  if [ $@ ]; then cd "$CODE_PATH/$*"; else cd "$CODE_PATH"; fi
}

function whew {
  local branch=$(_part_main_branch)
  if [[ -n $1 ]] cd "$CODE_PATH/$1"
  if ! git diff --quiet @; then git status --porcelain; echo '%F{red}Local changes found!%f' | color; return 1; fi
  gco "$branch" && gpp && gbc ||: && htr && (.part install-deps; remap)
}

function mappings {
  local list_of_mappings=$(ggrep -E '\*\* \| [^-]' "$MAPPINGS_PATH")
  if [ $@ ]; then
    list_of_mappings=$(echo "$list_of_mappings" | ggrep -Ei "$@")
  fi
  echo "$list_of_mappings" | gsed -r -e 's/\*\*/%F{62}/1' -e 's/\*\*/%F{8}:%F{cyan} /1' -e 's/\s?\|\s?//g' -e 's/$/%f/' | color
}

function remap {
  get-root
  gsed -ri "/\*\*$(basename "$CODE_ROOT")\*\*/{s/[^\\|]*\\|\$/ ${*:-Ref} |/}" "$MAPPINGS_PATH"
}

function get_code_context {
  local mapped=$(mappings "$@")
  local number_of_lines=$(echo "$mapped" | nocolor | ggrep -cvEe '^\s*$')
  if [ $number_of_lines -eq 0 ]; then
    mapped=$(find "$CODE_PATH" -maxdepth 1 -type d -mindepth 1 -exec basename {} \; | ggrep -Ei "$@")
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

function co {
  get_code_context "$@"
  cdc "$CODE_CONTEXT"
}

function hop {
  get_code_context "$@"
  local file_path=(${(s:/:)PWD})
  local code_idx=$(_part_code_base_idx)
  local src_folder=(${file_path[$code_idx]})
  if [[ -z "$src_folder" ]]
  then cdc "$CODE_CONTEXT"
  else cd "$(echo "$PWD" | sed "s/$src_folder/$CODE_CONTEXT/")"
  fi
}

function get-root {
  unset CODE_ROOT
  local code_leaf="${CODE_PATH##*/}"
  local code_idx=$(_part_code_base_idx)
  if [ $vcs_info_msg_0_ ]; then
    if [[ ! $vcs_info_msg_0_ == *']-' ]]; then
      CODE_ROOT=$vcs_info_msg_0_
    fi
  fi
  if [ ! $CODE_ROOT ]; then
    local file_path=(${(s:/:)PWD})
    local src_folder=(${file_path[$((code_idx - 1))]})
    local base_folder=(${file_path[$code_idx]})
    if [[ $src_folder && $base_folder && $src_folder == "$code_leaf" ]]; then
      CODE_ROOT=$base_folder
    fi
  fi

  if [ $CODE_ROOT ]; then
    CODE_ROOT="$CODE_PATH/$CODE_ROOT"
  fi
}

function htr {
  get-root
  if [ $CODE_ROOT ]; then
    cd "$CODE_ROOT"
  else
    echo "Not in repository/codefolder"
    return 1
  fi
}

function yw {
  local mapped=$(yarn workspaces list --json | jq -r '[.location,.name] | join(" ")' | grep "$@")
  local number_of_lines=$(echo "$mapped" | nocolor | ggrep -cvEe '^\s*$')
  if [ $number_of_lines -eq 0 ]; then
    echo 'No matches found'
    return 1
  elif [ $number_of_lines -eq 1 ]; then
    local dir_to_go_to=$(echo "${mapped%:*}" | nocolor)
    local workspace_context="$dir_to_go_to"
  else
    echo "$mapped" | grep -n '.' | gsed -re 's/^([0-9]:)/ \1/1' -e 's/^/%F{8}/' -e 's/:/: %F{63}/1' -e 's/ ([^ ]+$)/ %F{50}\1/' -e 's/@sprinklrjs\//%F{8}@sprinklrjs\/%F{50}/' -e 's/$/%f/' | color
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

# endregion #

# region hooks #

preexec_functions=()
precmd_functions=()

function preexec_cmd_timer {
  CMD_TIMER=$(print -P %D{%s%3.})
}

function precmd_cmd_timer {
  EXIT_STATUS=$?
  if [ $CMD_TIMER ]; then
    local now=$(print -P %D{%s%3.})
    local d_ms=$(($now - $CMD_TIMER))
    local d_s=$((d_ms / 1000))
    local ms=$((d_ms % 1000))
    local s=$((d_s % 60))
    local m=$(((d_s / 60) % 60))
    local h=$((d_s / 3600))

    if   ((h > 0)); then CMD_TIMER_STRING="${h}h ${m}m ${s}s"
    elif ((m > 0)); then CMD_TIMER_STRING="${m}m ${s}s"
    elif ((s > 9)); then CMD_TIMER_STRING="${s}.$(printf %02d $(($ms / 10)))s"
    elif ((s > 0)); then CMD_TIMER_STRING="${s}.$(printf %03d $ms)s"
    else unset CMD_TIMER_STRING
    fi
    unset CMD_TIMER
    if [ $CMD_TIMER_STRING ]; then print -P "%F{60}Command executed in %F{62}$CMD_TIMER_STRING%f\n"; fi
    if ((m > 1)); then
      beep
      local notification_message="Command: $CMD_ARGS\nProcess $(test $EXIT_STATUS = 0 && echo succeeded || echo failed) after $CMD_TIMER_STRING"
      if typeset -f part_notify_long_command > /dev/null; then
        part_notify_long_command "$notification_message"
      fi
    fi
  fi
}

function preexec_cmd_info {
  CMD_ARGS="$1"
  CMD_PWD=$(pwd)
}

function precmd_vcs_info {
  vcs_info
  unset RPROMPT

  local code_root
  local rprompt_warning
  local main_branch=$(_part_main_branch)
  if [ $vcs_info_msg_0_ ]; then
    if [[ $vcs_info_msg_0_ == *']-' ]]; then
      rprompt_warning='conflicts'
    else
      unset rprompt_warning
      code_root=$vcs_info_msg_0_
    fi
  fi
  if [ ! $code_root ]; then
    local file_path=(${(s:/:)PWD})
    local code_idx=$(_part_code_base_idx)
    local code_leaf="${CODE_PATH##*/}"
    local src_folder=(${file_path[$((code_idx - 1))]})
    local base_folder=(${file_path[$code_idx]})
    if [[ $src_folder && $base_folder && $src_folder == "$code_leaf" ]]; then
      code_root=$base_folder
    fi
  fi
  if [ $code_root ]; then
    local repo_label=$(cat "$MAPPINGS_PATH" | grep -E "^\\| \\*\\*${code_root}\\*\\* \\| .*? \\|$" -om 1 | cut -d "|" -f 3 | awk '{$1=$1};1')
    if [ $repo_label -a $repo_label != "-" ]; then
      RPROMPT+="%F{50}$repo_label%f"
    fi
  fi

  if [[ "$PWD" = $CODE_PATH* ]] && [[ -n "$ZSH_INIT_CWD" ]]
  then
    get-root
    if ! [[ "$CODE_ROOT" = "$ZSH_INIT_CWD" ]]
    then
      local curr_tld="${${PWD//$HOME/~}//\~\/$REL_CODE_PATH\//}"
      local init_tld="${${ZSH_INIT_CWD//$HOME/~}//\~\/$REL_CODE_PATH\//}"
      rprompt_warning="in ${curr_tld} instead of ${init_tld}"
    fi
  fi

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
    RPROMPT="$diff_char$RPROMPT%F{8}<%F{63}$([[ $vcs_info_msg_1_ = $main_branch ]] || echo ' ')$vcs_info_msg_1_%F{8}>%f"
  fi
  if [ $rprompt_warning ]; then
    RPROMPT+="%F{8}<%F{red}$rprompt_warning%F{8}>%f"
  fi

  if [ $RPROMPT ]; then RPROMPT=" $RPROMPT"; fi
}

ASCII_MESSAGES_HYDRATION="\n  ______                     _               _                             _ \n / _____) _                 | |             | |              _            | |\n( (____ _| |_ _____ _   _   | |__  _   _  __| | ____ _____ _| |_ _____  __| |\n \\____ (_   _|____ | | | |  |  _ \\| | | |/ _  |/ ___|____ (_   _) ___ |/ _  |\n _____) )| |_/ ___ | |_| |  | | | | |_| ( (_| | |   / ___ | | |_| ____( (_| |\n(______/  \\__)_____|\\__  |  |_| |_|\\__  |\\____|_|   \\_____|  \\__)_____)\\____|\n                   (____/         (____/                                     \n\n"
LAST_HYDRATION_REMINDER=$SECONDS

function precmd_hydration {
  local current_time=$SECONDS
  if (( current_time - LAST_HYDRATION_REMINDER >= 3600 )); then
    echo "$ASCII_MESSAGES_HYDRATION"
    LAST_HYDRATION_REMINDER=$current_time
  fi
}

precmd_functions+=(precmd_cmd_timer precmd_vcs_info precmd_hydration)
preexec_functions+=(preexec_cmd_info preexec_cmd_timer)

# endregion #

# region installs #

export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"

if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# endregion #

# region editors #

export PATH="$HOME/.local/bin:$PATH"

function ws {
  local code_idx=$(_part_code_base_idx)
  if [ $# -eq 0 ]; then
    local file_path=(${(s:/:)PWD})
    local src_folder=(${file_path[$code_idx]})
    webstorm "$CODE_PATH/$src_folder"
  elif [ $@ -a -d "$CODE_PATH/$*" ]; then
    webstorm "$CODE_PATH/$*"
  else
    echo "No valid folder passed"
  fi
}

function cs {
  local code_idx=$(_part_code_base_idx)
  if [ $# -eq 0 ]; then
    local file_path=(${(s:/:)PWD})
    local src_folder=(${file_path[$code_idx]})
    cursor "$CODE_PATH/$src_folder"
  elif [ $@ -a -d "$CODE_PATH/$*" ]; then
    cursor "$CODE_PATH/$*"
  else
    echo "No valid folder passed"
  fi
}

function webs {
  get_code_context "$@"
  ws "$CODE_CONTEXT"
}

function cows {
  get_code_context "$@"
  cdc "$CODE_CONTEXT"
  ws
}

function setup {
  co Ref
  ws
  remap "$@"
}

# endregion #
