#!/bin/sh
# Applies the optional iOS features to the Xcode project, from dart_define.json.
#
# The counterpart of the optional manifest fragments on Android, and it exists
# for the same reason: a capability a brand does not use must be absent from
# what ships, not merely switched off. An entitlement the app declares forces
# every provisioning profile to carry the matching capability, so leaving it in
# turns an unused feature into a build that cannot be signed:
#
#   Provisioning profile ... doesn't include the Associated Domains capability
#
# Two features are optional in that sense today:
#
#   deep links   - com.apple.developer.associated-domains, kept only when
#                  WEBTRIT_APP_LINK_DOMAIN names a domain
#   screen share - the broadcast upload extension ios/ScreenShare and the app
#                  group Runner shares with it, kept only when
#                  WEBTRIT_IOS_SCREEN_SHARE_APP_GROUP names an app group
#
# The switch is the same key the Dart code and android/app/build.gradle read,
# so one file decides the feature on both platforms.
#
# Not ios/Flutter/Environment.xcconfig, deliberately: it is gitignored and
# written by the Xcode scheme's pre-action at archive time, so it does not
# exist yet here and would fall back to the hard-coded default domain.
#
# Nothing installed: `plutil` reads JSON as happily as it reads a plist, and
# `PlistBuddy` edits the entitlements. That is the point of it living here
# rather than in a pipeline that had to install a gem to do the same edit.
#
# PlistBuddy for the plist, not plutil: plutil reads a key path separated by
# dots, and every entitlement key is full of them - it looked for
# `com` -> `apple` -> `developer` and reported the entitlement absent while it
# was sitting there.

set -eu

DART_DEFINE=${1:-dart_define.json}
ENTITLEMENTS=ios/Runner/Runner.entitlements
INFO_PLIST=ios/Runner/Info.plist
PROJECT=ios/Runner.xcodeproj/project.pbxproj
ASSOCIATED_DOMAINS=com.apple.developer.associated-domains
APP_GROUPS=com.apple.security.application-groups
PLIST_BUDDY=/usr/libexec/PlistBuddy

if [ ! -f "$DART_DEFINE" ]; then
  echo "No ${DART_DEFINE} in $(pwd) - run this after the configuration step that writes it." >&2
  exit 1
fi

# The string value of a key in the define file; empty when absent, empty or null.
define_value() {
  if value=$(plutil -extract "$1" raw -o - "$DART_DEFINE" 2>/dev/null); then
    value=$(printf '%s' "$value" | tr -d '[:space:]')
  else
    value=
  fi
  [ "$value" = null ] && value=
  printf '%s' "$value"
}

deep_links() {

# Absent, empty and null mean the same thing here: no domain, no deep links.
#
# What plutil prints counts only when it succeeded. On the macOS 15 runner a
# failed extract - no such key - writes its error to stdout, and that text was
# taken for a domain: the entitlement stayed and the archive could not be signed
# with a profile that has no Associated Domains. A value that is not a
# host name is no domain either, whatever printed it.
if domain=$(plutil -extract WEBTRIT_APP_LINK_DOMAIN raw -o - "$DART_DEFINE" 2>/dev/null); then
  domain=$(printf '%s' "$domain" | tr -d '[:space:]')
else
  domain=
fi
case "$domain" in
  null) domain= ;;
  *[!A-Za-z0-9.-]*)
    echo "WEBTRIT_APP_LINK_DOMAIN is not a host name (${domain}) - treating it as no domain" >&2
    domain=
    ;;
esac

if [ -n "$domain" ]; then
  echo "Deep links: enabled (${domain}) - keeping ${ASSOCIATED_DOMAINS}"
  return 0
fi

if [ ! -f "$ENTITLEMENTS" ]; then
  echo "Deep links: disabled - no ${ENTITLEMENTS} to strip"
  return 0
fi

if "$PLIST_BUDDY" -c "Print :${ASSOCIATED_DOMAINS}" "$ENTITLEMENTS" >/dev/null 2>&1; then
  "$PLIST_BUDDY" -c "Delete :${ASSOCIATED_DOMAINS}" "$ENTITLEMENTS"
  echo "Deep links: disabled - removed ${ASSOCIATED_DOMAINS} from ${ENTITLEMENTS}"
else
  echo "Deep links: disabled - ${ASSOCIATED_DOMAINS} already absent"
fi
}

# The screen share extension needs an App ID of its own (<app id>.ScreenShare),
# the app group on both App IDs and a provisioning profile for each. A brand
# that has not set them up must still sign, so with no app group named this
# takes out of the project:
#
#   - Runner's dependency on the extension and the extension in Runner's
#     "Embed Foundation Extensions" phase: it is neither built nor signed;
#   - the app group entitlement of Runner;
#   - RTCAppGroupIdentifier and RTCScreenSharingExtension from Runner's
#     Info.plist - which is also how the app sees at run time that it cannot
#     share the screen (ScreenBroadcastChannel), so the share stays hidden.
#
# The project is committed with the extension in; nothing here puts it back, so
# a checkout it was taken out of is restored with git before it is turned on.
# The value itself reaches the project as a build setting, through the Runner
# scheme's pre-action like every WEBTRIT_* define.
screen_share() {
group=$(define_value WEBTRIT_IOS_SCREEN_SHARE_APP_GROUP)
case "$group" in
  '') ;;
  group.*[!A-Za-z0-9.-]* | group.)
    echo "WEBTRIT_IOS_SCREEN_SHARE_APP_GROUP is not an app group (${group}) - treating it as none" >&2
    group=
    ;;
  group.*) ;;
  *)
    echo "WEBTRIT_IOS_SCREEN_SHARE_APP_GROUP does not start with group. (${group}) - treating it as none" >&2
    group=
    ;;
esac

embed_line='/\* ScreenShare.appex in Embed Foundation Extensions \*/,$'
dependency=$(awk '/\/\* PBXTargetDependency \*\/ = \{/ { id = $1 } /target = [0-9A-F]+ \/\* ScreenShare \*\/;/ { if (id != "") { print id; exit } }' "$PROJECT")
wired=no
if [ -n "$dependency" ] && grep -q "^[[:space:]]*${dependency} /\* PBXTargetDependency \*/,$" "$PROJECT"; then
  wired=yes
fi

if [ -n "$group" ]; then
  if [ "$wired" = no ] || ! grep -q "$embed_line" "$PROJECT"; then
    echo "Screen share: ${group} is set, but the extension was taken out of ${PROJECT} - restore ios/ with git first" >&2
    exit 1
  fi
  echo "Screen share: enabled (${group}) - keeping the extension"
  return 0
fi

if [ "$wired" = yes ]; then
  sed -i.bak "/^[[:space:]]*${dependency} \/\* PBXTargetDependency \*\/,\$/d" "$PROJECT"
fi
sed -i.bak "\#${embed_line}#d" "$PROJECT"
rm -f "${PROJECT}.bak"
"$PLIST_BUDDY" -c "Delete :${APP_GROUPS}" "$ENTITLEMENTS" >/dev/null 2>&1 || true
"$PLIST_BUDDY" -c "Delete :RTCAppGroupIdentifier" "$INFO_PLIST" >/dev/null 2>&1 || true
"$PLIST_BUDDY" -c "Delete :RTCScreenSharingExtension" "$INFO_PLIST" >/dev/null 2>&1 || true
# Xcode never takes out of an app what a copy phase no longer copies: an earlier
# build with the extension would leave it in the app, unsigned or with an App ID
# the profile lacks.
rm -rf build/ios/*/Runner.app/PlugIns/ScreenShare.appex
echo "Screen share: disabled - the extension, ${APP_GROUPS} and the RTC* keys are out"
}

deep_links
screen_share
