# IBC Test

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

create client on chain-a

```bash
# view consensus-state of chain-b
iriscli --home ibc-b/n0/iriscli q ibc client self-consensus-state -o json | jq
# export consensus_state.json from chain-b
iriscli --home ibc-b/n0/iriscli q ibc client self-consensus-state -o json >ibc-a/n0/consensus_state.json
# create client on chain-a
iriscli --home ibc-a/n0/iriscli tx ibc client create client-to-b ibc-a/n0/consensus_state.json --from n0 -y -o text --broadcast-mode=block
```

create client on chain-b

```bash
# view consensus-state of chain-a
iriscli --home ibc-a/n0/iriscli q ibc client self-consensus-state -o json | jq
# export consensus_state.json from chain-a
iriscli --home ibc-a/n0/iriscli q ibc client self-consensus-state -o json >ibc-b/n0/consensus_state.json
# create client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client create client-to-a ibc-b/n0/consensus_state.json --from n1 -y -o text --broadcast-mode=block
```

**Query client**

query client state

```bash
# query client state on chain-a
iriscli --home ibc-a/n0/iriscli q ibc client state client-to-b | jq
# query client state on chain-b
iriscli --home ibc-b/n0/iriscli q ibc client state client-to-a | jq
```

query client consensus-state

```bash
# query client consensus-state on chain-a
iriscli --home ibc-a/n0/iriscli q ibc client consensus-state client-to-b | jq
# query client consensus-state on chain-b
iriscli --home ibc-b/n0/iriscli q ibc client consensus-state client-to-a | jq
```

query client path

```bash
# query client path of chain-a
iriscli --home ibc-a/n0/iriscli q ibc client path | jq
# query client path of chain-b
iriscli --home ibc-b/n0/iriscli q ibc client path | jq
```

**Update client**

update chain-a

```bash
# query header of chain-b
iriscli --home ibc-b/n0/iriscli q ibc client header -o json | jq
# export header of chain-b
iriscli --home ibc-b/n0/iriscli q ibc client header -o json >ibc-a/n0/header.json
# update client on chain-a
iriscli --home ibc-a/n0/iriscli tx ibc client update client-to-b ibc-a/n0/header.json --from n0 -y -o text --broadcast-mode=block
```

update chain-b

```bash
# query header of chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json | jq
# export header of chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json >ibc-b/n0/header.json
# update client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client update client-to-a ibc-b/n0/header.json --from n1 -y -o text --broadcast-mode=block
```

**Create connection**

`open-init` on chain-a

```bash
# export prefix.json
iriscli --home ibc-b/n0/iriscli q ibc client path -o json >ibc-a/n0/prefix.json
# view prefix.json
jq -r '' ibc-a/n0/prefix.json
# open-init
iriscli --home ibc-a/n0/iriscli tx ibc connection open-init \
  conn-to-b client-to-b \
  conn-to-a client-to-a \
  ibc-a/n0/prefix.json \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-try` on chain-b

```bash
# export prefix.json
iriscli --home ibc-a/n0/iriscli q ibc client path -o json >ibc-b/n0/prefix.json
# export header.json from chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json >ibc-b/n0/header.json
# export proof_init.json from chain-a with hight in header.json
iriscli --home ibc-a/n0/iriscli q ibc connection proof conn-to-b $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) -o json >ibc-b/n0/conn/proof_init.json
# view proof_init.json
jq -r '' ibc-b/n0/conn/proof_init.json
# update client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client update client-to-a ibc-b/n0/header.json --from n1 -y -o text --broadcast-mode=block
# open-try
iriscli --home ibc-b/n0/iriscli tx ibc connection open-try \
  conn-to-a client-to-a \
  conn-to-b client-to-b \
  ibc-b/n0/prefix.json \
  1.0.0 \
  ibc-b/n0/conn/proof_init.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  --from n1 -y -o text \
  --broadcast-mode=block
```

`open-ack` on chain-a

```bash
# export header.json from chain-b
iriscli --home ibc-b/n0/iriscli q ibc client header -o json >ibc-a/n0/header.json
# export proof_try.json from chain-b with hight in header.json
iriscli --home ibc-b/n0/iriscli q ibc connection proof conn-to-a $(jq -r '.value.SignedHeader.header.height' ibc-a/n0/header.json) -o json >ibc-a/n0/conn/proof_try.json
# view proof_try.json
jq -r '' ibc-a/n0/conn/proof_try.json
# update client on chain-a
iriscli --home ibc-a/n0/iriscli tx ibc client update client-to-b ibc-a/n0/header.json --from n0 -y -o text --broadcast-mode=block
# open-ack
iriscli --home ibc-a/n0/iriscli tx ibc connection open-ack \
  conn-to-b \
  ibc-a/n0/conn/proof_try.json \
  1.0.0 \
  $(jq -r '.value.SignedHeader.header.height' ibc-a/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-confirm` on chain-b

```bash
# export header.json from chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json >ibc-b/n0/header.json
# export proof_ack.json from chain-a with hight in header.json
iriscli --home ibc-a/n0/iriscli q ibc connection proof conn-to-b $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) -o json >ibc-b/n0/conn/proof_ack.json
# view proof_ack.json
jq -r '' ibc-b/n0/conn/proof_ack.json
# update client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client update client-to-a ibc-b/n0/header.json --from n1 -y -o text --broadcast-mode=block
# open-try
iriscli --home ibc-b/n0/iriscli tx ibc connection open-confirm \
  conn-to-a \
  ibc-b/n0/conn/proof_ack.json \
  --from n1 -y -o text \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  --broadcast-mode=block
```

**Query connection**

query connection

```bash
# query connection on chain-a
iriscli --home ibc-a/n0/iriscli q ibc connection end conn-to-b | jq
# query connection on chain-b
iriscli --home ibc-b/n0/iriscli q ibc connection end conn-to-a | jq
```

query connection proof

```bash
# query connection proof with height in header.json on chain-a
iriscli --home ibc-a/n0/iriscli q ibc connection proof conn-to-b $(jq -r '.value.SignedHeader.header.height' ibc-a/n0/header.json) | jq
# query connection proof with height in header.json on chain-b
iriscli --home ibc-b/n0/iriscli q ibc connection proof conn-to-a $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) | jq
```

query connections of a client

```bash
# query connections of a client on chain-a
iriscli --home ibc-a/n0/iriscli q ibc connection client client-to-b | jq
# query connections of a client on chain-b
iriscli --home ibc-b/n0/iriscli q ibc connection client client-to-a | jq
```

**Create channel**

`open-init` on chain-a

```bash
# open-init
iriscli --home ibc-a/n0/iriscli tx ibc channel open-init \
  port-to-b chann-to-b \
  port-to-a chann-to-a \
  conn-to-a \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-try` on chain-b

```bash
# export header.json from chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json >ibc-b/n0/header.json
# export proof_init.json from chain-a with hight in header.json
iriscli --home ibc-a/n0/iriscli q ibc channel proof port-to-b chann-to-b $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) -o json >ibc-b/n0/chann/proof_init.json
# view proof_init.json
jq -r '' ibc-b/n0/chann/proof_init.json
# update client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client update client-to-a ibc-b/n0/header.json --from n1 -y -o text --broadcast-mode=block
# open-try
iriscli --home ibc-b/n0/iriscli tx ibc channel open-try \
  port-to-b chann-to-a \
  port-to-a chann-to-b \
  conn-to-b \
  ibc-b/n0/chann/proof_init.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  --from n1 -y -o text \
  --broadcast-mode=block
```

`open-ack` on chain-a

```bash
# export header.json from chain-b
iriscli --home ibc-b/n0/iriscli q ibc client header -o json >ibc-a/n0/header.json
# export proof_try.json from chain-b with hight in header.json
iriscli --home ibc-b/n0/iriscli q ibc channel proof port-to-a chann-to-a $(jq -r '.value.SignedHeader.header.height' ibc-a/n0/header.json) -o json >ibc-a/n0/chann/proof_try.json
# view proof_try.json
jq -r '' ibc-a/n0/chann/proof_try.json
# update client on chain-a
iriscli --home ibc-a/n0/iriscli tx ibc client update client-to-b ibc-a/n0/header.json --from n0 -y -o text --broadcast-mode=block
# open-ack
iriscli --home ibc-a/n0/iriscli tx ibc channel open-ack \
  port-to-b chann-to-b \
  ibc-a/n0/chann/proof_try.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-a/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-confirm` on chain-b

```bash
# export header.json from chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json >ibc-b/n0/header.json
# export proof_ack.json from chain-a with hight in header.json
iriscli --home ibc-a/n0/iriscli q ibc channel proof port-to-b chann-to-b $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) -o json >ibc-b/n0/chann/proof_ack.json
# view proof_ack.json
jq -r '' ibc-b/n0/chann/proof_ack.json
# update client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client update client-to-a ibc-b/n0/header.json --from n1 -y -o text --broadcast-mode=block
# open-confirm
iriscli --home ibc-b/n0/iriscli tx ibc channel open-confirm \
  port-to-a chann-to-a \
  ibc-b/n0/chann/proof_ack.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  --from n1 -y -o text \
  --broadcast-mode=block
```

**Query channel**

query channel

```bash
# query channel on chain-a
iriscli --home ibc-a/n0/iriscli query ibc channel end port-to-b chann-to-b | jq
# query channel on chain-b
iriscli --home ibc-b/n0/iriscli query ibc channel end port-to-a chann-to-a | jq
```

query channel proof

```bash
# query channel proof with height in header.json on chain-a
iriscli --home ibc-a/n0/iriscli q ibc channel proof port-to-b chann-to-b $(jq -r '.value.SignedHeader.header.height' ibc-a/n0/header.json) | jq
# query channel proof with height in header.json on chain-b
iriscli --home ibc-b/n0/iriscli q ibc channel proof port-to-a chann-to-a $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) | jq
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

**Receive packet `(not implemented)`**

```bash
iriscli --home ibc-a/n0/iriscli tx ibc channel send-packet [...]
```
