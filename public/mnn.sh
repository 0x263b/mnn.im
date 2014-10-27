#!/usr/bin/env bash

#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU Affero General Public License as
#published by the Free Software Foundation, either version 3 of the
#License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU Affero General Public License for more details.
#
#You should have received a copy of the GNU Affero General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

# requires curl, jq
# title and language taken from filename if not given
# pastes multiple files concatenated with ==> filename <==
# copies result to clipboard by default if possible, use -o to force stdout
# defaults to raw url for untitled & plaintext stdin, formatted if available, html otherwise. To force raw use -r, to force html set -l text
# the following are equivalent
# mnn.sh mnn.sh
# mnn.sh -l sh -t mnn.sh < mnn.sh

# this script is overly complicated for what it does
if   ! command -v curl 2&>/dev/null; then
	echo "requires curl: http://curl.haxx.se/" >&2
	exit
elif ! command -v jq 2&>/dev/null; then
	echo "requires jq: http://stedolan.github.io/jq/" >&2
	exit
fi

copy="cat" term="\n"
if [ -z "$SSH_TTY" ]; then
	if   command -v pbcopy 2&>/dev/null; then
		copy="pbcopy" term=""
	elif [ -n "$DISPLAY" ]; then
		if command -v xsel 2&>/dev/null; then
			copy="xsel" term=""
		elif command -v xclip 2&>/dev/null; then
			copy="xclip" term=""
		fi
	fi
fi

proto="https"
usage="usage: $(basename "$0") -t <title> -l <langid|list> -oruh files/stdin"
while getopts ":t:l:oruh" opt; do
	case $opt in
		t) title="$OPTARG";;
		l) lang="$OPTARG";;
		o) copy="cat" term="\n";;
		r) url="raw";;
		u) proto="http";;
		[\?:])
			echo "$usage" >&2
			exit;;
		h)
			echo \
"  mnn.im paster
  $usage

options:
  -t <title> set title for paste
  -l <lang>  set langid, or \"list\" for supported syntaxes
  -o         force printing to stdout instead of copying to clipboard
  -r         force raw url over html for files or when using -t or -l
  -u         don't use https for some reason
  files      if none are present input is taken from stdin

notes:
  Title and language will be inferred from filenames if not given.
  Multiple files will be concatenated with the string '==> filename <=='.
  URL is copied to clipboard by default if possible, use -o to force stdout.
  By default, the raw URL is returned only for untitled, plaintext, stdin input.
    To force raw on other kinds of input use -r. To force HTML on plain stdin, set -l text." >&2
			exit;;
	esac
done
shift $((OPTIND-1))

if [ "$lang" = "list" ]; then
	curl -ksS "$proto://mnn.im/api/langs" | jq -r '.lang_codes[]'
	exit
fi

[ -z "$lang"  ] && lang="${1##*.}"
if [ -z "$title" ]; then
	for arg; do
		title="$title, $(basename "$arg")"
	done
	title=${title:2}
fi

if [ -z "$1" ]; then
	set - /dev/stdin
	[ -z "$title" ] && [ -z "$lang" ] && url="raw"
fi

response="$(tail -n+1 "$@" | curl -ksS -dlang=$lang --data-urlencode title="$title" --data-urlencode paste@- "$proto://mnn.im/c")" || exit
if [ "$(echo "$response" | jq -r .status)" = "error" ]; then
	err="$(echo "$response" | jq -r .error_code)"
	printf "error from mnn.im: %d\n" $err >&2
	exit $err
fi
if [ -z "$url" ]; then #prefer formatted links
	link="$(echo "$response" | jq -r .paste.formatted)"; #jq -e would be good but it's newer than the latest release
	[ "$link" = "null" ] && url="link"
fi
[ -n "$url" ] && link="$(echo "$response" | jq -r .paste.$url)"
printf "$link$term" | "$copy"
