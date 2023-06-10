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
KEYS_LOGS=$DOCKERNET_HOME/logs/keys.log
SETUP_LOGS=$DOCKERNET_HOME/logs/setup.log
CHAIN="evmos"
# DENOMS
STRD_DENOM="aevmos"
# set denom based on chain
# Config
EVMOS_CHAIN_ID=evmos_9001-2
EVMOS_NODE_PREFIX=evmos
EVMOS_VAL_PREFIX=val
EVMOS_ADDRESS_PREFIX=evmos
EVMOS_DENOM=$STRD_DENOM
EVMOS_RPC_PORT=26657
EVMOS_ADMIN_ACCT=admin
EVMOS_ADMIN_ADDRESS=evmos1u20df3trc2c2zdhm8qvh2hdjx9ewh00sv6eyy8
EVMOS_ADMIN_MNEMONIC="tone cause tribe this switch near host damage idle fragile antique tail soda alien depth write wool they rapid unfold body scan pledge soft"
EVMOS_FEE_ADDRESS=evmos1czvrk3jkvtj8m27kqsqu2yrkhw3h3ykwj3rxh6

VAL_MNEMONIC_1="close soup mirror crew erode defy knock trigger gather eyebrow tent farm gym gloom base lemon sleep weekend rich forget diagram hurt prize fly"

# binaries
EVMOS_BINARY="$DOCKERNET_HOME/evmosd"

# COIN TYPES
# Coin types can be found at https://github.com/satoshilabs/slips/blob/master/slip-0044.md
COSMOS_COIN_TYPE=118


# CHAIN PARAMS
BLOCK_TIME='1s'
EVMOS_HOUR_EPOCH_DURATION="90s"
EVMOS_DAY_EPOCH_DURATION="100s"
EVMOS_EPOCH_EPOCH_DURATION="40s"
EVMOS_MINT_EPOCH_DURATION="20s"
HOST_DAY_EPOCH_DURATION="60s"
HOST_HOUR_EPOCH_DURATION="60s"
HOST_WEEK_EPOCH_DURATION="60s"
HOST_MINT_EPOCH_DURATION="60s"
UNBONDING_TIME="120s"
MAX_DEPOSIT_PERIOD="30s"
VOTING_PERIOD="30s"
INITIAL_ANNUAL_PROVISIONS="10000000000000.000000000000000000"


# relayer
RELAYER_EVMOS_ACCT=rly7
RELAYER_EVMOS_MNEMONIC="science depart where tell bus ski laptop follow child bronze rebel recall brief plug razor ship degree labor human series today embody fury harvest"


# Node names will be of the form: "evmos1"
node_name="${EVMOS_NODE_PREFIX}"

# Update node networking configuration
config_toml="${STATE}/${node_name}/config/config.toml"
client_toml="${STATE}/${node_name}/config/client.toml"
app_toml="${STATE}/${node_name}/config/app.toml"
genesis_json="${STATE}/${node_name}/config/genesis.json"

DENOM=$EVMOS_DENOM
CHAIN_ID=$EVMOS_CHAIN_ID
RPC_PORT=$EVMOS_RPC_PORT

# Tokens are denominated in the macro-unit
# (e.g. 5000000STRD implies 5000000000000ustrd)
VAL_TOKENS=100000000000000000000000000000000
STAKE_TOKENS=1000000000000000000

MICRO_DENOM_UNITS_VAR_NAME=${CHAIN}_MICRO_DENOM_UNITS
MICRO_DENOM_UNITS="${!MICRO_DENOM_UNITS_VAR_NAME:-000000000000000000}"
VAL_TOKENS=${VAL_TOKENS}${MICRO_DENOM_UNITS}
STAKE_TOKENS=${STAKE_TOKENS}${MICRO_DENOM_UNITS}

# Dev funding
DEV_ADDR_1="evmos1q7dfkza5zclyjlfu55dcsfd7cvqtjmh97eudnm"
DEV_ADDRS=("$DEV_ADDR_1")

DEV_AMOUNT=5000000
DEV_AMOUNT=${DEV_AMOUNT}${MICRO_DENOM_UNITS}


cmd="$EVMOS_BINARY --home ${STATE}/$node_name"

# Moniker is of the form: EVMOS_1
moniker=$(printf "${EVMOS_NODE_PREFIX}" | awk '{ print toupper($0) }')

# Clean from previous run
rm -rf $STATE/$node_name
rm -rf $LOGS/*

mkdir -p $LOGS

# Create a state directory for the current node and initialize the chain
mkdir -p $STATE/$node_name

$cmd init $moniker --chain-id $CHAIN_ID --overwrite >> $SETUP_LOGS
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

RELAYER_ACCT=$RELAYER_EVMOS_ACCT
RELAYER_MNEMONIC=$RELAYER_EVMOS_MNEMONIC

echo "$RELAYER_MNEMONIC" | $cmd keys add $RELAYER_ACCT --recover --keyring-backend=test >> $KEYS_LOGS 2>&1
RELAYER_ADDRESS=$($cmd keys show $RELAYER_ACCT --keyring-backend test -a)
$cmd add-genesis-account ${RELAYER_ADDRESS} ${VAL_TOKENS}${DENOM}

# add a validator account
VAL_PREFIX="${EVMOS_VAL_PREFIX}"

val_acct="${VAL_PREFIX}"
val_mnemonic="${VAL_MNEMONIC_1}"
echo "$val_mnemonic" | $cmd keys add $val_acct --recover --keyring-backend=test >> $KEYS_LOGS 2>&1
val_addr=$($cmd keys show $val_acct --keyring-backend test -a | tr -cd '[:alnum:]._-')
# Add this account to the current node
$cmd add-genesis-account ${val_addr} ${VAL_TOKENS}${DENOM}

# add dev addresses
# iterate over dev addresses
for dev_addr in "${DEV_ADDRS[@]}"; do
    $cmd add-genesis-account ${dev_addr} ${DEV_AMOUNT}${DENOM}
done

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
