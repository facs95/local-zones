FROM golang:1.19.3-bullseye as builder

ARG commit_hash

ENV PACKAGES curl make git libc-dev bash gcc jq bc
RUN apt-get update && apt-get upgrade -y && \
  apt-get install -y $PACKAGES

WORKDIR /go/src/github.com/Stride-Labs/

RUN git clone https://github.com/Stride-Labs/stride.git \
    && cd stride \
    && git checkout ${commit_hash}

WORKDIR /go/src/github.com/Stride-Labs/stride

RUN make build

FROM golang:1.19-bullseye as final

COPY --from=builder /go/src/github.com/Stride-Labs/stride/build/strided .
RUN apt update -y && apt install jq bc -y

COPY stride/init.sh .
COPY config.sh .
RUN chmod +x *.sh

ENTRYPOINT ["/bin/bash", "-c"]

EXPOSE 26657 26656 1317 9090
