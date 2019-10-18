# Test

**Use local `cosmos-sdk` for test**

```bash
# go.mod
replace github.com/cosmos/cosmos-sdk => /path-to-your-local/cosmos-sdk
```

**Environment setup**

```bash
cd ~ && mkdir ibc-testnets && cd ibc-testnets
iris testnet -o ibc-a --v 1 --chain-id chain-a --node-dir-prefix n
iris testnet -o ibc-b --v 1 --chain-id chain-b --node-dir-prefix n
```

**Set configuration**

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

**Set Keys**

```bash
# copy mnemonic
# jq -r '.secret' ibc-a/n0/iriscli/key_seed.json | pbcopy
# jq -r '.secret' ibc-b/n0/iriscli/key_seed.json | pbcopy

# Remove the key n0 on iris
iriscli --home ibc-b/n0/iriscli keys delete n0

# copy mnemonic
jq -r '.secret' ibc-b/n0/iriscli/key_seed.json | pbcopy
# seed from ibc-b/n0/iriscli/key_seed.json -> ibc-a/n1
iriscli --home ibc-a/n0/iriscli keys add n1 --recover

# copy mnemonic
jq -r '.secret' ibc-a/n0/iriscli/key_seed.json | pbcopy
# seed from ibc-a/n0/iriscli/key_seed.json -> ibc-b/n0
iriscli --home ibc-b/n0/iriscli keys add n0 --recover

# copy mnemonic
jq -r '.secret' ibc-b/n0/iriscli/key_seed.json | pbcopy
# seed from ibc-b/n0/iriscli/key_seed.json -> ibc-b/n1
iriscli --home ibc-b/n0/iriscli keys add n1 --recover

# Ensure keys match
iriscli --home ibc-a/n0/iriscli keys list | jq '.[].address'
iriscli --home ibc-b/n0/iriscli keys list | jq '.[].address'
```

**Start**

```bash
# run in background
nohup iris --home ibc-a/n0/iris start >ibc-a.log &
nohup iris --home ibc-b/n0/iris start >ibc-b.log &

# run in terminal
iris --home ibc-a/n0/iris start
iris --home ibc-b/n0/iris start
```

**Create client**

```bash
iriscli --home ibc-b/n0/iriscli q ibc client consensus-state-init -o json | jq
iriscli --home ibc-b/n0/iriscli q ibc client consensus-state-init -o json >ibc-a/n0/consensus_state.json
iriscli --home ibc-a/n0/iriscli tx ibc client create client-to-b ibc-a/n0/consensus_state.json --from n0 -y -o text

iriscli --home ibc-a/n0/iriscli q ibc client consensus-state-init -o json | jq
iriscli --home ibc-a/n0/iriscli q ibc client consensus-state-init -o json >ibc-b/n0/consensus_state.json
iriscli --home ibc-b/n0/iriscli tx ibc client create client-to-a ibc-b/n0/consensus_state.json --from n1 -y -o text

iriscli --home ibc-a/n0/iriscli q ibc client state client-to-b | jq
iriscli --home ibc-b/n0/iriscli q ibc client state client-to-a | jq

iriscli --home ibc-a/n0/iriscli q ibc client consensus-state client-to-b | jq
iriscli --home ibc-b/n0/iriscli q ibc client consensus-state client-to-a | jq
```

**Update client**

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

**Create connection**

```bash
# TODO: update chain-a first
iriscli --home ibc-b/n0/iriscli q ibc client path | jq
iriscli --home ibc-b/n0/iriscli q ibc client path -o json >ibc-a/n0/prefix.json
iriscli --home ibc-a/n0/iriscli tx ibc connection open-init \
  conn-to-b client-to-b \
  conn-to-a client-to-a \
  ibc-a/n0/prefix.json \
  --from n0 -y -o text

# TODO: update chain-b first
iriscli --home ibc-a/n0/iriscli q ibc client path | jq
iriscli --home ibc-a/n0/iriscli q ibc client path -o json >ibc-b/n0/prefix.json
iriscli --home ibc-b/n0/iriscli tx ibc connection open-try \
  conn-to-a client-to-a \
  conn-to-b client-to-b \
  ibc-b/n0/prefix.json 1.0.0 \
  [path/to/proof_init.json] \
  --from n1 -y -o text

# TODO: update chain-a first
iriscli --home ibc-a/n0/iriscli tx ibc connection open-ack \
  conn-to-b [path/to/proof_try.json] 1.0.0 \
  --from n0 -y -o text

# TODO: update chain-b first
iriscli --home ibc-b/n0/iriscli tx ibc connection open-confirm \
  conn-to-a [path/to/proof_ack.json] \
  --from n1 -y -o text
```

**Query connection**

```bash
iriscli --home ibc-a/n0/iriscli q ibc connection end conn-to-b | jq
iriscli --home ibc-b/n0/iriscli q ibc connection end conn-to-a | jq

iriscli --home ibc-a/n0/iriscli q ibc connection client client-to-b | jq
iriscli --home ibc-b/n0/iriscli q ibc connection client client-to-a | jq
```

**Create channel**

```bash
# TODO: update chain-a first
iriscli --home ibc-a/n0/iriscli tx ibc channel open-init \
  port-to-b chann-to-b \
  port-to-a chann-to-a \
  conn-to-a

# TODO: update chain-b first
iriscli --home ibc-b/n0/iriscli tx ibc channel open-try \
  port-to-b chann-to-a \
  port-to-a chann-to-b \
  conn-to-b \
  [/path/to/proof-init.json] \
  [proof-height]

# TODO: update chain-a first
iriscli --home ibc-a/n0/iriscli tx ibc channel open-ack \
  port-to-b chann-to-b \
  [/path/to/proof-try.json] \
  [proof-height]

# TODO: update chain-b first
iriscli --home ibc-b/n0/iriscli tx ibc channel open-confirm \
  port-to-a chann-to-a \
  [/path/to/proof-ack.json] \
  [proof-height]
```

**Query channel**

```bash
iriscli --home ibc-a/n0/iriscli query ibc channel end port-to-b chann-to-b | jq
iriscli --home ibc-b/n0/iriscli query ibc channel end port-to-a chann-to-a | jq
```

**Bank transfer from chain-a to chain-b**

```bash
# generate packet to chain-a
iriscli --home ibc-a/n0/iriscli tx ibc bank transfer [...]
```

**Bank receive**

> use "tx ibc channel send-packet" instead when router-module completed in the future

```bash
# TODO: update chain-b first
iriscli --home ibc-b/n0/iriscli tx ibc bank transfer [...] [...]
```

**Deliver packet `(not implemented)`**

```bash
iriscli --home ibc-a/n0/iriscli tx ibc channel send-packet [...]
```
