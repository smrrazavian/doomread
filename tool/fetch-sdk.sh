#!/usr/bin/env bash
# Download the SDK archives the dev image needs into tool/cache, resuming after drops.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p cache
fetch() { # url file sum-command checksum
  [ -f "cache/$2" ] && echo "$4  cache/$2" | $3 -c --status - && return
  rm -f "cache/$2"
  python3 fetch.py "$1" "cache/$2"
  echo "$4  cache/$2" | $3 -c -
}
fetch https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.7-stable.tar.xz \
  flutter.tar.xz sha256sum af7455f540df951184c7953fbe3cf884766e7541dacf8571f9f582db03dd6230
fetch https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip \
  cmdline-tools.zip sha1sum 5fdcc763663eefb86a5b8879697aa6088b041e70
fetch https://dl.google.com/android/repository/platform-tools_r37.0.1-linux.zip \
  platform-tools.zip sha1sum 477254aa5f903c15cf51001717bdf347fb6b53e0
fetch https://dl.google.com/android/repository/android-ndk-r28c-linux.zip \
  ndk-r28c.zip sha1sum a7b54a5de87fecd125a17d54f73c446199e72a64
fetch https://dl.google.com/android/repository/platform-35_r02.zip \
  platform-35.zip sha1sum 0bb560a90a7a2cbd0dd8348224d518b638fe7949
fetch https://dl.google.com/android/repository/platform-36_r02.zip \
  platform-36.zip sha1sum 2c1a80dd4d9f7d0e6dd336ec603d9b5c55a6f576
fetch https://dl.google.com/android/repository/build-tools_r36_linux.zip \
  build-tools-36.zip sha1sum b0b6376977657e8ad9b969bacf4093601da2c6fb
fetch https://dl.google.com/android/repository/cmake-3.22.1-linux.zip \
  cmake-3.22.1.zip sha1sum fd0a48b4a758310df8c7aa51f59840ed48fe7ed8
