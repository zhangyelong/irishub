# TEST

## init

```bash
chmod 777 init.sh
./init.sh
```

## start

```bash
nohup iris --home ibc-a/n0/iris start >ibc-a.log &
nohup iris --home ibc-b/n0/iris start >ibc-b.log &
```

```bash
iris --home ibc-iris/n0/iris start
gaiad --home ibc-gaia/n0/gaiad start
```

## handshake

```bash
chmod 777 handshake.sh
handshake.sh
```

## transfer

```bash
chmod 777 transfer-iris.sh
transfer-iris.sh
```

```bash
chmod 777 transfer-gaia.sh
transfer-gaia.sh
```
