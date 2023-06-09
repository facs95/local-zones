#!/bin/bash

set -eu
# get current directory
DOCKERNET_HOME=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

STATE=$DOCKERNET_HOME/state
LOGS=$DOCKERNET_HOME/logs
UPGRADES=$DOCKERNET_HOME/upgrades
SRC=$DOCKERNET_HOME/src
PEER_PORT=26656
DOCKER_COMPOSE="docker-compose -f $DOCKERNET_HOME/docker-compose.yml"

RELAYER_EVMOS_EXEC="$DOCKER_COMPOSE run --rm relayer-evmos"

RELAYER_STRIDE_ACCT=rly1
RELAYER_EVMOS_ACCT=rly2

RELAYER_EVMOS_MNEMONIC="science depart where tell bus ski laptop follow child bronze rebel recall brief plug razor ship degree labor human series today embody fury harvest"



relayer_exec=$RELAYER_EVMOS_EXEC
chain_name="evmos"
account_name=$RELAYER_EVMOS_ACCT
mnemonic=$RELAYER_EVMOS_MNEMONIC

relayer_logs=${LOGS}/relayer-evmos.log
relayer_config=$STATE/relayer-evmos/config

mkdir -p $relayer_config
chmod -R 777 $STATE/relayer-${chain_name}
cp ${DOCKERNET_HOME}/config/relayer_config.yaml $relayer_config/config.yaml

$relayer_exec rly keys restore stride $RELAYER_STRIDE_ACCT "$mnemonic" >> $relayer_logs 2>&1
$relayer_exec rly keys restore $chain_name $account_name "$mnemonic" >> $relayer_logs 2>&1

$relayer_exec rly transact link stride-${chain_name} >> $relayer_logs 2>&1

# $DOCKER_COMPOSE up -d relayer-${chain_name}
# $DOCKER_COMPOSE logs -f relayer-${chain_name} | sed -r -u "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" >> $relayer_logs 2>&1 &

