FROM ghdl/ghdl:6.0.0-mcode-ubuntu-24.04@sha256:ee042751cf7ed4bf1d84fd0ef9278504012f69dad503214c99819b4f9388a4dd

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]

CMD ["scripts/compile-rtl.sh"]
