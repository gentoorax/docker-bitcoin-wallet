FROM ghcr.io/gentoorax/xpra-base:2.0.8-alpha-da71e25
LABEL maintainer="Christopher Law <chris@chrislaw.me>"
ENV BTC_VERSION "31.0"
ARG BTC_GUI_DOWNLOAD_URL=https://bitcoincore.org/bin/bitcoin-core-${BTC_VERSION}/bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz
ARG BTC_SHA256SUMS_URL=https://bitcoincore.org/bin/bitcoin-core-${BTC_VERSION}/SHA256SUMS
ARG BTC_SHA256SUMS_ASC_URL=https://bitcoincore.org/bin/bitcoin-core-${BTC_VERSION}/SHA256SUMS.asc
ARG BTC_GUIX_SIGS_COMMIT=9b5f169268d27933c4e1fc1815ddb4b8463ebe05
ARG BTC_GUIX_SIGS_URL=https://github.com/bitcoin-core/guix.sigs/archive/${BTC_GUIX_SIGS_COMMIT}.tar.gz
ARG BTC_TRUSTED_FINGERPRINTS="E777299FC265DD04793070EB944D35F9AC3DB76A 152812300785C96444D3334D17565732E08E5E41 ED9BDF7AD6A55E232E84524257FF9BDBCC301009 D1DBF2C4B96F2DEBF4C16654410108112E7EA81F"
ARG BTC_TRUSTED_SIGNATURE_THRESHOLD=2
ARG BTC_TARBALL_SHA256=d3e4c58a35b1d0a97a457462c94f55501ad167c660c245cb1ffa565641c65074
COPY local-entrypoint.sh /
COPY launch-bitcoin.sh /usr/local/bin/launch-bitcoin.sh

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        desktop-file-utils \
        gnupg \
        libfontconfig1 \
        libfreetype6 \
        libegl1 \
        libgl1 \
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
        menu \
        openbox \
        wmctrl \
        xdg-utils \
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
    mkdir -p /etc/xdg/menus && \
    printf '%s\n' \
        '<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"' \
        ' "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">' \
        '<Menu>' \
        '  <Name>Applications</Name>' \
        '  <DefaultAppDirs/>' \
        '  <DefaultDirectoryDirs/>' \
        '  <Include>' \
        '    <All/>' \
        '  </Include>' \
        '</Menu>' \
        > /etc/xdg/menus/applications.menu && \
    cp /etc/xdg/menus/applications.menu /etc/xdg/menus/debian-menu.menu && \
    cp /etc/xdg/menus/applications.menu /etc/xdg/menus/kde-debian-menu.menu && \
    update-desktop-database /usr/share/applications && \
    sed -i 's/\r$//' /local-entrypoint.sh /usr/local/bin/launch-bitcoin.sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    chmod 755 /local-entrypoint.sh /usr/local/bin/launch-bitcoin.sh

USER user
WORKDIR /home/user
RUN curl -fsSLO ${BTC_GUI_DOWNLOAD_URL} && \
    curl -fsSLO ${BTC_SHA256SUMS_URL} && \
    curl -fsSLO ${BTC_SHA256SUMS_ASC_URL} && \
    curl -fsSL ${BTC_GUIX_SIGS_URL} | tar xz && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --batch --import guix.sigs-${BTC_GUIX_SIGS_COMMIT}/builder-keys/* && \
    gpg --batch --status-fd=1 --verify SHA256SUMS.asc SHA256SUMS > gpg-status.log 2>/dev/null && \
    trusted_count="$(awk '/^\[GNUPG:\] VALIDSIG / { print $3 }' gpg-status.log | sort -u | awk 'BEGIN { split(ENVIRON["BTC_TRUSTED_FINGERPRINTS"], trusted, " "); for (i in trusted) allow[trusted[i]] = 1 } allow[$1] { count++ } END { print count + 0 }')" && \
    test "${trusted_count}" -ge "${BTC_TRUSTED_SIGNATURE_THRESHOLD}" && \
    grep " bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz\$" SHA256SUMS | sha256sum -c - && \
    tar zxf bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz && \
    mv bitcoin-${BTC_VERSION} bitcoin-core && \
    rm -rf "${GNUPGHOME}" guix.sigs-${BTC_GUIX_SIGS_COMMIT} SHA256SUMS SHA256SUMS.asc gpg-status.log bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz && \
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
