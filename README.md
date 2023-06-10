# Your LOCAL map of zones

## Add accounts

In order to add accounts to the genesis file of each chain for them to be funded, you need to add them to the `./config.sh` file.

## How to run

`docker-compose build`

`docker-compose up -d`

In order to interact with it you can use the following commands:

`strided q bank balances stride1j7uu8nqc9vdstnd3wj0nuasddv90z5ejnucq0k --node http://localhost:26659`

## Ports

### Stride

- Tendermint RPC: 26659
- REST server: 1318

### Evmos
- Tendermint RPC: 26657
- REST server: 1317
- ETH Json RPC: 8545

