ARG repo="evmos"

FROM golang:1.19.3-bullseye as build-env

ARG commit_hash
ARG repo

ENV PACKAGES curl make git libc-dev bash gcc jq bc
RUN apt-get update && apt-get upgrade -y && \
  apt-get install -y $PACKAGES

WORKDIR /go/src/github.com/evmos/

RUN git clone "https://github.com/evmos/$repo.git"

WORKDIR /go/src/github.com/evmos/"$repo"
RUN git checkout ${commit_hash}

RUN make build

FROM golang:1.19-bullseye as final

ARG repo

RUN apt update -y && apt install jq bc -y

# Copy over binaries from the build-env
COPY --from=build-env /go/src/github.com/evmos/"$repo"/build/"$repo"d .

COPY evmos/init.sh .
RUN chmod +x *.sh

ENV CHAIN=${repo}

ENTRYPOINT ["/bin/bash", "-c"]

EXPOSE 26556
EXPOSE 26657
EXPOSE 9090
EXPOSE 1317
EXPOSE 8545

