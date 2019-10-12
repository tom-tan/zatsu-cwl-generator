FROM alpine:3.10 AS build

LABEL maintainer "Tomoya Tanjo <ttanjo@gmail.com>"

RUN apk add --no-cache llvm5-libs g++ binutils-gold clang lld \
                       llvm8-libs llvm8-static llvm8-dev \
                       cmake ninja zlib-dev curl-dev bash git

# Install ldc2
ARG ldc_ver=1.17.0

RUN wget -O ldc-bin.tar.xz https://github.com/ldc-developers/ldc/releases/download/v1.13.0/ldc2-1.13.0-alpine-linux-x86_64.tar.xz
RUN tar xf ldc-bin.tar.xz
RUN wget -O ldc-src.tar.gz https://github.com/ldc-developers/ldc/releases/download/v${ldc_ver}/ldc-${ldc_ver}-src.tar.gz
RUN tar xf ldc-src.tar.gz
RUN mkdir ldc-${ldc_ver}-src/build
WORKDIR ldc-${ldc_ver}-src/build
RUN cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release \
          -DD_COMPILER=/ldc2-1.13.0-alpine-linux-x86_64/bin/ldmd2 \
          -DCMAKE_INSTALL_PREFIX=/dlang/ldc2-${ldc_ver}
RUN ninja -j4 && ninja install
WORKDIR /dlang
RUN ln -s ldc2-${ldc_ver} dc
RUN cat /dlang/dc/etc/ldc2.conf | \
    sed -e 's/\("-defaultlib=phobos2-ldc,druntime-ldc",\)/\1 "-gcc=clang", "-linker=lld"/' | \
    sed -e "s|/dlang/ldc2-${ldc_ver}|%%ldcbinarypath%%/..|g" > ldc2.conf && \
    mv ldc2.conf /dlang/dc/etc

# The following is to build msgpack-d used by dcd
RUN sed -e 's/uint \+iov_len/size_t iov_len/' /dlang/dc/include/d/core/sys/posix/sys/uio.d > uio.d
RUN mv uio.d /dlang/dc/include/d/core/sys/posix/sys/uio.d

ENV PATH=/dlang/dc/bin:$PATH

WORKDIR /

# Install dub
ARG dub_ver=1.17.0

RUN wget -O dub.tar.gz https://github.com/dlang/dub/archive/v${dub_ver}.tar.gz
RUN tar xf dub.tar.gz
WORKDIR dub-${dub_ver}
RUN ./build.sh
RUN strip bin/dub
RUN mv bin/dub /dlang/dc/bin

WORKDIR /

# Install rdmd
ARG rdmd_ver=2.088.0

RUN wget -O tools.tar.gz https://github.com/dlang/tools/archive/v${rdmd_ver}.tar.gz
RUN tar xf tools.tar.gz
WORKDIR tools-${rdmd_ver}
RUN dub build -b release :rdmd
RUN strip dtools_rdmd
RUN mv dtools_rdmd /dlang/dc/bin/rdmd

WORKDIR /

RUN mkdir -p /dlang/.code-d/bin

# Install code-d
# It cannot be built with 0.4.1 (#65)
#ARG served_ver=0.4.1
#RUN wget -O serve-d.tar.gz https://github.com/Pure-D/serve-d/archive/v${served_ver}.tar.gz
#RUN tar xf serve-d.tar.gz
RUN wget -O serve-d.zip https://github.com/Pure-D/serve-d/archive/master.zip
RUN unzip serve-d.zip
WORKDIR serve-d-master
RUN dub build -b release
RUN strip serve-d
RUN mv serve-d /dlang/.code-d/bin

WORKDIR /

# Install dcd
ARG dcd_ver=0.12.0
RUN git clone https://github.com/dlang-community/DCD.git -b v${dcd_ver}
WORKDIR DCD
RUN dub build -b release -c client
RUN dub build -b release -c server
RUN strip bin/dcd-client bin/dcd-server
RUN mv bin/dcd-* /dlang/.code-d/bin


FROM alpine:3.10

ENV PATH=/dlang/dc/bin:$PATH

COPY --from=build /dlang /dlang

RUN mv /dlang/.code-d /root
RUN apk add --no-cache clang lld tzdata musl-dev gcc curl-dev
