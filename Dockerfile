FROM ldc-musl AS build

LABEL maintainer "Tomoya Tanjo <ttanjo@gmail.com>"

COPY zatsu_cwl_generator.d /
RUN ldc2 -mtriple=x86_64-alpine-linux-musl -static -O -release zatsu_cwl_generator.d

FROM busybox:1.31.0-musl

COPY --from=build /zatsu_cwl_generator /usr/bin/zatsu-cwl-generator

ENTRYPOINT ["zatsu-cwl-generator"]
