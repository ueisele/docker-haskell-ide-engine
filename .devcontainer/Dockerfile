FROM debian:11.2-slim
LABEL maintainer="code@uweeisele.eu"

# Set locales
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Install required dependencies
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install --no-install-recommends \
        procps sudo \
        ca-certificates hostname net-tools curl wget telnet \
        tar gzip xz-utils less vim git \
        make gcc g++ \
        libicu-dev libtinfo-dev libgmp-dev zlib1g-dev libsqlite3-dev libc6-dev libffi-dev libncurses-dev libnuma-dev z3 \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

# Install and setup pid1 for signal handling and orphan reaping
ARG PID1_VERSION=0.1.3.0
RUN curl -Lo- https://github.com/fpco/pid1/releases/download/pid1-${PID1_VERSION}/pid1-${PID1_VERSION}-linux-x86_64.tar.gz \
    | tar xz -C /usr/local
ENTRYPOINT ["/usr/local/sbin/pid1"]
CMD ["bash"]

# Create and setup user
ARG HASKELL_USER=haskell
RUN useradd --no-log-init --create-home --shell /bin/bash ${HASKELL_USER} \
    && usermod -aG sudo ${HASKELL_USER} \
    && sed -i 's/%sudo.*ALL=(ALL:ALL).*ALL/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
USER ${HASKELL_USER}
WORKDIR /home/${HASKELL_USER}
RUN mkdir -p /home/${HASKELL_USER}/.local/bin
ENV PATH=/home/${HASKELL_USER}/.local/bin:${PATH}

# Install and setup GHCup
ARG GHCUP_VERSION=0.1.17.4
ARG GHCUP_BINDIR=/home/${HASKELL_USER}/.ghcup/bin
RUN mkdir -p ${GHCUP_BINDIR}
ENV PATH=${GHCUP_BINDIR}:${PATH}
RUN curl -sL -o ${GHCUP_BINDIR}/ghcup https://downloads.haskell.org/~ghcup/0.1.17.4/x86_64-linux-ghcup-${GHCUP_VERSION} \
    && chmod +x ${GHCUP_BINDIR}/ghcup

# Install and setup GHC
ARG GHC_VERSION=8.10.7
RUN ghcup install ghc ${GHC_VERSION} \
    && ghcup set ghc ${GHC_VERSION}

# Install and setup Stack
ARG STACK_VERSION=2.7.3
RUN ghcup install stack ${STACK_VERSION}
RUN stack config set system-ghc true --global \
    && stack config set install-ghc false --global
RUN printf "ghc-options:\n  \"\$everything\": -haddock\n" >> /home/${HASKELL_USER}/.stack/config.yaml
ARG STACK_RESOLVER=lts-18.21
RUN stack --resolver=${STACK_RESOLVER} --compiler=ghc-${GHC_VERSION} setup \
    && cd /home/${HASKELL_USER}/.stack \
    && find . -type f \
        -not -path "./config.yaml" \
        -and -not -path "./global-project/stack.yaml" \
        -exec rm '{}' \; \
    && (find . -type d -print0 | sort -rz | xargs -0 rmdir 2>/dev/null || true)

# Install dependencies
RUN eval 'ver() { printf "%03d%03d%03d" $(echo "$1" | tr "." " "); };'; \
    if [ $(ver ${GHC_VERSION}) -ge $(ver 9.2) ]; then \ 
        retrie_version=1.2.0.1; \
    elif [ $(ver ${GHC_VERSION}) -ge $(ver 8.8) ] && [ $(ver ${GHC_VERSION}) -lt $(ver 9.2) ]; then \ 
        retrie_version=1.1.0.0; \
    elif [ $(ver ${GHC_VERSION}) -ge $(ver 8.4) ] && [ $(ver ${GHC_VERSION}) -lt $(ver 8.8) ]; then \ 
        retrie_version=0.1.1.1; \
    fi \
    && stack install \
        # Install dependencies for jcanero.hoogle-vscode vscode extension
        hoogle \
        # Install dependencies for haskell.haskell vscode extension
        ormolu retrie-${retrie_version} hlint apply-refact \
        # Install dependencies for phoityne.phoityne-vscode extension
        haskell-dap ghci-dap haskell-debug-adapter \
    && cd /home/${HASKELL_USER}/.stack \
    && find . -type f \
        -not -path "./config.yaml" \
        -and -not -path "./global-project/stack.yaml" \
        -and -not -path './snapshots/*/share/*' \
        -exec rm '{}' \; \
    && (find . -type d -print0 | sort -rz | xargs -0 rmdir 2>/dev/null || true)

# Generate hoogle index
RUN hoogle generate

# Install the Haskell language server
ARG HLS_VERSION=1.5.1
RUN ghcup install hls ${HLS_VERSION}

# Set version labels
LABEL ghcup.version=${GHCUP_VERSION} \
      ghc.version=${GHC_VERSION} \
      stack.version=${STACK_VERSION} \
      stack.resolver=${STACK_RESOLVER} \
      hls.version=${HLS_VERSION}