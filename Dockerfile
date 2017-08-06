FROM lsiobase/alpine:3.6

# environment variables
ENV \
    PYTHON_EGG_CACHE="/config/deluge/plugins" \
    LIBTORRENT_VERSION=1.1.4 \
    DELUGE_VERSION=1.3.15

# install build packages
RUN \
  apk add --no-cache --virtual .build-dependencies \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    curl \
    geoip-dev \
    g++ \
    gcc \
    gettext-dev \
    jpeg-dev \
    libffi-dev \
    openssl-dev \
    python2-dev && \

  apk add --no-cache --virtual .build-dependencies \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    boost-build \
    gnu-libiconv-dev && \

# install runtime packages
  apk add --no-cache \
    bash \
    # boost \
    boost-python \
    ca-certificates \
    geoip \
    gettext \
    intltool \
    jpeg \
    openssl \
    p7zip \
    python2 \
    # py2-pip \
    unrar \
    unzip && \

  python -m ensurepip --upgrade && \
  pip install -U pip setuptools && \

  apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    gnu-libiconv && \

  mkdir -p /tmp/libtorrent /tmp/deluge && \
  cd /tmp && \
  curl -SL -O https://github.com/arvidn/libtorrent/releases/download/libtorrent-${LIBTORRENT_VERSION//\./_}/libtorrent-rasterbar-${LIBTORRENT_VERSION}.tar.gz && \
  tar -C /tmp/libtorrent --strip-components=1 -xf /tmp/libtorrent-rasterbar-${LIBTORRENT_VERSION}.tar.gz && \
  export BOOST_BUILD_PATH=/usr/share/boost-build && \
  printf "using gcc : : : <compileflags>-w ;\nusing python : 2.7 : /usr/bin/python2.7 : /usr/include/python2.7 : /usr/lib/python2.7 ;" > \
    $BOOST_BUILD_PATH/user-config.jam && \
  # cd /tmp/libtorrent && \
  # b2 variant=release iconv=on install && \
  cd /tmp/libtorrent/bindings/python && \
  # b2 variant=release iconv=on && \
  b2 libtorrent-link=static variant=release iconv=on && \
  find /tmp/libtorrent/bindings/python/bin -name libtorrent.so -exec mv -u -v -t /usr/lib/python2.7/site-packages {} + && \
  # mv -u -v bin/gcc-6.3.0/release/iconv-on/libtorrent-python-pic-on/visibility-hidden/libtorrent.so /usr/lib/python2.7/site-packages && \
  # python -c "import libtorrent; print libtorrent.version"
  # python -c "from deluge._libtorrent import lt; print lt.version"

# install pip packages
  pip install --no-cache-dir -U \
    chardet \
    mako \
    Pillow \
    pyopenssl \
    python-geoip \
    pyxdg \
    setproctitle \
    slimit \
    twisted[tls] && \

  cd /tmp && \
  curl -SL -O http://git.deluge-torrent.org/deluge/snapshot/deluge-deluge-${DELUGE_VERSION}.tar.gz && \
  tar -C /tmp/deluge --strip-components=1 -xf /tmp/deluge-deluge-${DELUGE_VERSION}.tar.gz && \
  cd /tmp/deluge && \
  python setup.py build && \
  python setup.py install && \
  # python setup.py clean -a && \\

# cleanup
  apk del --purge .build-dependencies && \
  rm -rf /root/.cache /tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 8112 58846 58946 58946/udp
VOLUME /config /downloads
