# syntax=docker/dockerfile:latest
FROM debian:stable-slim AS base
ARG STRACE_VER=6.11

WORKDIR /src
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked <<eof
	DEBIAN_FRONTEND=non-interactive apt-get update
	DEBIAN_FRONTEND=non-interactive apt-get install -y --no-install-recommends build-essential wget ca-certificates git
eof

FROM base AS build

WORKDIR /src
RUN <<eof
	set -ex
	#wget -q -O - https://github.com/strace/strace/releases/download/v${STRACE_VER}/strace-${STRACE_VER}.tar.xz | \
	#	tar xJf - --strip-components=1
	git clone --single-branch --branch v${STRACE_VER} https://github.com/strace/strace.git .
	ls -lah .
	sh -c ./bootstrap
	mkdir build
	cd build
	../configure --prefix="/src/install" CFLAGS="-pthread" LDFLAGS="-static"
	make
	make install-strip
eof

FROM scratch AS release
COPY --from=build /src/install/strace /
