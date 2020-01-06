FROM debian:stretch-slim

ARG SOURCE_GIT_REPOSITORY
ARG SOURCE_GIT_COMMIT

LABEL maintainer="code@uweeisele.eu" \
      source.git.repository=${SOURCE_GIT_REPOSITORY} \
      source.git.commit=${SOURCE_GIT_COMMIT}

ARG GHC_MAIN_VERSION=8.6
ARG GHC_VERSION=${GHC_MAIN_VERSION}.5
ARG STACK_RESOLVER=lts-14.20
ARG STACK_VERSION=2.1.3
ARG STACK_ROOT=/root/.stack
ARG HIE_VERSION=1.0.0.0
ARG PID1_VERSION=0.1.2.0

LABEL ghc.version=${GHC_VERSION} \
      stack.resolver=${STACK_RESOLVER} \
      stack.version=${STACK_VERSION} \
      hie.version=${HIE_VERSION}

# Create symlink bind directory for build or haskell ide engine
RUN mkdir -p $HOME/.local/bin

# Set encoding to UTF-8 and PATH to find GHC and cabal/stack-installed binaries
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/root/.cabal/bin:/root/.local/bin:${STACK_ROOT}/programs/x86_64-linux/ghc-${GHC_VERSION}/bin:$PATH

# Configure apt
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    # Install common tools, Docker cli dependecies and Haskell IDE engine dependencies
    && apt-get -y install --no-install-recommends \
        apt-utils procps dnsutils netbase net-tools telnet wget curl dirmngr less vim git \
        g++ gcc make xz-utils libicu-dev libtinfo-dev libgmp-dev zlib1g-dev libsqlite3-dev libc6-dev libffi-dev  \
        gnupg gnupg-agent openssh-client ca-certificates apt-transport-https software-properties-common lsb-release \
    # Install Docker Cli
    && curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | (OUT=$(apt-key add - 2>&1) || echo $OUT) \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get -y install --no-install-recommends docker-ce-cli \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog


# Install stack
RUN wget -qO- https://github.com/commercialhaskell/stack/releases/download/v${STACK_VERSION}/stack-${STACK_VERSION}-linux-x86_64.tar.gz | tar xz --wildcards --strip-components=1 -C /usr/bin '*/stack'

# Use 'stack' to install basic Haskell tools like cabal, alex and happy
RUN stack --resolver="${STACK_RESOLVER}" --local-bin-path=/root/.local/bin install \
        cabal-install happy alex cpphs gtk2hs-buildtools hscolour hlint hindent \
    && cabal v2-update \
    # Clean up  
    && rm -rf $STACK_ROOT

# Install haskell ide engine
RUN cd /opt \
    && git clone https://github.com/haskell/haskell-ide-engine.git --recurse-submodules \
    && cd haskell-ide-engine \
    && git checkout ${HIE_VERSION} \
    && sed -i "s|resolver:.\+|resolver: ${STACK_RESOLVER} # GHC ${GHC_VERSION}|g" install/shake.yaml \
    && sed -i "s|resolver:.\+|resolver: ${STACK_RESOLVER} # GHC ${GHC_VERSION}|g" stack-${GHC_VERSION}.yaml \
    && sed -i "s|resolver:.\+|resolver: ${STACK_RESOLVER} # GHC ${GHC_VERSION}|g" stack.yaml \
    && stack ./install.hs stack-hie-${GHC_VERSION} \
    && stack ./install.hs stack-build-data \
    # Clean up
    && stack clean \
    && rm -rf $STACK_ROOT \
    && rm /root/.local/bin/hie* \
    && ln -s $(readlink -f /opt/haskell-ide-engine/.stack-work/install/x86_64-linux/*/${GHC_VERSION}/bin/hie) /root/.local/bin/hie-${GHC_VERSION} \
    && ln -s $(readlink -f /opt/haskell-ide-engine/.stack-work/install/x86_64-linux/*/${GHC_VERSION}/bin/hie-wrapper) /root/.local/bin/hie-wrapper \
    && ln -s /root/.local/bin/hie-${GHC_VERSION} /root/.local/bin/hie \
    && ln -s /root/.local/bin/hie-${GHC_VERSION} /root/.local/bin/hie-${GHC_MAIN_VERSION}

# Finally setup stack
RUN stack setup --resolver="${STACK_RESOLVER}" ghc-${GHC_VERSION}
RUN stack config set system-ghc --global true \
    && stack config set install-ghc --global false \
    # set the resolver
    && stack --resolver="${STACK_RESOLVER}" exec -- ghc --version

# Install pid' init daemon
RUN wget -qO- https://github.com/fpco/pid1/releases/download/v${PID1_VERSION}/pid1-${PID1_VERSION}-linux-x86_64.tar.gz | tar xz -C /usr/local

# Set up pid1 entrypoint and default command
ENTRYPOINT ["/usr/local/sbin/pid1"]
CMD ["/bin/bash"]