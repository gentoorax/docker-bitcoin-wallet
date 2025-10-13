FROM ghcr.io/gentoorax/xpra-base:1.0.5-alpha-3f4fc0b
LABEL maintainer="Christopher Law <chris@chrislaw.me>"
ENV BTC_VERSION "29.1"
ENV BTC_GUI_DOWNLOAD_URL https://bitcoincore.org/bin/bitcoin-core-${BTC_VERSION}/bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz
ENV BTC_TARBALL_SHA256 "2dddeaa8c0626ec446b6f21b64c0f3565a1e7e67ff0b586d25043cbd686c9455"
COPY local-entrypoint.sh /
COPY launch-bitcoin.sh /usr/local/bin/launch-bitcoin.sh

RUN apt-get update && \
    apt-get install -y \
        curl \
        zip \
        libfontconfig1 \
        libfreetype6 \
        libegl1-mesa \
        libgl1-mesa-glx \
        libice6 \
        libsm6 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-randr0 \
        libxcb-render0 \
        libxcb-render-util0 \
        libxcb-shape0 \
        libxcb-shm0 \
        libxcb-sync1 \
        libxcb-util1 \
        libxcb-xfixes0 \
        libxcb-xinerama0 \
        libxcb-xkb1 \
        libxkbcommon0 \
        libxkbcommon-x11-0 \
        wmctrl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    chmod 755 /local-entrypoint.sh /usr/local/bin/launch-bitcoin.sh

USER user
WORKDIR /home/user
RUN curl -fsSLO ${BTC_GUI_DOWNLOAD_URL} && \
    echo "${BTC_TARBALL_SHA256}  bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz" | sha256sum -c - && \
    tar zxf bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz && \
    mv bitcoin-${BTC_VERSION} bitcoin-core && \
    rm bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz && \
    mkdir .bitcoin

CMD ["/local-entrypoint.sh"]
EXPOSE 10000
