FROM ghcr.io/gentoorax/xpra-base:1.0.5-alpha-3f4fc0b
LABEL maintainer="Christopher Law <chris@chrislaw.me>"
ENV BTC_VERSION "31.0"
ENV BTC_GUI_DOWNLOAD_URL https://bitcoincore.org/bin/bitcoin-core-${BTC_VERSION}/bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz
ENV BTC_SHA256SUMS_URL https://bitcoincore.org/bin/bitcoin-core-${BTC_VERSION}/SHA256SUMS
ENV BTC_SHA256SUMS_ASC_URL https://bitcoincore.org/bin/bitcoin-core-${BTC_VERSION}/SHA256SUMS.asc
ENV BTC_GUIX_SIGS_COMMIT 9b5f169268d27933c4e1fc1815ddb4b8463ebe05
ENV BTC_GUIX_SIGS_URL https://github.com/bitcoin-core/guix.sigs/archive/${BTC_GUIX_SIGS_COMMIT}.tar.gz
ENV BTC_TARBALL_SHA256 "d3e4c58a35b1d0a97a457462c94f55501ad167c660c245cb1ffa565641c65074"
COPY local-entrypoint.sh /
COPY launch-bitcoin.sh /usr/local/bin/launch-bitcoin.sh
COPY launch-xterm.sh /usr/local/bin/launch-xterm.sh

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
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
        libxcb-cursor0 \
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
        wmctrl \
        xdotool \
        xterm && \
    printf '%s\n' \
        '[Desktop Entry]' \
        'Type=Application' \
        'Version=1.0' \
        'Name=Bitcoin Wallet' \
        'Comment=Launch the Bitcoin Core wallet GUI' \
        'Exec=/usr/local/bin/launch-bitcoin.sh' \
        'Icon=/home/user/bitcoin-core/share/pixmaps/bitcoin128.png' \
        'Terminal=false' \
        'Categories=Network;Finance;' \
        'StartupNotify=true' \
        > /usr/share/applications/bitcoin-wallet.desktop && \
    printf '%s\n' \
        '[Desktop Entry]' \
        'Type=Application' \
        'Version=1.0' \
        'Name=XTerm' \
        'Comment=Launch an xterm terminal' \
        'Exec=/usr/local/bin/launch-xterm.sh' \
        'Icon=utilities-terminal' \
        'Terminal=false' \
        'Categories=System;TerminalEmulator;' \
        'StartupNotify=true' \
        > /usr/share/applications/xterm-wallet.desktop && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    chmod 755 /local-entrypoint.sh /usr/local/bin/launch-bitcoin.sh /usr/local/bin/launch-xterm.sh

USER user
WORKDIR /home/user
RUN curl -fsSLO ${BTC_GUI_DOWNLOAD_URL} && \
    curl -fsSLO ${BTC_SHA256SUMS_URL} && \
    curl -fsSLO ${BTC_SHA256SUMS_ASC_URL} && \
    curl -fsSL ${BTC_GUIX_SIGS_URL} | tar xz && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --batch --import guix.sigs-${BTC_GUIX_SIGS_COMMIT}/builder-keys/* && \
    gpg --batch --verify SHA256SUMS.asc SHA256SUMS && \
    grep " bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz\$" SHA256SUMS | sha256sum -c - && \
    tar zxf bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz && \
    mv bitcoin-${BTC_VERSION} bitcoin-core && \
    rm -rf "${GNUPGHOME}" guix.sigs-${BTC_GUIX_SIGS_COMMIT} SHA256SUMS SHA256SUMS.asc bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz && \
    mkdir -p .bitcoin && \
    chmod 700 .bitcoin && \
    mkdir -p .config/openbox && \
    cat <<'EOF' > .config/openbox/rc.xml
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <placement>
    <policy>Smart</policy>
    <center>yes</center>
    <monitor>Primary</monitor>
  </placement>
  <applications>
    <application class="bitcoin-qt">
      <position force="yes">
        <monitor>Primary</monitor>
        <x>center</x>
        <y>center</y>
      </position>
    </application>
    <application name="bitcoin-qt">
      <position force="yes">
        <monitor>Primary</monitor>
        <x>center</x>
        <y>center</y>
      </position>
    </application>
  </applications>
</openbox_config>
EOF

CMD ["/local-entrypoint.sh"]
EXPOSE 10000
