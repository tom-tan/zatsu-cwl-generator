FROM alpine:edge AS build

LABEL maintainer "Tomoya Tanjo <ttanjo@gmail.com>"

RUN apk --no-cache add -X http://dl-cdn.alpinelinux.org/alpine/edge/testing ldc ldc-static dtools-rdmd dub
RUN apk --no-cache add build-base git

# The following is to build msgpack-d used by dcd (fixed in the next release of ldc)
RUN sed -e 's/uint \+iov_len/size_t iov_len/' /usr/include/d/core/sys/posix/sys/uio.d > uio.d
RUN mv uio.d /usr/include/d/core/sys/posix/sys/uio.d

RUN mkdir -p /dlang/.code-d/bin

# Install code-d
ARG served_ver=0.5.1
RUN wget -O serve-d.tar.gz https://github.com/Pure-D/serve-d/archive/v${served_ver}.tar.gz
RUN tar xf serve-d.tar.gz
WORKDIR serve-d-${served_ver}
RUN dub build -b release
RUN strip serve-d
RUN mv serve-d /dlang/.code-d/bin

WORKDIR /

# Install dcd
ARG dcd_ver=0.11.1
RUN git clone https://github.com/dlang-community/DCD.git DCD-${dcd_ver} -b v${dcd_ver} --depth 1
# RUN wget -O dcd.tar.gz https://github.com/dlang-community/DCD/archive/v${dcd_ver}.tar.gz
# RUN tar xf dcd.tar.gz
WORKDIR DCD-${dcd_ver}
RUN dub build -b release -c client
RUN dub build -b release -c server
RUN strip bin/dcd-client bin/dcd-server
RUN mv bin/dcd-* /dlang/.code-d/bin


FROM alpine:edge

COPY --from=build /dlang/.code-d/bin /root/.code-d/bin

RUN apk --no-cache add -X http://dl-cdn.alpinelinux.org/alpine/edge/testing ldc ldc-static dtools-rdmd dub build-base
RUN apk --no-cache add build-base
