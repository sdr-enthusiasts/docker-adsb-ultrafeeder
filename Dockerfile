FROM ghcr.io/sdr-enthusiasts/docker-baseimage:mlatclient AS buildimage

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
RUN \
    --mount=type=bind,source=./,target=/app/ \
    # this baseimage has build-essential installed, no need to install it
    #apt-get update -q -y && \
    #apt-get install -o Dpkg::Options::="--force-confnew" -y --no-install-recommends -q \
    #    build-essential && \
    gcc -static /app/downloads/distance-in-meters.c -o /distance -lm -O2

FROM ghcr.io/sdr-enthusiasts/docker-tar1090:latest

LABEL org.opencontainers.image.source="https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder"

ENV \
    PRIVATE_MLAT="false" \
    MLAT_INPUT_TYPE="auto"

ARG VERSION_REPO="sdr-enthusiasts/docker-adsb-ultrafeeder" \
    VERSION_BRANCH="##BRANCH##"

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
RUN \
    --mount=type=bind,from=buildimage,source=/,target=/buildimage/ \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Needed to run the mlat_client:
    KEPT_PACKAGES+=(python3-minimal) && \
    KEPT_PACKAGES+=(python3-pkg-resources) && \
    #
    # packages needed for debugging - these can stay out in production builds:
    #KEPT_PACKAGES+=(procps nano aptitude psmisc) && \
    # Install all these packages:
    apt-get update -q -y && \
    apt-get install -o Dpkg::Options::="--force-confnew" -y --no-install-recommends -q \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}" && \
    # Get mlat-client
    tar zxf /buildimage/mlatclient.tgz -C / && \
    ln -s /usr/local/bin/mlat-client /usr/bin/mlat-client && \
    # Get distance binary
    cp -f  /buildimage/distance /usr/local/bin/distance && \
    # Add Container Version
    { [[ "${VERSION_BRANCH:0:1}" == "#" ]] && VERSION_BRANCH="main" || true; } && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(curl -ssL "https://api.github.com/repos/$VERSION_REPO/commits/$VERSION_BRANCH" | awk '{if ($1=="\"sha\":") {print substr($2,2,7); exit}}')_$VERSION_BRANCH" > /.CONTAINER_VERSION && \
    # Clean up:
    apt-get autoremove -q -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0 -y "${TEMP_PACKAGES[@]}" && \
    apt-get clean -q -y && \
    # test mlat-client
    /usr/bin/mlat-client --help > /dev/null && \
    # remove pycache introduced by testing mlat-client
    { find /usr | grep -E "/__pycache__$" | xargs rm -rf || true; } && \
    rm -rf /src /tmp/* /var/lib/apt/lists/* /git /var/cache/* && \
    #
    # Do some stuff for kx1t's convenience:
    echo "alias dir=\"ls -alsv\"" >> /root/.bashrc && \
    echo "alias nano=\"nano -l\"" >> /root/.bashrc

COPY rootfs/ /
