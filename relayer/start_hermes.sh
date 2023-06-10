#!/bin/bash
DOCKERNET_HOME=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
RELAYER_CONFIG=$DOCKERNET_HOME/hermes_config.toml


LOGS=$DOCKERNET_HOME/logs
CHANNEL_LOGS=$LOGS/channel.log
KEYS_lOGS=$LOGS/keys.log

# Clean from previous run
rm -rf $LOGS/*

mkdir -p $LOGS

EVMOS_CHAINID="evmos_9001-2"
STRIDE_CHAINID="stride-1"

# import evmos account
hermes --config $RELAYER_CONFIG keys add --hd-path "m/44'/60'/0'/0/0" --mnemonic-file /root/mnemonic --chain $EVMOS_CHAINID >> $KEYS_lOGS 2>&1
# import osmosis account
hermes --config $RELAYER_CONFIG keys add --mnemonic-file /root/mnemonic --chain $STRIDE_CHAINID >> $KEYS_lOGS 2>&1

# channel EVMOS - OSMOSIS
hermes --config $RELAYER_CONFIG create channel --a-chain $EVMOS_CHAINID --b-chain $STRIDE_CHAINID --a-port  transfer --b-port transfer --new-client-connection --yes >> $CHANNEL_LOGS 2>&1

# start hermes relayer
hermes --config $RELAYER_CONFIG start

