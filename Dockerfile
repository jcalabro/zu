FROM fedora:41

ENV PATH="${PATH}:/root/go/bin"

RUN dnf update -y && \
    dnf install -y \
    cargo go curl git tar xz unzip valgrind

RUN go install github.com/shivakar/quickserve@latest

ADD zig_version.txt .
RUN curl -L https://github.com/marler8997/zigup/releases/download/v2025_01_02/zigup-x86_64-linux.tar.gz | tar xz && \
    mv zigup /usr/bin && \
    zigup fetch $(cat zig_version.txt) && \
    zigup default $(cat zig_version.txt) && rm zig_version.txt
