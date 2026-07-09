# Work profile: Sprinklr/spaceweb helpers and repo listing

alias yb="yarn build"
alias ybt="yarn build --scope=spaceweb-themes"
alias yarn-ddos="yarn docs:dev:only-spaceweb"

function git-ticket {
  get-root
  local project_name=$(jq '.name' "$CODE_ROOT/package.json" -r)
  case $project_name in
    spaceweb|sprinklr-app-client)
      local ticket_name="$(git rev-parse --abbrev-ref @ | ggrep -Eo '^\w+/\w+-[0-9]+' | gsed 's!.*/!!;s/.*/\U&/;/./!d')"
      if [ "$ticket_name" != 'EDGE-1230' ]; then echo "$ticket_name"; fi
    ;;
    *)
  esac
}

function git-prefix {
  get-root
  local git_ticket="$(git-ticket)"
  local project_name=$(jq '.name' "$CODE_ROOT/package.json" -r)

  case $project_name in
    spaceweb)
      echo "[spaceweb]$([ -n "$git_ticket" ] && echo "[$git_ticket]") "
    ;;
    *)
      [ -n "$git_ticket" ] && echo "[$git_ticket] "
    ;;
  esac
}

alias htw="yw spr-main-web"

function hts {
  get-root
  cd "$CODE_ROOT/packages/spaceweb"
}

function wheeee {
  get-root
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
      if [[ $force_wheeee -eq 1 ]]
      then
        yarn prenext-dev
        yarn prebuild
      fi
      yarn next-dev:only
    ;;
    *)
      echo "Uhh no idea how to handle $project_name sorry"
    ;;
  esac
}
alias wheeeee='wheeee force'

function space-up {
  local space_version="$1"
  if [ -z "$space_version" ]
  then
    local space_version="^$(yarn npm info --json @sprinklrjs/spaceweb | jq -r .version)"
  fi
  yarn up @sprinklrjs/spaceweb@$space_version @sprinklrjs/spaceweb-themes@$space_version
  yarn workspace @sprinklrjs/public-assets postinstall
}

alias vrt-debug="npx ts-node --project internals/vrt/tsconfig.json internals/vrt/scripts/preVrt.ts && rm -rf packages/docs/public/resources/vrt-snapshots/[^.]* || : && cp -r .lostpixel/[^.]* packages/docs/public/resources/vrt-snapshots && yarn ts-node internals/vrt/scripts/lostPixelJson.ts && yarn docs:dev:only-spaceweb"

export PATH="$HOME/.rd/bin:$PATH"

function part_find_code_repos {
  if [[ "$mac" == yes ]]; then
    find -E "$CODE_PATH" -maxdepth 1 -regex '.*/SU?[0-9]' "$@"
  else
    find "$CODE_PATH" -maxdepth 1 -regextype posix-extended -regex '.*/SU?[0-9]' "$@"
  fi
}

function branches {
  part_find_code_repos -exec sh -c 'cd {}; echo "$(basename $PWD)"#"$(git branch --show-current)"#"$(git log -n 1 "--date=format-local:%F %R" --pretty=format:%cd)"' \; | sort | gsed -r 's/^/%F{62}/;s/#/%F{8}:%F{50} /1;s/#/%F{8} (%F{7}/1;s/$/%F{8})%f/' | color
}

function repos {
  part_find_code_repos -exec sh -c 'cd {}; echo "$(basename $PWD)",#R"$(gsed -nr "/$(basename $PWD)/{s/\s*\|$//;s/^.*\|\s+//;p}" "$MAPPINGS_PATH")"#E,#B"$(curr_branch="$(git branch --show-current)"; echo "$curr_branch")",#D"$(git log -n 1 "--date=format-local:%F %R" --pretty=format:%cd)"' \; | sort | gsed -r 's/^SU./ %F{69} %F{62} \0/1;s/^S./ %F{75} %F{62} \0 /1;s/#RRef/%F{8}<%F{73}Ref/;s/#R/%F{8}<%F{50}/;s/#E/%F{8}>%f/;s/#Bmain/%F{8}%F{50}  %F{73}main/1;s/#B/%F{8}%F{50} %F{48}/1;s/#D/%F{8}(%F{7}/1;s/$/%F{8})%f/' | color | column -t -s ,
}
