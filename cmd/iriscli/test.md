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

**View Keys**

```bash
# view keys
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
iriscli --home ibc-a/n0/iriscli tx ibc client create client-to-b ibc-a/n0/consensus_state.json \
  --from n0 -y -o text --broadcast-mode=block
```

create client on chain-b

```bash
# view consensus-state of chain-a
iriscli --home ibc-a/n0/iriscli q ibc client self-consensus-state -o json | jq
# export consensus_state.json from chain-a
iriscli --home ibc-a/n0/iriscli q ibc client self-consensus-state -o json >ibc-b/n0/consensus_state.json
# create client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client create client-to-a ibc-b/n0/consensus_state.json \
  --from n0 -y -o text --broadcast-mode=block
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
iriscli --home ibc-a/n0/iriscli tx ibc client update client-to-b ibc-a/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
```

update chain-b

```bash
# query header of chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json | jq
# export header of chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json >ibc-b/n0/header.json
# update client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client update client-to-a ibc-b/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
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
iriscli --home ibc-a/n0/iriscli q ibc connection proof conn-to-b \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  -o json >ibc-b/n0/conn_proof_init.json
# view proof_init.json
jq -r '' ibc-b/n0/conn_proof_init.json
# update client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client update client-to-a ibc-b/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# query client consense state
iriscli --home ibc-b/n0/iriscli q ibc client consensus-state client-to-a | jq
# open-try
iriscli --home ibc-b/n0/iriscli tx ibc connection open-try \
  conn-to-a client-to-a \
  conn-to-b client-to-b \
  ibc-b/n0/prefix.json \
  1.0.0 \
  ibc-b/n0/conn_proof_init.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-ack` on chain-a

```bash
# export header.json from chain-b
iriscli --home ibc-b/n0/iriscli q ibc client header -o json >ibc-a/n0/header.json
# export proof_try.json from chain-b with hight in header.json
iriscli --home ibc-b/n0/iriscli q ibc connection proof conn-to-a \
  $(jq -r '.value.SignedHeader.header.height' ibc-a/n0/header.json) \
  -o json >ibc-a/n0/conn_proof_try.json
# view proof_try.json
jq -r '' ibc-a/n0/conn_proof_try.json
# update client on chain-a
iriscli --home ibc-a/n0/iriscli tx ibc client update client-to-b ibc-a/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# query client consense state
iriscli --home ibc-a/n0/iriscli q ibc client consensus-state client-to-b | jq
# open-ack
iriscli --home ibc-a/n0/iriscli tx ibc connection open-ack \
  conn-to-b \
  ibc-a/n0/conn_proof_try.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-a/n0/header.json) \
  1.0.0 \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-confirm` on chain-b

```bash
# export header.json from chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json >ibc-b/n0/header.json
# export proof_ack.json from chain-a with hight in header.json
iriscli --home ibc-a/n0/iriscli q ibc connection proof conn-to-b \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  -o json >ibc-b/n0/conn_proof_ack.json
# view proof_ack.json
jq -r '' ibc-b/n0/conn_proof_ack.json
# update client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client update client-to-a ibc-b/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# open-confirm
iriscli --home ibc-b/n0/iriscli tx ibc connection open-confirm \
  conn-to-a \
  ibc-b/n0/conn_proof_ack.json \
  --from n0 -y -o text \
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
iriscli --home ibc-a/n0/iriscli q ibc connection proof conn-to-b \
  $(jq -r '.value.SignedHeader.header.height' ibc-a/n0/header.json) | jq
# query connection proof with height in header.json on chain-b
iriscli --home ibc-b/n0/iriscli q ibc connection proof conn-to-a \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) | jq
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
  port-to-bank chann-to-b \
  port-to-bank chann-to-a \
  conn-to-b \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-try` on chain-b

```bash
# export header.json from chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json >ibc-b/n0/header.json
# export proof_init.json from chain-a with hight in header.json
iriscli --home ibc-a/n0/iriscli q ibc channel proof port-to-bank chann-to-b \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  -o json >ibc-b/n0/chann_proof_init.json
# view proof_init.json
jq -r '' ibc-b/n0/chann_proof_init.json
# update client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client update client-to-a ibc-b/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# query client consense state
iriscli --home ibc-b/n0/iriscli q ibc client consensus-state client-to-a | jq
# open-try
iriscli --home ibc-b/n0/iriscli tx ibc channel open-try \
  port-to-bank chann-to-a \
  port-to-bank chann-to-b \
  conn-to-a \
  ibc-b/n0/chann_proof_init.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-ack` on chain-a

```bash
# export header.json from chain-b
iriscli --home ibc-b/n0/iriscli q ibc client header -o json >ibc-a/n0/header.json
# export proof_try.json from chain-b with hight in header.json
iriscli --home ibc-b/n0/iriscli q ibc channel proof port-to-bank chann-to-a \
  $(jq -r '.value.SignedHeader.header.height' ibc-a/n0/header.json) \
  -o json >ibc-a/n0/chann_proof_try.json
# view proof_try.json
jq -r '' ibc-a/n0/chann_proof_try.json
# update client on chain-a
iriscli --home ibc-a/n0/iriscli tx ibc client update client-to-b ibc-a/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# query client consense state
iriscli --home ibc-a/n0/iriscli q ibc client consensus-state client-to-b | jq
# open-ack
iriscli --home ibc-a/n0/iriscli tx ibc channel open-ack \
  port-to-bank chann-to-b \
  ibc-a/n0/chann_proof_try.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-a/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-confirm` on chain-b

```bash
# export header.json from chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json >ibc-b/n0/header.json
# export proof_ack.json from chain-a with hight in header.json
iriscli --home ibc-a/n0/iriscli q ibc channel proof port-to-bank chann-to-b \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  -o json >ibc-b/n0/chann_proof_ack.json
# view proof_ack.json
jq -r '' ibc-b/n0/chann_proof_ack.json
# update client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client update client-to-a ibc-b/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# query client consense state
iriscli --home ibc-b/n0/iriscli q ibc client consensus-state client-to-a | jq
# open-confirm
iriscli --home ibc-b/n0/iriscli tx ibc channel open-confirm \
  port-to-bank chann-to-a \
  ibc-b/n0/chann_proof_ack.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

**Query channel**

query channel

```bash
# query channel on chain-a
iriscli --home ibc-a/n0/iriscli query ibc channel end port-to-bank chann-to-b | jq
# query channel on chain-b
iriscli --home ibc-b/n0/iriscli query ibc channel end port-to-bank chann-to-a | jq
```

query channel proof

```bash
# query channel proof with height in header.json on chain-a
iriscli --home ibc-a/n0/iriscli q ibc channel proof port-to-bank chann-to-b \
  $(jq -r '.value.SignedHeader.header.height' ibc-a/n0/header.json) | jq
# query channel proof with height in header.json on chain-b
iriscli --home ibc-b/n0/iriscli q ibc channel proof port-to-bank chann-to-a \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) | jq
```

**Bank transfer from chain-a to chain-b**

```bash
# export transfer result to result.json
iriscli --home ibc-a/n0/iriscli tx ibcmockbank transfer \
  --src-port port-to-bank --src-channel chann-to-b \
  --denom uiris --amount 1 \
  --receiver $(iriscli --home ibc-b/n0/iriscli keys show n0 | jq -r '.address') \
  --source true \
  --from n0 -y -o json > ibc-a/n0/result.json
# export packet.json
jq -r '.events[1].attributes[2].value' ibc-a/n0/result.json >ibc-b/n0/packet.json
```

**Bank receive**

> use "tx ibc channel send-packet" instead when router-module completed in the future

```bash
# export header.json from chain-a
iriscli --home ibc-a/n0/iriscli q ibc client header -o json >ibc-b/n0/header.json
# export proof.json from chain-b with hight in header.json
iriscli --home ibc-a/n0/iriscli q ibc channel proof port-to-bank chann-to-b \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  -o json >ibc-b/n0/proof.json
# view proof.json
jq -r '' ibc-b/n0/proof.json
# update client on chain-b
iriscli --home ibc-b/n0/iriscli tx ibc client update client-to-a ibc-b/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# receive packet
iriscli --home ibc-b/n0/iriscli tx ibcmockbank recv-packet \
  ibc-b/n0/packet.json ibc-b/n0/proof.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-b/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

**Query Account**

```bash
# view sender account
iriscli --home ibc-a/n0/iriscli q account -o text \
  $(iriscli --home ibc-a/n0/iriscli keys show n0 | jq -r '.address')
# view receiver account
iriscli --home ibc-b/n0/iriscli q account -o text \
  $(iriscli --home ibc-b/n0/iriscli keys show n0 | jq -r '.address')
```
