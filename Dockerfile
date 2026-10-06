# Unit test images for the Gerrit checks (WT-2002), one stage per check; see
# .jenkins/README.md. Build context: the repository root, e.g.
#   docker build --target phone-test -t mobile-app-phone-test . && docker run --rm mobile-app-phone-test

FROM ubuntu:noble-20260917 AS flutter
# Matches phone/.fvmrc. sha256: releases_linux.json on storage.googleapis.com/flutter_infra_release.
ARG FLUTTER_VERSION=3.47.1
ARG FLUTTER_SHA256=a1d8166c0309267cb7dc99f1424eecf08b86946ad3b50723c6f59945964aea45
ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/flutter.tar.xz \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory '*' \
    && flutter config --no-analytics --no-cli-animations \
    && flutter precache --universal --no-android --no-ios --no-web

# The dependency manifests only (pubspecs, Gradle files), so each stage's `pub get` /
# Gradle download below is cached until a manifest changes. `pub get` also checks that
# each Android plugin's main class exists, hence android/src/main.
FROM flutter AS manifests
COPY phone /src/phone
COPY callkeep /src/callkeep
COPY tools /src/tools
COPY analysis /src/analysis
RUN find /src -type f ! -name pubspec.yaml ! -name pubspec.lock ! -path '*/android/src/main/*' \
        ! -name '*.gradle' ! -name '*.properties' ! -name gradlew ! -path '*/gradle/wrapper/*' -delete

# phone/ and every phone/packages/** package with a test/ directory. phone/ depends on
# ../callkeep by path. integration_test/ and patrol_test/ need a device and are not run.
FROM flutter AS phone-test
WORKDIR /src/phone
COPY --from=manifests /src/phone /src/phone
COPY --from=manifests /src/callkeep /src/callkeep
RUN flutter pub get \
    && for p in packages/signaling_service/*/; do (cd "$p" && flutter pub get) || exit 1; done
COPY phone /src/phone
COPY callkeep /src/callkeep
# flutter test compiles every test file on its own, with the whole app behind it; for the
# ~370 files of phone/test that compilation is most of the run (~16 min). test/all_test.dart,
# generated here from whatever test files there are, imports them all as groups, so they
# compile once (~3 min). They share one process, so a test that changes global state
# (platform channel mocks, Logger.root.level, the app lifecycle state) has to restore it
# in its own tearDown.
RUN cd test && { \
      echo "import 'package:flutter_test/flutter_test.dart';"; \
      find . -name '*_test.dart' ! -name all_test.dart | sort | awk '{printf "import \x27%s\x27 as t%d;\n", $0, NR}'; \
      echo 'void main() {'; \
      find . -name '*_test.dart' ! -name all_test.dart | sort | awk '{printf "  group(\x27%s\x27, t%d.main);\n", $0, NR}'; \
      echo '}'; \
    } > all_test.dart
CMD rc=0; echo "=== ."; flutter test --no-pub --reporter=failures-only test/all_test.dart || rc=1; \
    for d in $(find packages -name pubspec.yaml -not -path '*/example/*' -printf '%h\n' | sort); do \
      [ -d "$d/test" ] || continue; echo "=== $d"; \
      (cd "$d" && flutter test --no-pub --concurrency=$(nproc) --reporter=failures-only) || rc=1; \
    done; exit $rc

# Dart side of every callkeep/webtrit_callkeep* package with a test/ directory. Native
# iOS/macOS/Windows tests need those hosts; the Android JVM tests are callkeep-android-test.
FROM flutter AS callkeep-test
WORKDIR /src/callkeep
COPY --from=manifests /src/callkeep /src/callkeep
RUN for p in webtrit_callkeep*/; do (cd "$p" && flutter pub get) || exit 1; done
COPY callkeep /src/callkeep
CMD rc=0; for d in webtrit_callkeep*; do \
      [ -d "$d/test" ] || continue; echo "=== $d"; \
      (cd "$d" && flutter test --no-pub --concurrency=$(nproc) --reporter=failures-only) || rc=1; \
    done; exit $rc

# Robolectric JVM tests of callkeep/webtrit_callkeep_android, as
# callkeep/.github/workflows/android-unit-tests.yml runs them. The module compiles against
# the Flutter engine jar: Flutter's Android artifacts, JDK 17 (test toolchain), JDK 21
# (Gradle daemon JVM) and the Android SDK.
FROM flutter AS callkeep-android-test
ARG ANDROID_CMDLINE_TOOLS=https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip
ENV ANDROID_HOME=/opt/android-sdk \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
    GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.workers.max=4"
RUN apt-get update \
    && apt-get install -y --no-install-recommends openjdk-17-jdk-headless openjdk-21-jdk-headless \
    && rm -rf /var/lib/apt/lists/* \
    && flutter precache --android \
    && mkdir -p "$ANDROID_HOME/cmdline-tools" \
    && curl -fsSL -o /tmp/cmdline-tools.zip "$ANDROID_CMDLINE_TOOLS" \
    && unzip -q /tmp/cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools" \
    && mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" \
    && rm /tmp/cmdline-tools.zip \
    && yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses > /dev/null \
    && "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --install "platforms;android-36" "build-tools;35.0.0" > /dev/null
WORKDIR /src/callkeep/webtrit_callkeep_android/android
COPY --from=manifests /src/callkeep/webtrit_callkeep_android/android .
RUN echo "flutter.sdk=/opt/flutter" > local.properties \
    && ./gradlew dependencies --configuration debugUnitTestRuntimeClasspath > /dev/null \
    && ./gradlew :lint:dependencies > /dev/null
COPY callkeep/webtrit_callkeep_android/android .
RUN echo "flutter.sdk=/opt/flutter" > local.properties
CMD ["./gradlew", "testDebugUnitTest"]

# tools/, with `dart test` as tools/ CI and lefthook run it. tools/ depends on ../analysis
# and ../phone/packages/theme_schema by path.
FROM flutter AS tools-test
WORKDIR /src/tools
COPY --from=manifests /src/tools /src/tools
COPY --from=manifests /src/analysis /src/analysis
COPY --from=manifests /src/phone/packages/theme_schema /src/phone/packages/theme_schema
RUN dart pub get
COPY tools /src/tools
COPY analysis /src/analysis
COPY phone/packages/theme_schema /src/phone/packages/theme_schema
CMD ["dart", "test", "--concurrency=4", "--reporter=failures-only"]
