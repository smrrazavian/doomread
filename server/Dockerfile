# The Doomread server, AOT-compiled and run from scratch (ADR-0007).
# Built from the repo root, because it needs packages/core:
#   docker build -f server/Dockerfile .
# dart:3.13.5, pinned by digest (the Dart that Flutter 3.47.7 ships).
FROM dart@sha256:8604cbd137b6d67c24f49b916f2aa9b67d71b539576e0178bf161d831c9e344f AS build

ARG HTTPS_PROXY HTTP_PROXY NO_PROXY

WORKDIR /src
COPY pubspec.yaml pubspec.lock ./
COPY packages/core packages/core
COPY server server
# ponytail: the app is a workspace member that needs Flutter, which this image
# lacks, so it is dropped from the workspace here. The lockfile still pins
# every package the server shares with it.
RUN sed -i '/^  - app$/d' pubspec.yaml && dart pub get
RUN dart compile exe server/bin/server.dart -o /server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
