# -------------------------------------------------------------------
# Stage 1: Build Emscripten SDK
# -------------------------------------------------------------------
FROM debian:bookworm-slim AS emscripten-build

ARG EMSCRIPTEN_VERSION=5.0.2

ENV EMSDK=/emsdk
ENV EM_CACHE=/emsdk/upstream/emscripten/cache

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    python3 \
    python3-pip \
    nodejs \
    clang \
    llvm \
    binutils \
    make \
    unzip \
    tar \
    xz-utils \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/emscripten-core/emsdk.git "${EMSDK}"

RUN set -eux; \
    cd "${EMSDK}"; \
    ./emsdk install "${EMSCRIPTEN_VERSION}"; \
    ./emsdk activate "${EMSCRIPTEN_VERSION}"

# Pre-build system libraries to populate the cache.
RUN set -eux; \
    cd "${EMSDK}"; \
    . ./emsdk_env.sh; \
    embuilder build \
        libc \
        libc++ \
        libc++abi \
        libcompiler_rt

# Strip binaries and remove unnecessary documentation/tests.
RUN set -eux; \
    if command -v node >/dev/null 2>&1; then \
        strip -s "$(command -v node)" || true; \
    fi; \
    find "${EMSDK}/upstream/bin" -name 'clang*' \
        -exec strip -s {} + || true; \
    rm -rf "${EMSDK}/upstream/emscripten/tests" \
           "${EMSDK}/upstream/emscripten/docs"


# -------------------------------------------------------------------
# Stage 2: Emscripten runtime image
# -------------------------------------------------------------------
FROM debian:bookworm-slim AS emscripten-runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    python3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=emscripten-build /emsdk /emsdk

ENV EMSDK=/emsdk
ENV EM_CACHE=/emsdk/upstream/emscripten/cache
ENV PATH="/emsdk:/emsdk/upstream/emscripten:/emsdk/node/bin:${PATH}"

WORKDIR /workspace

CMD ["/bin/bash"]


# -------------------------------------------------------------------
# Stage 3: Install Odin
# -------------------------------------------------------------------
FROM emscripten-runtime AS odin-build

ARG ODIN_VERSION=dev-2026-10

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl tar \
    llvm clang build-essential \
    && rm -rf /var/lib/apt/lists/*

ENV ODIN_VERSION=${ODIN_VERSION}
ENV ODIN_ROOT=/opt/odin
ENV PATH="${ODIN_ROOT}:${PATH}"

RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "${ARCH}" in \
        x86_64|amd64) ODIN_ARCH=amd64 ;; \
        aarch64|arm64) ODIN_ARCH=arm64 ;; \
        *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
    esac; \
    ODIN_URL="https://github.com/odin-lang/Odin/releases/download/${ODIN_VERSION}/odin-linux-${ODIN_ARCH}-${ODIN_VERSION}.tar.gz"; \
    echo "Downloading ${ODIN_URL}"; \
    curl -fSL "${ODIN_URL}" -o /tmp/odin.tar.gz; \
    mkdir -p "${ODIN_ROOT}"; \
    tar -xzf /tmp/odin.tar.gz --strip-components=1 -C "${ODIN_ROOT}"; \
    rm /tmp/odin.tar.gz

CMD ["/bin/bash"]
