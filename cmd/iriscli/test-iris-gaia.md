# IBC Test

**Install `iris`**

```bash
git clone https://github.com/irisnet/irishub.git
cd irishub
git checkout cosmos-sdk
go mod tidy
make install
iris version
iriscli version
```

**Install `gaia`**

```bash
git clone https://github.com/irisnet/gaia.git
cd gaia
git checkout ibc-gaia-mockbank
go mod tidy
make install
gaiad version
gaiacli version
```

**Environment setup**

```bash
cd ~ && mkdir ibc-testnets && cd ibc-testnets
iris testnet -o ibc-iris --v 1 --chain-id iris --node-dir-prefix n
gaiad testnet -o ibc-gaia --v 1 --chain-id cosmos --node-dir-prefix n
```

**Set configuration**

```bash
sed -i '' 's/"leveldb"/"goleveldb"/g' ibc-iris/n0/iris/config/config.toml
sed -i '' 's/"leveldb"/"goleveldb"/g' ibc-gaia/n0/gaiad/config/config.toml
sed -i '' 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:26556"#g' ibc-gaia/n0/gaiad/config/config.toml
sed -i '' 's#"tcp://0.0.0.0:26657"#"tcp://0.0.0.0:26557"#g' ibc-gaia/n0/gaiad/config/config.toml
sed -i '' 's#"localhost:6060"#"localhost:6061"#g' ibc-gaia/n0/gaiad/config/config.toml
sed -i '' 's#"tcp://127.0.0.1:26658"#"tcp://127.0.0.1:26558"#g' ibc-gaia/n0/gaiad/config/config.toml

sed -i '' 's/n0token/uiris/' ibc-iris/n0/iris/config/genesis.json
sed -i '' 's/n0token/uatom/' ibc-gaia/n0/gaiad/config/genesis.json

iriscli config --home ibc-iris/n0/iriscli/ chain-id iris
gaiacli config --home ibc-gaia/n0/gaiacli/ chain-id cosmos
iriscli config --home ibc-iris/n0/iriscli/ output json
gaiacli config --home ibc-gaia/n0/gaiacli/ output json
iriscli config --home ibc-iris/n0/iriscli/ node http://localhost:26657
gaiacli config --home ibc-gaia/n0/gaiacli/ node http://localhost:26557
```

**View Keys**

```bash
iriscli --home ibc-iris/n0/iriscli keys list | jq '.[].address'
gaiacli --home ibc-gaia/n0/gaiacli keys list | jq '.[].address'
```

**Start**

```bash
# run in background
nohup iris --home ibc-iris/n0/iris start >ibc-iris.log &
nohup gaiad --home ibc-gaia/n0/gaiad start >ibc-gaia.log &

# run in terminal
iris --home ibc-iris/n0/iris start
gaiad --home ibc-gaia/n0/gaiad start
```

**Create client**

create client on iris

```bash
# view consensus-state of cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc client self-consensus-state -o json | jq
# export consensus_state.json from cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc client self-consensus-state -o json >ibc-iris/n0/consensus_state.json
# create client on iris
iriscli --home ibc-iris/n0/iriscli tx ibc client create client-to-gaia ibc-iris/n0/consensus_state.json \
  --from n0 -y -o text --broadcast-mode=block
```

create client on cosmos

```bash
# view consensus-state of iris
iriscli --home ibc-iris/n0/iriscli q ibc client self-consensus-state -o json | jq
# export consensus_state.json from iris
iriscli --home ibc-iris/n0/iriscli q ibc client self-consensus-state -o json >ibc-gaia/n0/consensus_state.json
# create client on cosmos
gaiacli --home ibc-gaia/n0/gaiacli tx ibc client create client-to-iris ibc-gaia/n0/consensus_state.json \
  --from n0 -y -o text --broadcast-mode=block
```

**Query client**

query client state

```bash
# query client state on iris
iriscli --home ibc-iris/n0/iriscli q ibc client state client-to-gaia | jq
# query client state on cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc client state client-to-iris | jq
```

query client consensus-state

```bash
# query client consensus-state on iris
iriscli --home ibc-iris/n0/iriscli q ibc client consensus-state client-to-gaia | jq
# query client consensus-state on cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc client consensus-state client-to-iris | jq
```

query client path

```bash
# query client path of iris
iriscli --home ibc-iris/n0/iriscli q ibc client path | jq
# query client path of cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc client path | jq
```

**Update client**

update iris

```bash
# query header of cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc client header -o json | jq
# export header of cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc client header -o json >ibc-iris/n0/header.json
# update client on iris
iriscli --home ibc-iris/n0/iriscli tx ibc client update client-to-gaia ibc-iris/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
```

update cosmos

```bash
# query header of iris
iriscli --home ibc-iris/n0/iriscli q ibc client header -o json | jq
# export header of iris
iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
# update client on cosmos
gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
```

**Create connection**

`open-init` on iris

```bash
# open-init
iriscli --home ibc-iris/n0/iriscli tx ibc connection open-init \
  conn-to-gaia client-to-gaia \
  conn-to-iris client-to-iris \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-try` on cosmos

```bash
# export header.json from iris
iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
# export proof_init.json from iris with hight in header.json
iriscli --home ibc-iris/n0/iriscli q ibc connection proof conn-to-gaia \
  $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) \
  -o json >ibc-gaia/n0/conn_proof_init.json
# view proof_init.json
jq -r '' ibc-gaia/n0/conn_proof_init.json
# update client on cosmos
gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# query client consense state
gaiacli --home ibc-gaia/n0/gaiacli q ibc client consensus-state client-to-iris | jq
# open-try
gaiacli --home ibc-gaia/n0/gaiacli tx ibc connection open-try \
  conn-to-iris client-to-iris \
  conn-to-gaia client-to-gaia \
  1.0.0 \
  ibc-gaia/n0/conn_proof_init.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-ack` on iris

```bash
# export header.json from cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc client header -o json >ibc-iris/n0/header.json
# export proof_try.json from cosmos with hight in header.json
gaiacli --home ibc-gaia/n0/gaiacli q ibc connection proof conn-to-iris \
  $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) \
  -o json >ibc-iris/n0/conn_proof_try.json
# view proof_try.json
jq -r '' ibc-iris/n0/conn_proof_try.json
# update client on iris
iriscli --home ibc-iris/n0/iriscli tx ibc client update client-to-gaia ibc-iris/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# query client consense state
iriscli --home ibc-iris/n0/iriscli q ibc client consensus-state client-to-gaia | jq
# open-ack
iriscli --home ibc-iris/n0/iriscli tx ibc connection open-ack \
  conn-to-gaia \
  ibc-iris/n0/conn_proof_try.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) \
  1.0.0 \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-confirm` on cosmos

```bash
# export header.json from iris
iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
# export proof_ack.json from iris with hight in header.json
iriscli --home ibc-iris/n0/iriscli q ibc connection proof conn-to-gaia \
  $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) \
  -o json >ibc-gaia/n0/conn_proof_ack.json
# view proof_ack.json
jq -r '' ibc-gaia/n0/conn_proof_ack.json
# update client on cosmos
gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# open-confirm
gaiacli --home ibc-gaia/n0/gaiacli tx ibc connection open-confirm \
  conn-to-iris \
  ibc-gaia/n0/conn_proof_ack.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

**Query connection**

query connection

```bash
# query connection on iris
iriscli --home ibc-iris/n0/iriscli q ibc connection end conn-to-gaia | jq
# query connection on cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc connection end conn-to-iris | jq
```

query connection proof

```bash
# query connection proof with height in header.json on iris
iriscli --home ibc-iris/n0/iriscli q ibc connection proof conn-to-gaia \
  $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) | jq
# query connection proof with height in header.json on cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc connection proof conn-to-iris \
  $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) | jq
```

query connections of a client

```bash
# query connections of a client on iris
iriscli --home ibc-iris/n0/iriscli q ibc connection client client-to-gaia | jq
# query connections of a client on cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc connection client client-to-iris | jq
```

**Create channel**

`open-init` on iris

```bash
# open-init
iriscli --home ibc-iris/n0/iriscli tx ibc channel open-init \
  bank chann-to-gaia \
  bank chann-to-iris \
  conn-to-gaia --unordered \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-try` on cosmos

```bash
# export header.json from iris
iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
# export proof_init.json from iris with hight in header.json
iriscli --home ibc-iris/n0/iriscli q ibc channel proof bank chann-to-gaia \
  $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) \
  -o json >ibc-gaia/n0/chann_proof_init.json
# view proof_init.json
jq -r '' ibc-gaia/n0/chann_proof_init.json
# update client on cosmos
gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# query client consense state
gaiacli --home ibc-gaia/n0/gaiacli q ibc client consensus-state client-to-iris | jq
# open-try
gaiacli --home ibc-gaia/n0/gaiacli tx ibc channel open-try \
  bank chann-to-iris \
  bank chann-to-gaia \
  conn-to-iris --unordered \
  ibc-gaia/n0/chann_proof_init.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-ack` on iris

```bash
# export header.json from cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc client header -o json >ibc-iris/n0/header.json
# export proof_try.json from cosmos with hight in header.json
gaiacli --home ibc-gaia/n0/gaiacli q ibc channel proof bank chann-to-iris \
  $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) \
  -o json >ibc-iris/n0/chann_proof_try.json
# view proof_try.json
jq -r '' ibc-iris/n0/chann_proof_try.json
# update client on iris
iriscli --home ibc-iris/n0/iriscli tx ibc client update client-to-gaia ibc-iris/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# query client consense state
iriscli --home ibc-iris/n0/iriscli q ibc client consensus-state client-to-gaia | jq
# open-ack
iriscli --home ibc-iris/n0/iriscli tx ibc channel open-ack \
  bank chann-to-gaia \
  ibc-iris/n0/chann_proof_try.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

`open-confirm` on cosmos

```bash
# export header.json from iris
iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
# export proof_ack.json from iris with hight in header.json
iriscli --home ibc-iris/n0/iriscli q ibc channel proof bank chann-to-gaia \
  $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) \
  -o json >ibc-gaia/n0/chann_proof_ack.json
# view proof_ack.json
jq -r '' ibc-gaia/n0/chann_proof_ack.json
# update client on cosmos
gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# query client consense state
gaiacli --home ibc-gaia/n0/gaiacli q ibc client consensus-state client-to-iris | jq
# open-confirm
gaiacli --home ibc-gaia/n0/gaiacli tx ibc channel open-confirm \
  bank chann-to-iris \
  ibc-gaia/n0/chann_proof_ack.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

**Query channel**

query channel

```bash
# query channel on iris
iriscli --home ibc-iris/n0/iriscli query ibc channel end bank chann-to-gaia | jq
# query channel on cosmos
gaiacli --home ibc-gaia/n0/gaiacli query ibc channel end bank chann-to-iris | jq
```

query channel proof

```bash
# query channel proof with height in header.json on iris
iriscli --home ibc-iris/n0/iriscli q ibc channel proof bank chann-to-gaia \
  $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) | jq
# query channel proof with height in header.json on cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc channel proof bank chann-to-iris \
  $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) | jq
```

**Bank transfer from iris to cosmos**

```bash
# export transfer result to result.json
iriscli --home ibc-iris/n0/iriscli tx ibcmockbank transfer \
  --src-port bank --src-channel chann-to-gaia \
  --denom uiris --amount 1 \
  --receiver $(gaiacli --home ibc-gaia/n0/gaiacli keys show n0 | jq -r '.address') \
  --source true \
  --from n0 -y -o json \
  --broadcast-mode=block \
  >ibc-iris/n0/result.json
# export packet.json
jq -r '.events[1].attributes[5].value' ibc-iris/n0/result.json >ibc-gaia/n0/packet.json
```

**Bank receive**

```bash
# export header.json from iris
iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
# export proof.json from iris with hight in header.json
iriscli --home ibc-iris/n0/iriscli q ibc channel packet-proof bank chann-to-gaia \
  $(jq -r '.m_sequence' ibc-gaia/n0/packet.json) \
  $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) \
  -o json >ibc-gaia/n0/proof.json
# view proof.json
jq -r '' ibc-gaia/n0/proof.json
# update client on cosmos
gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# receive packet
gaiacli --home ibc-gaia/n0/gaiacli tx ibcmockbank recv-packet \
  ibc-gaia/n0/packet.json ibc-gaia/n0/proof.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) \
  --from n0 -y -o text \
  --broadcast-mode=block
```

**Query Account**

```bash
# view sender account on iris
iriscli --home ibc-iris/n0/iriscli q account -o text \
  $(iriscli --home ibc-iris/n0/iriscli keys show n0 | jq -r '.address')
# view receiver account on cosmos
gaiacli --home ibc-gaia/n0/gaiacli q account -o text \
  $(gaiacli --home ibc-gaia/n0/gaiacli keys show n0 | jq -r '.address')
```

**Bank transfer from cosmos to iris**

```bash
# export transfer result to result.json
gaiacli --home ibc-gaia/n0/gaiacli tx ibcmockbank transfer \
  --src-port bank --src-channel chann-to-iris \
  --denom uatom --amount 1 \
  --receiver $(iriscli --home ibc-iris/n0/iriscli keys show n0 | jq -r '.address') \
  --source true \
  --from n0 -y -o json \
  --broadcast-mode=block \
  >ibc-gaia/n0/result.json
# export packet.json
jq -r '.events[1].attributes[5].value' ibc-gaia/n0/result.json >ibc-iris/n0/packet.json
```

**Bank receive**

```bash
# export header.json from cosmos
gaiacli --home ibc-gaia/n0/gaiacli q ibc client header -o json >ibc-iris/n0/header.json
# export proof.json from cosmos with hight in header.json
gaiacli --home ibc-gaia/n0/gaiacli q ibc channel packet-proof bank chann-to-iris \
  $(jq -r '.m_sequence' ibc-iris/n0/packet.json) \
  $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) \
  -o json >ibc-iris/n0/proof.json
# view proof.json
jq -r '' ibc-iris/n0/proof.json
# update client on iris
iriscli --home ibc-iris/n0/iriscli tx ibc client update client-to-gaia ibc-iris/n0/header.json \
  --from n0 -y -o text --broadcast-mode=block
# receive packet
iriscli --home ibc-iris/n0/iriscli tx ibcmockbank recv-packet \
  ibc-iris/n0/packet.json ibc-iris/n0/proof.json \
  $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) \
  --from n0 -y \
  --broadcast-mode=block
```

**Query Account**

```bash
# view sender account on cosmos
gaiacli --home ibc-gaia/n0/gaiacli q account -o text \
  $(gaiacli --home ibc-gaia/n0/gaiacli keys show n0 | jq -r '.address')
# view receiver account on iris
iriscli --home ibc-iris/n0/iriscli q account -o text \
  $(iriscli --home ibc-iris/n0/iriscli keys show n0 | jq -r '.address')
```
