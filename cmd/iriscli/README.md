# IBC instruction

// temporal document

// connect irishub and gaia

## Dependencies

This branch uses non-canonical branch of cosmos-sdk. Before building, run `go mod vendor` on the root directory to retrive the dependencies. To build:

**install iris**
```shell
git clone https://github.com/irisnet/irishub.git
cd irishub
git checkout cosmos-sdk
go mod tidy
make install
iris version
iriscli version
```

**install gaia**
```shell
git clone https://github.com/cosmos/gaia.git
cd gaia
git checkout joon/ibc-gaia-interface
go mod tidy
make install
gaiad version
gaiacli version
```

Stub out testnet files for 2 networks, this example does so in your $HOME directory:

```shell
cd ~ && mkdir ibc-testnets && cd ibc-testnets
gaiad testnet -o gaia --v 1 --chain-id gaia --node-dir-prefix n
iris testnet -o iris --v 1 --chain-id iris --node-dir-prefix n
```

Fix the configuration files to allow both chains/nodes to run on the same machine

```shell
# Configure the proper database backend for each node and different listening ports
sed -i '' 's/"leveldb"/"goleveldb"/g' gaia/n0/gaiad/config/config.toml
sed -i '' 's/"leveldb"/"goleveldb"/g' iris/n0/iris/config/config.toml
sed -i '' 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:26556"#g' iris/n0/iris/config/config.toml
sed -i '' 's#"tcp://0.0.0.0:26657"#"tcp://0.0.0.0:26557"#g' iris/n0/iris/config/config.toml
sed -i '' 's#"localhost:6060"#"localhost:6061"#g' iris/n0/iris/config/config.toml
sed -i '' 's#"tcp://127.0.0.1:26658"#"tcp://127.0.0.1:26558"#g' iris/n0/iris/config/config.toml
```

Then configure your `cli` instances for each chain:

```bash
gaiacli config --home gaia/n0/gaiacli/ chain-id gaia
iriscli config --home iris/n0/iriscli/ chain-id iris
gaiacli config --home gaia/n0/gaiacli/ node http://localhost:26657
iriscli config --home iris/n0/iriscli/ node http://localhost:26557

# Add the key from chain `iris` to the chain `gaia` cli
jq -r '.secret' iris/n0/iriscli/key_seed.json | pbcopy

# Paste the mnemonic from the above command after setting password (12345678)
gaiacli --home gaia/n0/gaiacli keys add n1 --recover
```

After configuration is complete, start each node in a seperate terminal window:

```bash
gaiad --home gaia/n0/gaiad start
iris --home iris/n0/iris start
```

## Client

Create a `gaia` client on chain `iris`:

```bash
gaiacli --home gaia/n0/gaiacli q ibc client path > path0.json
gaiacli --home gaia/n0/gaiacli q ibc client consensus-state > state0.json
iriscli --home iris/n0/iriscli tx ibc client create c-gaia ./state0.json --from n0 -y
iriscli --home iris/n0/iriscli q ibc client client c-gaia
```

Create a `iris` client on chain `gaia`:

```bash
iriscli --home iris/n0/iriscli q ibc client path > path1.json
iriscli --home iris/n0/iriscli q ibc client consensus-state > state1.json
gaiacli --home gaia/n0/gaiacli tx ibc client create c-iris ./state1.json --from n0 -y
gaiacli --home gaia/n0/gaiacli q ibc client client c-iris
```

## Connection

Create a connection with the following command:

```shell
gaiacli \
  --home gaia/n0/gaiacli \
  tx ibc connection handshake \
  conn-iris c-iris path1.json \
  conn-gaia c-gaia path0.json \
  --chain-id2 iris \
  --from1 n0 --from2 n1 \
  --node1 tcp://localhost:26657 \
  --node2 tcp://localhost:26557
```

Once the connection is established you should be able to query it:

```bash
gaiacli --home gaia/n0/gaiacli q ibc connection connection conn-iris --trust-node
iriscli --home iris/n0/iriscli q ibc connection connection conn-gaia --trust-node
```

## Channel

To establish a channel using the `ibc-mock` application protocol run the following command:

```
gaiacli \
  --home iris/n0/gaiacli \
  tx ibc channel handshake \
  ibc-mock chan-iris conn-iris \
  ibc-mock chan-gaia conn-gaia \
  --node1 tcp://localhost:26657 \
  --node2 tcp://localhost:26557 \
  --chain-id2 iris \
  --from1 n0 --from2 n1
```

You can query the channel after establishment by running the following command

```bash
gaiacli --home gaia/n0/gaiacli query ibc channel channel ibc-mock chan-iris --trust-node
iriscli --home iris/n0/iriscli query ibc channel channel ibc-mock chan-gaia --trust-node
```

## Send Packet

To send a packet using the `ibc-mock` application protocol run the following command:

```
gaiacli --home gaia/n0/gaiacli q ibcmocksend sequence chan-iris
```

The command will return the latest sent sequence, `0` if not exists. Run command with next sequence (n+1).

```
gaiacli --home gaia/n0/gaiacli tx ibcmocksend sequence chan-iris 1 --from n0
```

## Receive Packet

To receive packets using the `ibc-mock` application protocol run the following command:

```
gaiacli \
  --home gaia/n0/gaiacli \
  tx ibc channel flush ibc-mock chan-iris \
  --node1 tcp://localhost:26657 \
  --node2 tcp://localhost:26557 \
  --chain-id2 iris \
  --from1 n0 --from2 n1
```

To see the updated sequence run the following command:

```
iriscli --home iris/n0/iriscli q ibcmockrecv sequence chan-gaia --trust-node
```
