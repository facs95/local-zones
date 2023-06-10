# syntax = docker/dockerfile:1
FROM rust:1.70-buster AS builder

WORKDIR /src/

ARG commit_hash

RUN git clone https://github.com/informalsystems/hermes.git \
    && cd hermes \
    && git checkout $commit_hash \
    && cargo build --release --bin hermes

FROM debian:bullseye-slim
RUN apt update -y && apt install jq bc -y

COPY --from=builder /src/hermes/target/release/hermes /usr/local/bin/hermes

COPY /relayer/hermes_config.toml /root
COPY /relayer/start_hermes.sh /root
COPY /relayer/mnemonic /root
RUN chmod +x /root/start_hermes.sh
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.9.0/wait /root/wait
RUN chmod +x /root/wait

