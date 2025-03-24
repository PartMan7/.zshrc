#!/bin/bash

# Many thanks to phil-blain on GitHub
# https://gist.github.com/phil-blain/2a1cf81a0030001d33158e44a35ceda6

# TODO Clean up this file a bit

set -Eeuo pipefail

trap 'rc=$?; echo "${0}: ERR trap at line ${LINENO} (return code: $rc)"; exit $rc' ERR

color_trace=$(git config --get-color color.trace 145)
color_none=$(tput sgr 0)

if [  ! -z "${PICKAXEDIFF_TRACE+x}" ]; then
  PS4='+${color_trace}+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }${color_none}'
  set -x
fi

echo_meta () {
echo "${color_meta}$1${color_none}"
}

path=$1
old_file=$2
old_hex=$3
old_mode=$4
new_file=$5
new_hex=$6
new_mode=$7

color_frag=$(git config --get-color color.diff.frag cyan)
color_func=$(git config --get-color color.diff.func '')
color_meta=$(git config --get-color color.diff.meta 'normal bold')
color_new=$(git config --get-color color.diff.new green)
color_old=$(git config --get-color color.diff.old red)

only_match_flag=""
if { grepdiff -h 2>&1 || : ; } | \grep -q -e '--only-match'; then
  only_match_flag="--only-match=mod"
fi
extended_flag=""
if [  ! -z "${PICKAXE_REGEX+x}" ]; then
  extended_flag="--extended-regexp"
fi

diff_output=$(git diff --no-color --no-ext-diff -p --src-prefix=a/ --dst-prefix=b/ $old_file $new_file || :)

filtered_diff=$( echo "$diff_output" | \
                grepdiff --output-matching=hunk ${only_match_flag} ${extended_flag} -- "$GREPDIFF_REGEX" | \
                \grep -v -e '^--- a/' -e '^+++ b/' | \
                \grep -v -e '^--- /dev/null' -e '^+++ /dev/null' | \
                \grep -v -e '^diff --git' -e '^index ' | \
                sed -e "s/\(@@ .* @@\)\(.*\)/${color_frag}\1${color_none}${color_func}\2${color_none}/" | \
                GREP_COLOR=7 GREP_COLORS="ms=7" \grep --color=always -E -e "$GREPDIFF_REGEX|$" | \
                sed -e $'s/\x1b\[m\x1b\[K/\x1b\[27m/g' -e $'s/\x1b\[K//g' | \
                sed -e "s/^\(+.*\)/${color_new}\1${color_none}/" | \
                sed -e "s/^\(-.*\)/${color_old}\1${color_none}/" )

a_path="a/$path"
b_path="b/$path"
old_path="$a_path"
new_path="$b_path"

echo_meta "diff --git $a_path $b_path"

# Detect new or removed files
NULL='/dev/null'
ZERO_OID="0000000"
same_mode="$old_mode"
if [ "$old_file" == "$NULL" ]; then
   old_path="$NULL"
   old_hex="$ZERO_OID"
   same_mode=''
   echo_meta "new file mode $new_mode"
elif [ "$new_file" == "$NULL" ]; then
   new_path="$NULL"
   new_hex="$ZERO_OID"
   same_mode=''
   echo_meta "deleted file mode $old_mode"
elif [ "$old_mode" != "$new_mode" ]; then
  echo_meta "old mode $old_mode"
  echo_meta "new mode $new_mode"
  same_mode=''
fi

echo_meta "index $old_hex..$new_hex $same_mode"
echo_meta "--- $old_path"
echo_meta "+++ $new_path"
echo "$filtered_diff"
