#!/bin/bash
RELAYER_CONFIG=/root/.hermes/config.toml
EVMOS_CHAINID="evmos_9000-1"
STRIDE_CHAINID="STRIDE"

# import evmos account
hermes --config $RELAYER_CONFIG keys add --hd-path "m/44'/60'/0'/0/0" --mnemonic-file /root/mnemonic --chain $EVMOS_CHAINID
# import osmosis account
hermes --config $RELAYER_CONFIG keys add --mnemonic-file /root/mnemonic --chain $STRIDE_CHAINID

# channel EVMOS - OSMOSIS
hermes --config $RELAYER_CONFIG create channel --a-chain $EVMOS_CHAINID --b-chain $STRIDE_CHAINID --a-port  transfer --b-port transfer --new-client-connection --yes

# start hermes relayer
hermes --config $RELAYER_CONFIG start

