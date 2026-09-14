#!/bin/sh
# Regenerates the pigeon code for one platform package and strips the trailing whitespace the
# Kotlin and Objective-C generators leave behind, which the repository's whitespace check
# refuses. Run from the package directory (webtrit_callkeep_android, webtrit_callkeep_ios) or
# pass that directory as the argument. Generated files are never edited by hand.
set -eu
cd "${1:-.}"
input=pigeons/callkeep.messages.dart
if [ ! -f "$input" ]; then
  echo "pigeon.sh: no $input in $(pwd); run it from a platform package or pass one" >&2
  exit 1
fi
dart run pigeon --input "$input"
# every output path named in the @ConfigurePigeon block of the input
grep -oE "(dartOut|kotlinOut|objcHeaderOut|objcSourceOut|swiftOut|dartTestOut): *'[^']+'" "$input" \
  | sed -E "s/^[a-zA-Z]+: *'([^']+)'/\1/" \
  | while read -r out; do
      [ -f "$out" ] && perl -pi -e 's/[ \t]+$//' "$out"
    done
