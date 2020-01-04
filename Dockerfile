ARG HASKELL_FEATURE_VERSION=8.6
ARG HASKELL_VERSION=${HASKELL_FEATURE_VERSION}.5
ARG STACK_VERSION=2.1.3
ARG HIE_VERSION=0.14.0.0

## HIE Builder

FROM haskell:${HASKELL_VERSION} AS builder

ARG HASKELL_VERSION
ARG STACK_VERSION
ARG HIE_VERSION

# Configure apt
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install --no-install-recommends apt-utils 2>&1

# Install haskell ide engine dependencies
RUN apt-get -y install libicu-dev libtinfo-dev libgmp-dev

# Create symlink bind directory for build or haskell ide engine
RUN mkdir -p $HOME/.local/bin

# Upgrade stack
RUN stack upgrade --binary-version="${STACK_VERSION}"

# Install haskell ide engine
RUN git clone https://github.com/haskell/haskell-ide-engine.git --recurse-submodules \
    && cd haskell-ide-engine \
    && git checkout ${HIE_VERSION} \
    && stack install.hs stack-hie-${HASKELL_VERSION}

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog


## Haskell GHC with HIE Docker image

FROM haskell:${HASKELL_VERSION}

ARG STACK_VERSION
ARG HASKELL_VERSION
ARG HASKELL_FEATURE_VERSION

# Configure apt
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install --no-install-recommends apt-utils procps wget 2>&1

# Install Docker CE Cli
RUN apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common lsb-release \
    && curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | (OUT=$(apt-key add - 2>&1) || echo $OUT) \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y docker-ce-cli

# Create symlink bind directory for build or haskell ide engine
RUN mkdir -p $HOME/.local/bin

# Upgrade stack
RUN stack upgrade --binary-version="${STACK_VERSION}"

# Copy haskell ide engine from build container
COPY --from=builder /root/.local/bin/hie-${HASKELL_VERSION} /root/.local/bin/
COPY --from=builder /root/.local/bin/hie-wrapper /root/.local/bin/
RUN ln -s /root/.local/bin/hie-${HASKELL_VERSION} /root/.local/bin/hie \
    && ln -s /root/.local/bin/hie-${HASKELL_VERSION} /root/.local/bin/hie-${HASKELL_FEATURE_VERSION}

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

# Set the default shell to bash rather than sh
ENV SHELL /bin/bash
ENTRYPOINT /bin/bash