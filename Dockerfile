# First stage build
FROM mjmckinnon/ubuntubuild:22.04 AS builder

ARG VERSION="v0.21.4"
ARG GITREPO="https://github.com/litecoin-project/litecoin.git"
ARG GITNAME="litecoin"
ARG COMPILEFLAGS="--disable-tests --disable-bench --enable-cxx --disable-shared --with-pic --disable-wallet --without-gui --without-miniupnpc"
ENV DEBIAN_FRONTEND="noninteractive"

# Get the source from Github
WORKDIR /root
RUN git clone ${GITREPO} --branch ${VERSION}
WORKDIR /root/${GITNAME}
# Configure and compile
RUN set -e \
    && echo "** compile **" \
    && ./autogen.sh \
    && ./configure CXXFLAG="-O2" LDFLAGS=-static-libstdc++ ${COMPILEFLAGS} \
    && make \
    && echo "** install and strip the binaries **" \
    && mkdir -p /dist-files \
    && make install DESTDIR=/dist-files \
    && strip /dist-files/usr/local/bin/* \
    && echo "** removing extra lib files **" \
    && find /dist-files -name "lib*.la" -delete \
    && find /dist-files -name "lib*.a" -delete \
    && cd .. && rm -rf ${GITREPO}

# Final stage build
FROM ubuntu:22.04
LABEL maintainer="Michael J. McKinnon <mjmckinnon@gmail.com>"

# Copy and set entrypoint script
COPY ./docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Copy the compiled files
COPY --from=builder /dist-files/ /

RUN \
    echo "** setup the litecoin user **" \
    && groupadd -g 1000 litecoin \
    && useradd -u 1000 -g litecoin litecoin

ENV DEBIAN_FRONTEND="noninteractive"
RUN set -e \
    && echo "** update and install dependencies ** " \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    gosu \
    libboost-filesystem1.74.0 \
    libboost-thread1.74.0 \
    libevent-2.1-7 \
    libevent-pthreads-2.1-7 \
    libfmt8 \
    libboost-program-options1.74.0 \
    libboost-chrono1.74.0 \
    libczmq4 \
    && echo "** cleanup artifacts **" \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ \
    && rm -rf /tmp/* /var/tmp/*

ENV DATADIR="/data"
EXPOSE 9332
EXPOSE 9333
VOLUME /data
CMD ["litecoind", "-printtoconsole"]
