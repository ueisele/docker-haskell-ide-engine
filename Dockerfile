ARG BUILDER_HASKELL_VERSION=8.6.5
ARG BUILDER_STACK_VERSION=2.1.3
ARG HIE_VERSION=0.14.0.0
ARG HASKELL_VERSION=8.8.1

FROM haskell:${BUILDER_HASKELL_VERSION} AS builder

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
RUN stack upgrade --binary-version=${BUILDER_STACK_VERSION}

# Install haskell ide engine
RUN git clone https://github.com/haskell/haskell-ide-engine.git --recurse-submodules \
    && cd haskell-ide-engine \
    && git checkout ${HIE_VERSION} \
    && stack install.hs stack-hie-${BUILDER_HASKELL_VERSION}

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog


FROM haskell:${HASKELL_VERSION}

# Configure apt
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install --no-install-recommends apt-utils 2>&1

# Create symlink bind directory for build or haskell ide engine
RUN mkdir -p $HOME/.local/bin

# Upgrade stack
RUN stack upgrade

# Copy haskell ide engine from build container
COPY --from=builder /root/.local/bin/hie /root/.local/bin/

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

# Set the default shell to bash rather than sh
ENV SHELL /bin/bash
ENTRYPOINT /bin/bash