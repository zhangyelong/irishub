echo "\n*** export consensus_state.json from chain-gaia\n"
gaiacli --home ibc-gaia/n0/gaiacli q ibc client self-consensus-state -o json >ibc-iris/n0/consensus_state.json
echo "\n*** create client on chain-iris\n"
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc client create client-to-gaia ibc-iris/n0/consensus_state.json --from n0 -y --broadcast-mode=block

echo "\n*** export consensus_state.json from chain-iris\n"
iriscli --home ibc-iris/n0/iriscli q ibc client self-consensus-state -o json >ibc-gaia/n0/consensus_state.json
echo "\n*** create client on chain-gaia\n"
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc client create client-to-iris ibc-gaia/n0/consensus_state.json --from n0 -y --broadcast-mode=block

echo "\n*** export prefix.json\n"
gaiacli --home ibc-gaia/n0/gaiacli q ibc client path -o json >ibc-iris/n0/prefix.json
echo "\n*** open-init\n"
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc connection open-init conn-to-gaia client-to-gaia conn-to-iris client-to-iris ibc-iris/n0/prefix.json --from n0 -y --broadcast-mode=block

echo "\n*** export prefix.json\n"
iriscli --home ibc-iris/n0/iriscli q ibc client path -o json >ibc-gaia/n0/prefix.json
echo "\n*** export header.json from chain-iris\n"
iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
echo "\n*** export proof_init.json from chain-iris with hight in header.json\n"
iriscli --home ibc-iris/n0/iriscli q ibc connection proof conn-to-gaia $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) -o json >ibc-gaia/n0/conn_proof_init.json
echo "\n*** update client on chain-gaia\n"
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json --from n0 -y --broadcast-mode=block
echo "\n*** open-try\n"
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc connection open-try conn-to-iris client-to-iris conn-to-gaia client-to-gaia ibc-gaia/n0/prefix.json 1.0.0 ibc-gaia/n0/conn_proof_init.json $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) --from n0 -y --broadcast-mode=block

echo "\n*** export header.json from chain-gaia\n"
gaiacli --home ibc-gaia/n0/gaiacli q ibc client header -o json >ibc-iris/n0/header.json
echo "\n*** export proof_try.json from chain-gaia with hight in header.json\n"
gaiacli --home ibc-gaia/n0/gaiacli q ibc connection proof conn-to-iris $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) -o json >ibc-iris/n0/conn_proof_try.json
echo "\n*** update client on chain-iris\n"
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc client update client-to-gaia ibc-iris/n0/header.json --from n0 -y --broadcast-mode=block
echo "\n*** open-ack\n"
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc connection open-ack conn-to-gaia ibc-iris/n0/conn_proof_try.json $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) 1.0.0 --from n0 -y --broadcast-mode=block

echo "\n*** export header.json from chain-iris\n"
iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
echo "\n*** export proof_ack.json from chain-iris with hight in header.json\n"
iriscli --home ibc-iris/n0/iriscli q ibc connection proof conn-to-gaia $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) -o json >ibc-gaia/n0/conn_proof_ack.json
echo "\n*** update client on chain-gaia\n"
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json --from n0 -y --broadcast-mode=block
echo "\n*** open-confirm\n"
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc connection open-confirm conn-to-iris ibc-gaia/n0/conn_proof_ack.json $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) --from n0 -y --broadcast-mode=block

echo "\n*** connection created ...\n"
echo "\n*** connection on chain-iris \n"
iriscli --home ibc-iris/n0/iriscli q ibc connection end conn-to-gaia | jq
echo "\n*** connection on chain-gaia \n"
gaiacli --home ibc-gaia/n0/gaiacli q ibc connection end conn-to-iris | jq
echo "\n*** ... end\n"
