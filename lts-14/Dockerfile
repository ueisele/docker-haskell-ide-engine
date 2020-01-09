FROM debian:stretch-slim
LABEL maintainer="code@uweeisele.eu"

# Set encoding to UTF-8
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Set home dir
ARG HOME=/root

# Create symlink bind directory for build or haskell ide engine
RUN mkdir -p ${HOME}/.local/bin
ENV PATH=${HOME}/.local/bin:$PATH

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
ARG STACK_VERSION=2.1.3
RUN wget -qO- https://github.com/commercialhaskell/stack/releases/download/v${STACK_VERSION}/stack-${STACK_VERSION}-linux-x86_64.tar.gz | tar xz --wildcards --strip-components=1 -C /usr/bin '*/stack'

# Use 'stack' to install basic Haskell tools like cabal, alex and happy
ARG STACK_RESOLVER=lts-14.20
ARG STACK_ROOT=${HOME}/.stack
RUN stack --resolver="${STACK_RESOLVER}" --local-bin-path=${HOME}/.local/bin install \
        # Inastall tool cabal
        cabal-install \ 
        # Haskell GHCI VS Code Debug Adapter (https://marketplace.visualstudio.com/items?itemName=phoityne.phoityne-vscode)
        phoityne-vscode haskell-dap \
        # Other Haskell tools
        happy alex cpphs hscolour hlint hindent \
    # Update Cabal index
    && cabal v2-update \
    # Configure hlint
    && mkdir ${HOME}/.local/bin/data \
    && touch ${HOME}/.local/bin/data/hlint.yaml \
    # Clean up  
    && rm -rf $STACK_ROOT
ENV PATH=${HOME}/.cabal/bin:$PATH

# Install haskell ide engine
ARG GHC_MAIN_VERSION=8.6
ARG GHC_VERSION=${GHC_MAIN_VERSION}.5
ARG HIE_VERSION=1.0.0.0
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
    && rm -rf /opt/haskell-ide-engine \
    && rm -rf $STACK_ROOT \
    && rm ${HOME}/.local/bin/hie \
    && rm ${HOME}/.local/bin/hie-${GHC_MAIN_VERSION} \
    && ln -s ${HOME}/.local/bin/hie-${GHC_VERSION} /root/.local/bin/hie \
    && ln -s ${HOME}/.local/bin/hie-${GHC_VERSION} /root/.local/bin/hie-${GHC_MAIN_VERSION}

# Finally setup stack
RUN stack setup --resolver="${STACK_RESOLVER}" ghc-${GHC_VERSION}
RUN stack update
ENV PATH=${STACK_ROOT}/programs/x86_64-linux/ghc-${GHC_VERSION}/bin:$PATH
RUN stack config set system-ghc --global true \
    && stack config set install-ghc --global false \
    # set the resolver
    && stack --resolver="${STACK_RESOLVER}" exec -- ghc --version

# Install pid1 init daemon
ARG PID1_VERSION=0.1.2.0
RUN wget -qO- https://github.com/fpco/pid1/releases/download/v${PID1_VERSION}/pid1-${PID1_VERSION}-linux-x86_64.tar.gz | tar xz -C /usr/local

# Set up pid1 entrypoint and default command
ENTRYPOINT ["/usr/local/sbin/pid1"]
CMD ["/bin/bash"]

# Set Git related labels
ARG SOURCE_GIT_REPOSITORY
ARG SOURCE_GIT_COMMIT
ARG DOCKERFILE_URL

LABEL source.git.repository=${SOURCE_GIT_REPOSITORY} \
      source.git.commit=${SOURCE_GIT_COMMIT} \
      dockerfile.url=${DOCKERFILE_URL}

# Set Haskell related labels
LABEL ghc.version=${GHC_VERSION} \
      stack.resolver=${STACK_RESOLVER} \
      stack.version=${STACK_VERSION} \
      hie.version=${HIE_VERSION}