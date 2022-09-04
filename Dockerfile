FROM alpine:3.16 as DEV

RUN mkdir -p /workdir
WORKDIR /workdir
RUN apk add --no-cache ldc gcc musl-dev llvm-libunwind-static

COPY zatsu-cwl-generator.d /workdir

RUN ldc2 -static -O -release zatsu-cwl-generator.d


FROM busybox:1.34.0-musl

LABEL maintainer "Tomoya Tanjo <ttanjo@gmail.com>"

COPY --from=DEV /workdir/zatsu-cwl-generator /usr/bin/zatsu-cwl-generator

ENTRYPOINT ["zatsu-cwl-generator"]
