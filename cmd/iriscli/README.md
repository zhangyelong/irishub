# IBC instruction

// temporal document

// connect irishub and gaia

## Dependencies

This branch uses non-canonical branch of cosmos-sdk. Before building, run `go mod vendor` on the root directory to retrive the dependencies. To build:

### Install `iris`

```bash
git clone https://github.com/irisnet/irishub.git
cd irishub
git checkout cosmos-sdk
go mod tidy
make install
iris version
iriscli version
```

### Install `gaia`

```bash
git clone https://github.com/cosmos/gaia.git
cd gaia
git checkout joon/ibc-gaia-interface
go mod tidy
make install
gaiad version
gaiacli version
```

## Environment Setup

Stub out testnet files for 2 networks, this example does so in your $HOME directory:

```bash
cd ~ && mkdir ibc-testnets && cd ibc-testnets
gaiad testnet -o gaia --v 1 --chain-id gaia --node-dir-prefix n
iris testnet -o iris --v 1 --chain-id iris --node-dir-prefix n
```

### Set `gaiacli` Configuation

Fix the configuration files to allow both chains/nodes to run on the same machine

```bash
# Configure the proper database backend for each node and different listening ports
sed -i '' 's/"leveldb"/"goleveldb"/g' gaia/n0/gaiad/config/config.toml
sed -i '' 's/"leveldb"/"goleveldb"/g' iris/n0/iris/config/config.toml
sed -i '' 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:26556"#g' iris/n0/iris/config/config.toml
sed -i '' 's#"tcp://0.0.0.0:26657"#"tcp://0.0.0.0:26557"#g' iris/n0/iris/config/config.toml
sed -i '' 's#"localhost:6060"#"localhost:6061"#g' iris/n0/iris/config/config.toml
sed -i '' 's#"tcp://127.0.0.1:26658"#"tcp://127.0.0.1:26558"#g' iris/n0/iris/config/config.toml

gaiacli config --home gaia/n0/gaiacli/ chain-id gaia
iriscli config --home iris/n0/iriscli/ chain-id iris
gaiacli config --home gaia/n0/gaiacli/ output json
iriscli config --home iris/n0/iriscli/ output json
gaiacli config --home gaia/n0/gaiacli/ node http://localhost:26657
iriscli config --home iris/n0/iriscli/ node http://localhost:26557
```

Add keys from each chain to the other and make such that the key at `iris/n0/iriscli/key_seed.json` is named `n1` on `iriscli` instance and the same for `n0`. After this is complete the results of `gaiacli keys list` and `iriscli keys list` from each chain should be identical. The following are instructions for how to do this on Mac:

```bash
# These commands copy the seed phrase from each dir into the clipboard on mac
jq -r '.secret' gaia/n0/gaiacli/key_seed.json | pbcopy
jq -r '.secret' iris/n0/iriscli/key_seed.json | pbcopy

# Remove the key n0 on iris
iriscli --home iris/n0/iriscli keys delete n0

# seed from iris/n0/iriscli/key_seed.json -> gaia/n1
gaiacli --home gaia/n0/gaiacli keys add n1 --recover

# seed from gaia/n0/gaiacli/key_seed.json -> iris/n0
iriscli --home iris/n0/iriscli keys add n0 --recover

# seed from iris/n0/iriscli/key_seed.json -> iris/n1
iriscli --home iris/n0/iriscli keys add n1 --recover

# Ensure keys match
gaiacli --home gaia/n0/gaiacli keys list | jq '.[].address'
iriscli --home iris/n0/iriscli keys list | jq '.[].address'
```

After configuration is complete, start your `gaiad` and `iris` processes:

```bash
# running in the background with log
nohup gaiad --home gaia/n0/gaiad start > gaia.log &
nohup iris --home iris/n0/iris start > iris.log &

# or without log
gaiad --home gaia/n0/gaiad start
iris --home iris/n0/iris start
```

## IBC Command Sequence

### Client Creation

Create IBC clients on each chain using the following commands. Note that we are using the consensus state of `iris` to create the client on `gaia` and visa-versa. These "roots of trust" are used to validate transactions coming from the other chain. They will be updated periodically during handshakes and will require update at least once per unbonding period:

```bash
# client for chain iris on chain gaia
gaiacli \
  --home gaia/n0/gaiacli \
  tx ibc client create client-to-iris \
  $(iriscli --home iris/n0/iriscli q ibc client consensus-state) \
  --from n0 -y -o text

# client for chain gaia on chain iris
iriscli \
  --home iris/n0/iriscli \
  tx ibc client create client-to-gaia \
  $(gaiacli --home gaia/n0/gaiacli q ibc client consensus-state) \
  --from n1 -y -o text
```

To query details about the clients use the following commands :

```bash
gaiacli --home gaia/n0/gaiacli q ibc client client client-to-iris --indent
iriscli --home iris/n0/iriscli q ibc client client client-to-gaia --indent
```

### Connection Creation

In order to send transactions using IBC there are two differnt handshakes that must be preformed. First there is a `connection` created between the two chains. Once the connection is created, an application specific `channel` handshake is preformed which allows the transfer of application specific data. Examples of applications are token transfer, cross-chain validation, cross-chain accounts, and in this tutorial `ibc-mock`.

Create a `connection` with the following command:

> NOTE: This command broadcasts a total of 7 transactions between the two chains from 2 different wallets. At the start of the command you will be prompted for passwords for the two different keys. The command may then take some time. Please wait for the command to return!

```bash
gaiacli \
  --home gaia/n0/gaiacli \
  tx ibc connection handshake \
  conn-to-iris client-to-iris $(iriscli --home iris/n0/iriscli q ibc client path) \
  conn-to-gaia client-to-gaia $(gaiacli --home gaia/n0/gaiacli q ibc client path) \
  --chain-id2 iris \
  --from1 n0 \
  --from2 n1 \
  --node1 tcp://localhost:26657 \
  --node2 tcp://localhost:26557
```

Once the connection is established you should be able to query it:

```bash
gaiacli --home gaia/n0/gaiacli q ibc connection connection conn-to-iris --indent --trust-node
iriscli --home iris/n0/iriscli q ibc connection connection conn-to-gaia --indent --trust-node
```

### Channel

Now that the `connection` has been created, its time to establish a `channel` for the `ibc-mock` application protocol. This will allow sending of data between `gaia` and `iris`. To create the `channel`, run the following command:

> NOTE: This command broadcasts a total of 7 transactions between the two chains from 2 different wallets. At the start of the command you will be prompted for passwords for the two different keys. The command may then take some time. Please wait for the command to return!

```bash
gaiacli \
  --home gaia/n0/gaiacli \
  tx ibc channel handshake \
  ibcmocksend chan-to-iris conn-to-iris \
  ibcmockrecv chan-to-gaia conn-to-gaia \
  --node1 tcp://localhost:26657 \
  --node2 tcp://localhost:26557 \
  --chain-id2 iris \
  --from1 n0 \
  --from2 n1
```

You can query the `channel` after establishment by running the following command:

```bash
gaiacli --home gaia/n0/gaiacli query ibc channel channel ibcmocksend chan-to-iris --indent --trust-node
iriscli --home iris/n0/iriscli query ibc channel channel ibcmockrecv chan-to-gaia --indent --trust-node
```

## Send Packet

To send a packet using the `ibc-mock` application protocol, you need to know the channel you plan to send on, as well as the sequence number on the channel. To get the sequence you use the following commands:

```bash
# Returns the last sequence number
gaiacli --home gaia/n0/gaiacli q ibcmocksend sequence chan-to-iris

# Returns the next expected sequence number, for use in scripting
gaiacli --home gaia/n0/gaiacli q ibcmocksend next chan-to-iris
# BUG: should return "1" when the sequence is "0", but actually return "2"
```

Now you are ready to send an `ibc-mock` packet down the channel (`chan-to-iris`) from chain `gaia` to chain `iris`! To do so run the following command:

```bash
gaiacli \
  --home gaia/n0/gaiacli \
  tx ibcmocksend sequence chan-to-iris \
  $(gaiacli --home gaia/n0/gaiacli q ibcmocksend next chan-to-iris) \
  --from n0 \
  -o text
# BUG: Use "1" instead of "$(gaiacli --home gaia/n0/gaiacli q ibcmocksend next chan-to-iris)"
# when "gaiacli --home gaia/n0/gaiacli q ibcmocksend sequence chan-to-iris" returns 0
```

### Receive Packet

Once packets are sent, reciept must be confirmed on the destination chain. To receive the packets you just sent, run the following command:

```bash
gaiacli \
  --home gaia/n0/gaiacli \
  tx ibc channel flush ibcmocksend chan-to-iris \
  --node1 tcp://localhost:26657 \
  --node2 tcp://localhost:26557 \
  --chain-id2 iris \
  --from1 n0 \
  --from2 n1 \
  -o text
```

Once the packets have been sent, check the To see the updated sequence run the following command:

```bash
iriscli --home iris/n0/iriscli q ibcmockrecv sequence chan-to-gaia --trust-node
```
