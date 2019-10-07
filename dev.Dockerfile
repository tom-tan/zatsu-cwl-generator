FROM dlang2/ldc-ubuntu:1.17.0 AS build

LABEL maintainer "Tomoya Tanjo <ttanjo@gmail.com>"

ARG DEBCONF_NOWARNINGS=yes

RUN apt-get update
RUN apt-get install -y --no-install-recommends cmake musl-tools
RUN CC=musl-gcc ldc-build-runtime --dFlags="-w;-mtriple=x86_64-alpine-linux-musl" BUILD_SHARED_LIBS=OFF


FROM dlang2/ldc-ubuntu:1.17.0

ARG DEBCONF_NOWARNINGS=yes

RUN apt-get update
RUN apt-get install -y --no-install-recommends musl-tools

COPY --from=build /ldc-build-runtime.tmp/lib /dlang/dc/lib-musl
COPY ldc2-musl.conf /ldc2.conf.musl

RUN cat /ldc2.conf.musl >> /dlang/dc/etc/ldc2.conf && \
    rm /ldc2.conf.musl
