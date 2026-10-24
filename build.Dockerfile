FROM emscripten/emsdk:latest

ARG ODIN_VERSION=dev-2026-10

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl tar \
    clang libclang-rt-18-dev libx11-dev \
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
