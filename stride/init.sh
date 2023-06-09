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


# Logs
STRIDE_LOGS=$LOGS/stride.log
TX_LOGS=$DOCKERNET_HOME/logs/tx.log
KEYS_LOGS=$DOCKERNET_HOME/logs/keys.log
SETUP_LOGS=$DOCKERNET_HOME/logs/setup.log
CHAIN="stride"
# DENOMS
STRD_DENOM="ustrd"
# set denom based on chain
# Config
STRIDE_CHAIN_ID=STRIDE
STRIDE_NODE_PREFIX=stride
STRIDE_VAL_PREFIX=val
STRIDE_ADDRESS_PREFIX=stride
STRIDE_DENOM=$STRD_DENOM
STRIDE_RPC_PORT=26657
STRIDE_ADMIN_ACCT=admin
STRIDE_ADMIN_ADDRESS=stride1u20df3trc2c2zdhm8qvh2hdjx9ewh00sv6eyy8
STRIDE_ADMIN_MNEMONIC="tone cause tribe this switch near host damage idle fragile antique tail soda alien depth write wool they rapid unfold body scan pledge soft"
STRIDE_FEE_ADDRESS=stride1czvrk3jkvtj8m27kqsqu2yrkhw3h3ykwj3rxh6

VAL_MNEMONIC_1="close soup mirror crew erode defy knock trigger gather eyebrow tent farm gym gloom base lemon sleep weekend rich forget diagram hurt prize fly"

# binaries
STRIDE_BINARY="$DOCKERNET_HOME/strided"

# COIN TYPES
# Coin types can be found at https://github.com/satoshilabs/slips/blob/master/slip-0044.md
COSMOS_COIN_TYPE=118


# CHAIN PARAMS
BLOCK_TIME='1s'
STRIDE_HOUR_EPOCH_DURATION="90s"
STRIDE_DAY_EPOCH_DURATION="100s"
STRIDE_EPOCH_EPOCH_DURATION="40s"
STRIDE_MINT_EPOCH_DURATION="20s"
HOST_DAY_EPOCH_DURATION="60s"
HOST_HOUR_EPOCH_DURATION="60s"
HOST_WEEK_EPOCH_DURATION="60s"
HOST_MINT_EPOCH_DURATION="60s"
UNBONDING_TIME="120s"
MAX_DEPOSIT_PERIOD="30s"
VOTING_PERIOD="30s"
INITIAL_ANNUAL_PROVISIONS="10000000000000.000000000000000000"


# relayer
RELAYER_STRIDE_ACCT=rly7
RELAYER_STRIDE_MNEMONIC="science depart where tell bus ski laptop follow child bronze rebel recall brief plug razor ship degree labor human series today embody fury harvest"


# Node names will be of the form: "stride1"
node_name="${STRIDE_NODE_PREFIX}"

# Update node networking configuration
config_toml="${STATE}/${node_name}/config/config.toml"
client_toml="${STATE}/${node_name}/config/client.toml"
app_toml="${STATE}/${node_name}/config/app.toml"
genesis_json="${STATE}/${node_name}/config/genesis.json"

DENOM=$STRIDE_DENOM
CHAIN_ID=$STRIDE_CHAIN_ID
RPC_PORT=$STRIDE_RPC_PORT

# Tokens are denominated in the macro-unit
# (e.g. 5000000STRD implies 5000000000000ustrd)
VAL_TOKENS=5000000
STAKE_TOKENS=5000

MICRO_DENOM_UNITS_VAR_NAME=${CHAIN}_MICRO_DENOM_UNITS
MICRO_DENOM_UNITS="${!MICRO_DENOM_UNITS_VAR_NAME:-000000}"
VAL_TOKENS=${VAL_TOKENS}${MICRO_DENOM_UNITS}
STAKE_TOKENS=${STAKE_TOKENS}${MICRO_DENOM_UNITS}

cmd="$STRIDE_BINARY --home ${STATE}/$node_name"

# Moniker is of the form: STRIDE_1
moniker=$(printf "${STRIDE_NODE_PREFIX}" | awk '{ print toupper($0) }')

# Clean from previous run
rm -rf $STATE/$node_name
rm -rf $LOGS/*

mkdir -p $LOGS

# Create a state directory for the current node and initialize the chain
mkdir -p $STATE/$node_name

ls -al

$cmd init $moniker --chain-id $STRIDE_CHAIN_ID --overwrite >> $SETUP_LOGS
chmod -R 777 $STATE/$node_name

sed -i -E "s|cors_allowed_origins = \[\]|cors_allowed_origins = [\"\*\"]|g" $config_toml
sed -i -E "s|127.0.0.1|0.0.0.0|g" $config_toml
sed -i -E "s|timeout_commit = \"5s\"|timeout_commit = \"${BLOCK_TIME}\"|g" $config_toml
sed -i -E "s|prometheus = false|prometheus = true|g" $config_toml

sed -i -E "s|minimum-gas-prices = \".*\"|minimum-gas-prices = \"0${DENOM}\"|g" $app_toml
sed -i -E '/\[api\]/,/^enable = .*$/ s/^enable = .*$/enable = true/' $app_toml
sed -i -E 's|unsafe-cors = .*|unsafe-cors = true|g' $app_toml
sed -i -E "s|snapshot-interval = 0|snapshot-interval = 300|g" $app_toml

sed -i -E "s|chain-id = \"\"|chain-id = \"${CHAIN_ID}\"|g" $client_toml
sed -i -E "s|keyring-backend = \"os\"|keyring-backend = \"test\"|g" $client_toml
sed -i -E "s|node = \".*\"|node = \"tcp://localhost:$RPC_PORT\"|g" $client_toml

sed -i -E "s|\"stake\"|\"${DENOM}\"|g" $genesis_json
sed -i -E "s|\"aphoton\"|\"${DENOM}\"|g" $genesis_json # ethermint default

RELAYER_ACCT=$RELAYER_STRIDE_ACCT
RELAYER_MNEMONIC=$RELAYER_STRIDE_MNEMONIC

echo "$RELAYER_MNEMONIC" | $cmd keys add $RELAYER_ACCT --recover --keyring-backend=test >> $KEYS_LOGS 2>&1
RELAYER_ADDRESS=$($cmd keys show $RELAYER_ACCT --keyring-backend test -a)
$cmd add-genesis-account ${RELAYER_ADDRESS} ${VAL_TOKENS}${DENOM}

# add a validator account
VAL_PREFIX="${STRIDE_VAL_PREFIX}"

val_acct="${VAL_PREFIX}"
val_mnemonic="${VAL_MNEMONIC_1}"
echo "$val_mnemonic" | $cmd keys add $val_acct --recover --keyring-backend=test >> $KEYS_LOGS 2>&1
val_addr=$($cmd keys show $val_acct --keyring-backend test -a | tr -cd '[:alnum:]._-')
# Add this account to the current node
$cmd add-genesis-account ${val_addr} ${VAL_TOKENS}${DENOM}
# actually set this account as a validator on the current node
$cmd gentx $val_acct ${STAKE_TOKENS}${DENOM} --chain-id $CHAIN_ID --keyring-backend test >> $SETUP_LOGS 2>&1

# Cleanup from seds
rm -rf ${client_toml}-E
rm -rf ${genesis_json}-E
rm -rf ${app_toml}-E

# Cleanup from seds
rm -rf ${config_toml}-E
rm -rf ${genesis_json}-E


$cmd collect-gentxs &> /dev/null
$cmd validate-genesis &> /dev/null

$cmd start
