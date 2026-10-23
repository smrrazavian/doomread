# Doomread dev and CI image: Flutter + Android SDK, all from official archives
# fetched by tool/fetch-sdk.sh and checksum-verified there and here.
# eclipse-temurin:21-jdk-noble, pinned by digest.
FROM eclipse-temurin@sha256:107215954359f1ab0be058a247d7c64ed6e69c71c1682d471d38ef751ec8e964

ARG UID=1000

# clang/lld/llvm: package:sqlite3's build hook compiles the vendored SQLite (ADR-0006).
# ponytail: apt packages follow the pinned Ubuntu base, not exact versions; pin them if builds drift.
RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl unzip xz-utils zip ca-certificates clang lld llvm \
 && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter ANDROID_HOME=/opt/android-sdk
ENV PATH=$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

# The base image already has a user with uid 1000 (ubuntu); reuse it as "dev".
RUN (getent passwd $UID >/dev/null && usermod -l dev -d /home/dev -m $(getent passwd $UID | cut -d: -f1)) \
    || useradd -m -u $UID dev \
 && mkdir -p $FLUTTER_HOME $ANDROID_HOME && chown -R $UID $FLUTTER_HOME $ANDROID_HOME
USER dev

# Archives are bind-mounted, not copied: a COPY layer would keep them in the image
# forever (about 2.7 GB) even after they're deleted.
RUN --mount=type=bind,source=cache,target=/cache \
    echo "af7455f540df951184c7953fbe3cf884766e7541dacf8571f9f582db03dd6230  /cache/flutter.tar.xz" | sha256sum -c - \
 && tar -xJf /cache/flutter.tar.xz -C /opt

# Each SDK package: archive, sha1 and where it lands. Archives hold either one
# top-level folder or the package contents directly; both are handled.
RUN --mount=type=bind,source=cache,target=/cache set -e; cd /cache; \
    install() { echo "$2  $1" | sha1sum -c -; rm -rf /tmp/x; unzip -q "$1" -d /tmp/x; \
      n=$(ls /tmp/x | wc -l); mkdir -p "$(dirname "$ANDROID_HOME/$3")"; \
      if [ "$n" = 1 ] && [ -d "/tmp/x/$(ls /tmp/x)" ]; then mv "/tmp/x/$(ls /tmp/x)" "$ANDROID_HOME/$3"; \
      else mv /tmp/x "$ANDROID_HOME/$3"; fi; }; \
    install cmdline-tools.zip  5fdcc763663eefb86a5b8879697aa6088b041e70 cmdline-tools/latest; \
    install platform-tools.zip 477254aa5f903c15cf51001717bdf347fb6b53e0 platform-tools; \
    install platform-35.zip    0bb560a90a7a2cbd0dd8348224d518b638fe7949 platforms/android-35; \
    install platform-36.zip    2c1a80dd4d9f7d0e6dd336ec603d9b5c55a6f576 platforms/android-36; \
    install build-tools-36.zip b0b6376977657e8ad9b969bacf4093601da2c6fb build-tools/36.0.0; \
    install cmake-3.22.1.zip   fd0a48b4a758310df8c7aa51f59840ed48fe7ed8 cmake/3.22.1; \
    install ndk-r28c.zip       a7b54a5de87fecd125a17d54f73c446199e72a64 ndk/28.2.13676358

# Accepting the Android SDK licences was approved by the project owner.
RUN yes | sdkmanager --licenses >/dev/null && adb version

RUN flutter config --no-analytics --no-cli-animations \
 && dart --disable-analytics \
 && flutter precache --android \
 && flutter --version

# Owned by dev, so a fresh home volume (as in CI) stays writable when tool/dev
# mounts the Gradle init scripts inside it.
RUN mkdir -p /home/dev/.gradle

WORKDIR /work
