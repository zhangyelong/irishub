# Test

use local `cosmos-sdk` for test

```bash
# go.mod
replace github.com/cosmos/cosmos-sdk => /path-to-your-local/cosmos-sdk-iris
```

environment setup

```bash
cd ~ && mkdir ibc-testnets && cd ibc-testnets
iris testnet -o ibc-a --v 1 --chain-id chain-a --node-dir-prefix n
iris testnet -o ibc-b --v 1 --chain-id chain-b --node-dir-prefix n
```

configuration

```bash
sed -i '' 's/"leveldb"/"goleveldb"/g' ibc-a/n0/iris/config/config.toml
sed -i '' 's/"leveldb"/"goleveldb"/g' ibc-b/n0/iris/config/config.toml
sed -i '' 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:26556"#g' ibc-b/n0/iris/config/config.toml
sed -i '' 's#"tcp://0.0.0.0:26657"#"tcp://0.0.0.0:26557"#g' ibc-b/n0/iris/config/config.toml
sed -i '' 's#"localhost:6060"#"localhost:6061"#g' ibc-b/n0/iris/config/config.toml
sed -i '' 's#"tcp://127.0.0.1:26658"#"tcp://127.0.0.1:26558"#g' ibc-b/n0/iris/config/config.toml

iriscli config --home ibc-a/n0/iriscli/ chain-id chain-a
iriscli config --home ibc-b/n0/iriscli/ chain-id chain-b
iriscli config --home ibc-a/n0/iriscli/ output json
iriscli config --home ibc-b/n0/iriscli/ output json
iriscli config --home ibc-a/n0/iriscli/ node http://localhost:26657
iriscli config --home ibc-b/n0/iriscli/ node http://localhost:26557
```

keys

```bash
jq -r '.secret' ibc-a/n0/iriscli/key_seed.json | pbcopy
jq -r '.secret' ibc-b/n0/iriscli/key_seed.json | pbcopy

# Remove the key n0 on iris
iriscli --home ibc-b/n0/iriscli keys delete n0

# seed from ibc-b/n0/iriscli/key_seed.json -> ibc-a/n1
iriscli --home ibc-a/n0/iriscli keys add n1 --recover

# seed from ibc-a/n0/iriscli/key_seed.json -> ibc-b/n0
iriscli --home ibc-b/n0/iriscli keys add n0 --recover

# seed from ibc-b/n0/iriscli/key_seed.json -> ibc-b/n1
iriscli --home ibc-b/n0/iriscli keys add n1 --recover

# Ensure keys match
iriscli --home ibc-a/n0/iriscli keys list | jq '.[].address'
iriscli --home ibc-b/n0/iriscli keys list | jq '.[].address'
```

start

```bash
nohup iris --home ibc-a/n0/iris start >ibc-a.log &
nohup iris --home ibc-b/n0/iris start >ibc-b.log &

iris --home ibc-a/n0/iris start
iris --home ibc-b/n0/iris start
```

create client

```bash
iriscli --home ibc-b/n0/iriscli q ibc client consensus-state-init -o json | jq
iriscli --home ibc-b/n0/iriscli q ibc client consensus-state-init -o json >ibc-a/n0/consensus_state.json
iriscli --home ibc-a/n0/iriscli tx ibc client create client-to-b ibc-a/n0/consensus_state.json --from n0 -y -o text

iriscli --home ibc-a/n0/iriscli q ibc client consensus-state-init -o json | jq
iriscli --home ibc-a/n0/iriscli q ibc client consensus-state-init -o json >ibc-b/n0/consensus_state.json
iriscli --home ibc-b/n0/iriscli tx ibc client create client-to-a ibc-b/n0/consensus_state.json --from n1 -y -o text

iriscli --home ibc-a/n0/iriscli q ibc client state client-to-b | jq
iriscli --home ibc-b/n0/iriscli q ibc client state client-to-a | jq

iriscli --home ibc-a/n0/iriscli q ibc client consensus-state client-to-b
iriscli --home ibc-b/n0/iriscli q ibc client consensus-state client-to-a
```

ppdate client

```bash
# update chain-a
iriscli --home ibc-b/n0/iriscli q ibc client header -o json | jq
iriscli --home ibc-b/n0/iriscli q ibc client header -o json >ibc-a/n0/header.json
iriscli --home ibc-a/n0/iriscli tx ibc client update client-to-b ibc-a/n0/header.json --from n0 -y -o text

# update chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json | jq
iriscli --home ibc-a/n0/iriscli q ibc client header -o json >ibc-b/n0/header.json
iriscli --home ibc-b/n0/iriscli tx ibc client update client-to-a ibc-b/n0/header.json --from n1 -y -o text
```

create connection

```bash
# TODO: update chain-a first
iriscli --home ibc-a/n0/iriscli tx ibc connection open-init \
  [connection-id] [client-id] \
  [counterparty-connection-id] [counterparty-client-id] \
  [path/to/counterparty_prefix.json]

# TODO: update chain-b first
iriscli --home ibc-b/n0/iriscli tx ibc connection open-try \
  [connection-id] [client-id] \
  [counterparty-connection-id] [counterparty-client-id] \
  [path/to/counterparty_prefix.json] [counterparty-versions] \
  [path/to/proof_init.json]

# TODO: update chain-a first
iriscli --home ibc-a/n0/iriscli tx ibc connection open-ack \
  [connection-id] [path/to/proof_try.json] [version]

# TODO: update chain-b first
iriscli --home ibc-b/n0/iriscli tx ibc connection open-confirm \
  [connection-id] [path/to/proof_ack.json]
```

query connection

```bash
iriscli --home ibc-a/n0/iriscli q ibc connection end [connection-id]
iriscli --home ibc-b/n0/iriscli q ibc connection end [connection-id]

iriscli --home ibc-a/n0/iriscli q ibc connection client [client-id]
iriscli --home ibc-b/n0/iriscli q ibc connection client [client-id]
```

create channel

```bash
# TODO: update chain-a first
iriscli --home ibc-a/n0/iriscli tx ibc channel open-init \
  [port-id] [channel-id] \
  [counterparty-port-id] [counterparty-channel-id] \
  [connection-hops]

# TODO: update chain-b first
iriscli --home ibc-b/n0/iriscli tx ibc channel open-try \
  [port-id] [channel-id] \
  [counterparty-port-id] [counterparty-channel-id] \
  [connection-hops] [/path/to/proof-init.json] [proof-height]

# TODO: update chain-a first
iriscli --home ibc-a/n0/iriscli tx ibc channel open-ack \
  [port-id] [channel-id] [/path/to/proof-try.json] [proof-height]

# TODO: update chain-b first
iriscli --home ibc-b/n0/iriscli tx ibc channel open-confirm \
  [port-id] [channel-id] [/path/to/proof-ack.json] [proof-height]
```

query channel

```bash
iriscli --home ibc-a/n0/iriscli query ibc channel end [port-id] [channel-id]
iriscli --home ibc-b/n0/iriscli query ibc channel end [port-id] [channel-id]
```

bank transfer

```bash
iriscli --home ibc-a/n0/iriscli tx ibc bank transfer [...]
```

bank receive

```bash
iriscli --home ibc-a/n0/iriscli tx ibc bank transfer [...] [...]
# use `channel send-packet` instead when router-module completed
# iriscli --home ibc-a/n0/iriscli tx ibc channel send-packet [...]
```
