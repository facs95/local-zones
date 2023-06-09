global:
  api-listen-addr: :5183
  timeout: 10s
  memo: ""
  light-cache-size: 20
chains:
  stride:
    type: cosmos
    value:
      key: rly1
      chain-id: STRIDE
      rpc-addr: http://stride1:26657
      account-prefix: stride
      keyring-backend: test
      gas-adjustment: 1.3
      gas-prices: 0.01ustrd
      coin-type: 118
      debug: false
      timeout: 20s
      output-format: json
      sign-mode: direct
  evmos:
    type: cosmos
    value:
      key: rly7
      chain-id: evmos_9001-1
      rpc-addr: http://evmos1:26657
      account-prefix: evmos
      keyring-backend: test
      gas-adjustment: 1.2
      gas-prices: 0.01aevmos
      coin-type: 60
      debug: false
      timeout: 20s
      output-format: json
      sign-mode: direct
      extra-codecs:
        - ethermint
  # {new-host-zone}:
  #   type: cosmos
  #   value:
  #     key: rly{N}
  #     chain-id: {CHAIN_ID}
  #     rpc-addr: http://{node_prefix}1:26657
  #     account-prefix: {bech32_hrp_account_prefix}
  #     keyring-backend: test
  #     gas-adjustment: 1.2
  #     gas-prices: 0.01{minimal_denom}
  #     coin-type: {coin-type}
  #     debug: false
  #     timeout: 20s
  #     output-format: json
  #     sign-mode: direct

paths:
  stride-evmos:
    src:
      chain-id: STRIDE
    dst:
      chain-id: evmos_9001-2
    src-channel-filter:
      rule: ""
      channel-list: []

