#!/usr/bin/env bash
# Pushes the commits above the target branch to Gerrit for review, in the form
# described in docs/gerrit_push.md: the pre-push gate runs on its own, the push
# happens only if it passed, and the server is then asked what landed.
#
#   scripts/gerrit-push.sh [--dry-run] [--wip | --ready | --no-mark]
#                          [--target <branch>] [--topic <topic>]
#
#   --dry-run   print the commits, target and topic, check them, push nothing
#   --wip       mark the changes work in progress (the default for a new chain)
#   --ready     lift work in progress from them
#   --no-mark   push without either mark: an existing change keeps the mark
#               it has
#   --target    the branch the changes are for (default: master)
#   --topic     the Gerrit topic (default: the ticket id the branch name starts
#               with, e.g. WT-1234 for WT-1234-fix-the-thing)
#
# A push with %wip puts work in progress back on every change it updates, even
# one whose owner has already lifted it. So when a change of the chain is
# already in review without the mark, the default refuses, and one of --wip,
# --ready or --no-mark has to be named.
#
# Each commit needs exactly one Change-Id; a commit made with the hooks turned
# off has none and Gerrit refuses it, so that is checked before the gate runs.

set -uo pipefail

mode=""
dry_run=0
target=master
topic=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) dry_run=1 ;;
    --wip) mode=wip ;;
    --ready) mode=ready ;;
    --no-mark) mode=none ;;
    --target) target="$2"; shift ;;
    --topic) topic="$2"; shift ;;
    -h|--help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "gerrit-push: unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

root=$(git rev-parse --show-toplevel) || exit 2
cd "$root" || exit 2

# The gate checks the working tree, so it proves the commits only when the tree
# holds nothing else - an untracked file a commit forgot would make it pass.
if [[ -n $(git status --porcelain) ]]; then
  echo "gerrit-push: uncommitted or untracked files; commit, stash or remove them first" >&2
  exit 2
fi

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ -z "$topic" ]]; then
  topic=$(grep -oE '^[A-Z][A-Z0-9]*-[0-9]+' <<<"$branch")
  if [[ -z "$topic" ]]; then
    echo "gerrit-push: branch '$branch' does not start with a ticket id; pass --topic" >&2
    exit 2
  fi
fi

git fetch -q origin "$target" || exit 2
base="origin/$target"
commits=$(git rev-list --reverse "$base..HEAD")
if [[ -z "$commits" ]]; then
  echo "gerrit-push: nothing above $base" >&2
  exit 2
fi

# ssh://[user@]host[:port]/project(.git)
url=$(git remote get-url origin)
if [[ ! "$url" =~ ^ssh://([^/]+)/(.+)$ ]]; then
  echo "gerrit-push: origin is not an ssh:// Gerrit remote: $url" >&2
  exit 2
fi
hostport=${BASH_REMATCH[1]}
project=${BASH_REMATCH[2]%.git}
ssh_args=("${hostport%%:*}")
[[ "$hostport" == *:* ]] && ssh_args=(-p "${hostport##*:}" "${ssh_args[@]}")
gerrit() { ssh -o ConnectTimeout=20 "${ssh_args[@]}" gerrit "$@"; }
# The current patchsets of the chain's changes on this project and target, one JSON
# line per change, in one query.
server_state() {
  local q="" id
  for id in "${change_ids[@]}"; do q+="${q:+ OR }change:$id"; done
  gerrit query --format=JSON --current-patch-set "project:$project" "branch:$target" "($q)" \
    2>/dev/null | grep '"number"'
}
change_line() { grep -F "\"id\":\"$1\"" <<<"$state" | head -1; }
json_field() { grep -oE "\"$1\":(\"[^\"]*\"|[0-9a-z]+)" <<<"$2" | head -1 | cut -d: -f2 | tr -d '"'; }

echo "Target: refs/for/$target   Topic: $topic"
echo "Commits:"
missing=0
change_ids=()
for c in $commits; do
  ids=$(git log -1 --format='%(trailers:key=Change-Id,valueonly)' "$c" | sed '/^$/d')
  n=$(grep -c . <<<"$ids")
  printf '  %s %s\n' "$(git rev-parse --short "$c")" "$(git log -1 --format=%s "$c")"
  if [[ "$n" -ne 1 ]]; then
    echo "    has $n Change-Id lines, needs exactly one" >&2
    missing=1
  fi
  change_ids+=("$ids")
done
[[ "$missing" -eq 0 ]] || exit 1

if [[ -z "$mode" ]]; then
  # Changes of the chain already in review without the WIP mark.
  state=$(server_state)
  ready_in_review=()
  for id in "${change_ids[@]}"; do
    line=$(change_line "$id")
    [[ -n "$line" ]] || continue
    [[ "$(json_field wip "$line")" == true ]] && continue
    [[ "$(json_field status "$line")" == NEW ]] && ready_in_review+=("$(json_field number "$line")")
  done
  if [[ ${#ready_in_review[@]} -gt 0 ]]; then
    echo "gerrit-push: already in review without the WIP mark: ${ready_in_review[*]}" >&2
    echo "  --wip would put the mark back on them; name --wip, --ready or --no-mark" >&2
    exit 2
  fi
  mode=wip
fi
case "$mode" in
  wip) opts="%wip,topic=$topic" ;;
  ready) opts="%ready,topic=$topic" ;;
  none) opts="%topic=$topic" ;;
esac
echo "Push: HEAD:refs/for/$target$opts"
[[ "$dry_run" -eq 1 ]] && exit 0

# A topic branch has no push destination, so lefthook would pick the files of the
# push itself and can pick the wrong ones. Hand it the files the commits change,
# NUL-separated: with one path per line it reads only the first.
log=$(mktemp -t gerrit-push-gate.XXXXXX)
echo "Gate: lefthook run pre-push on the files of $base..HEAD (log: $log)"
git diff -z --name-only "$base...HEAD" |
  env -u GIT_DIR lefthook run pre-push --files-from-stdin --no-tty >"$log" 2>&1
gate=${PIPESTATUS[1]}
sed 's/\x1b\[[0-9;]*m//g' "$log" | sed -n '/summary:/,$p'
if [[ "$gate" -ne 0 ]]; then
  echo "gerrit-push: the gate failed ($gate); nothing pushed. See $log" >&2
  exit 1
fi

push_log=$(mktemp -t gerrit-push.XXXXXX)
git push --no-verify origin "HEAD:refs/for/$target$opts" >"$push_log" 2>&1
push=$?
cat "$push_log"
# "no new changes": every commit is already on the server byte for byte. Not an
# error, and the marks then stay as they are - check the server below.
if [[ "$push" -ne 0 ]] && ! grep -q 'no new changes' "$push_log"; then
  echo "gerrit-push: git push exited $push" >&2
  exit 1
fi

# The push output is not the answer; the server is.
status=0
state=$(server_state)
echo "On the server:"
i=0
for c in $commits; do
  id=${change_ids[$i]}
  i=$((i + 1))
  line=$(change_line "$id")
  rev=$(json_field revision "$line")
  num=$(json_field number "$line")
  wip=no
  [[ "$(json_field wip "$line")" == true ]] && wip=yes
  if [[ "$rev" == "$c" ]]; then
    printf '  %s wip=%s %s\n' "$num" "$wip" "$(git log -1 --format=%s "$c")"
  else
    printf '  MISMATCH %s: server has %s, local is %s\n' "${num:-?}" "${rev:-nothing}" "$c" >&2
    status=1
  fi
done
exit "$status"
