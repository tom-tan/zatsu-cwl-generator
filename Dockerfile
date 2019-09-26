FROM busybox:1.31.0-musl

LABEL maintainer "Tomoya Tanjo <ttanjo@gmail.com>"

COPY zatsu-cwl-generator /usr/bin/zatsu-cwl-generator

ENTRYPOINT ["zatsu-cwl-generator"]
