FROM ghcr.io/gentoorax/xpra-base:1.0.5-alpha-3f4fc0b
MAINTAINER Christopher Law <chris@chrislaw.me>
ENV BTC_VERSION "29.1"
ENV BTC_GUI_DOWNLOAD_URL https://bitcoincore.org/bin/bitcoin-core-${BTC_VERSION}/bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz
ENV BTC_TARBALL_SHA256 "2dddeaa8c0626ec446b6f21b64c0f3565a1e7e67ff0b586d25043cbd686c9455"
COPY local-entrypoint.sh /

RUN apt-get update && \
    apt-get install -y curl zip libfontconfig1 libfreetype6 \
                       libegl1-mesa libgl1-mesa-glx && \
    apt-get clean && \
    chmod 755 /local-entrypoint.sh

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
