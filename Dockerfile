FROM ghcr.io/sdr-enthusiasts/docker-baseimage:mlatclient as mlatclient

FROM ghcr.io/sdr-enthusiasts/docker-tar1090:latest

LABEL org.opencontainers.image.source = "https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder"

ENV URL_MLAT_CLIENT_REPO="https://github.com/wiedehopf/mlat-client.git" \
    PRIVATE_MLAT="false" \
    MLAT_INPUT_TYPE="auto"

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
RUN \
    --mount=type=bind,source=./,target=/app/ \
    --mount=type=bind,from=mlatclient,source=/,target=/mlatclient/ \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Needed to run the mlat_client:
    KEPT_PACKAGES+=(python3-minimal) && \
    KEPT_PACKAGES+=(python3-pkg-resources) && \
    # needed to compile distance
    TEMP_PACKAGES+=(build-essential) && \
    # needed for container version
    TEMP_PACKAGES+=(git) && \
    #
    # packages needed for debugging - these can stay out in production builds:
    #KEPT_PACKAGES+=(procps nano aptitude psmisc) && \
    # Install all these packages:
    apt-get update -q -y && \
    apt-get install -o Dpkg::Options::="--force-confnew" -y --no-install-recommends -q \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}" && \
    # Get mlat-client
    tar zxf /mlatclient/mlatclient.tgz -C / && \
    ln -s /usr/local/bin/mlat-client /usr/bin/mlat-client && \
    # Compile distance binary
    gcc -static /app/downloads/distance-in-meters.c -o /usr/local/bin/distance -lm -O2 && \
    # Add Container Version
    branch="##BRANCH##" && \
    [[ "${branch:0:1}" == "#" ]] && branch="main" || true && \
    git clone --depth=1 -b "$branch" https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder.git /tmp/clone && \
    pushd /tmp/clone && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(git rev-parse --short HEAD)_$(git branch --show-current)" > /.CONTAINER_VERSION && \
    popd && \
    # Clean up and install POST_PACKAGES:
    apt-get remove -q -y "${TEMP_PACKAGES[@]}" && \
    # apt-get install -o Dpkg::Options::="--force-confnew" -y --no-install-recommends -q \
    # ${POST_PACKAGES[@]} && \
    apt-get autoremove -q -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0 -y && \
    apt-get clean -q -y && \
    # test mlat-client
    /usr/bin/mlat-client --help > /dev/null && \
    # remove pycache introduced by testing mlat-client
    find /usr | grep -E "/__pycache__$" | xargs rm -rf || true && \
    rm -rf /src /tmp/* /var/lib/apt/lists/* /git /var/cache/* && \
    #
    # Do some stuff for kx1t's convenience:
    echo "alias dir=\"ls -alsv\"" >> /root/.bashrc && \
    echo "alias nano=\"nano -l\"" >> /root/.bashrc

COPY rootfs/ /
