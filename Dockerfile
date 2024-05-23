FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base AS build

RUN set -x && \
    apt-get update -y && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y \
        gcc && \
    cd / && \
    curl -sSL https://raw.githubusercontent.com/sdr-enthusiasts/docker-adsb-ultrafeeder/main/downloads/distance.c -o /distance.c && \
    gcc -static distance.c -o distance -lm -Ofast

FROM ghcr.io/sdr-enthusiasts/docker-tar1090:latest

LABEL org.opencontainers.image.source = "https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder"

ENV URL_MLAT_CLIENT_REPO="https://github.com/wiedehopf/mlat-client.git" \
    PRIVATE_MLAT="false" \
    MLAT_INPUT_TYPE="auto"

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
RUN TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Git and net-tools are needed to install and run @Mikenye's HealthCheck framework
    KEPT_PACKAGES+=(git) && \
    #
    # Needed to run the mlat_client:
    # POST_PACKAGES+=(python3-minimal) && \
    #
    # These are needed to compile and install the mlat_client:
    KEPT_PACKAGES+=(python3) && \
    KEPT_PACKAGES+=(python3-pkg-resources) && \
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(debhelper) && \
    TEMP_PACKAGES+=(python3-dev) && \
    TEMP_PACKAGES+=(python3-distutils-extra) && \
    TEMP_PACKAGES+=(python3-pip) && \
    TEMP_PACKAGES+=(python3-setuptools) && \
    TEMP_PACKAGES+=(python3-wheel) && \
    #
    # packages needed for debugging - these can stay out in production builds:
    #KEPT_PACKAGES+=(procps nano aptitude psmisc) && \
    # Install all these packages:
    apt-get update -q -y && \
    apt-get install -o Dpkg::Options::="--force-confnew" -y --no-install-recommends -q \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}" && \
    #
    # Compile and Install the mlat_client
    mkdir -p /git && \
    pushd /git && \
    git clone --depth 1 $URL_MLAT_CLIENT_REPO && \
    cd mlat-client && \
    ./setup.py install && \
    ln -s /usr/local/bin/mlat-client /usr/bin/mlat-client && \
    popd && \
    rm -rf /git && \
    #
    # Clean up and install POST_PACKAGES:
    apt-get remove -q -y "${TEMP_PACKAGES[@]}" && \
    # apt-get install -o Dpkg::Options::="--force-confnew" -y --no-install-recommends -q \
    # ${POST_PACKAGES[@]} && \
    apt-get autoremove -q -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0 -y && \
    find /usr | grep -E "/__pycache__$" | xargs rm -rf || true && \
    apt-get clean -q -y && \
    rm -rf /src /tmp/* /var/lib/apt/lists/* /git /var/cache/* && \
    #
    # Do some stuff for kx1t's convenience:
    echo "alias dir=\"ls -alsv\"" >> /root/.bashrc && \
    echo "alias nano=\"nano -l\"" >> /root/.bashrc

COPY rootfs/ /
COPY --from=build /distance /usr/local/bin/distance

# Add Container Version
RUN set -x && \
    branch="##BRANCH##" && \
    [[ "${branch:0:1}" == "#" ]] && branch="main" || true && \
    git clone --depth=1 -b "$branch" https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder.git /tmp/clone && \
    pushd /tmp/clone && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(git rev-parse --short HEAD)_$(git branch --show-current)" > /.CONTAINER_VERSION && \
    popd && \
    rm -rf /tmp/*
