FROM fedora:41

ENV PATH="${PATH}:/root/go/bin"

RUN dnf update -y && \
    dnf install -y \
    cargo go curl git tar xz unzip valgrind

RUN go install github.com/shivakar/quickserve@latest

RUN curl -L https://github.com/marler8997/anyzig/releases/download/v2025_08_13/anyzig-x86_64-linux.tar.gz | tar xz && \
    mv zig /usr/bin && \
    zig 0.15.1 --help # pull the version we use at image build time
