echo "\n*** open-init\n"
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc channel open-init bank chann-to-gaia bank chann-to-iris conn-to-gaia --unordered --from n0 -y --broadcast-mode=block

echo "\n*** export header.json from chain-iris\n"
sleep 8 && iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
echo "\n*** export proof_init.json from chain-iris with hight in header.json\n"
iriscli --home ibc-iris/n0/iriscli q ibc channel proof bank chann-to-gaia $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) -o json >ibc-gaia/n0/chann_proof_init.json
echo "\n*** update client on chain-gaia\n"
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json --from n0 -y --broadcast-mode=block
echo "\n*** open-try\n"
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc channel open-try bank chann-to-iris bank chann-to-gaia conn-to-iris ibc-gaia/n0/chann_proof_init.json $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) --unordered --from n0 -y --broadcast-mode=block

echo "\n*** export header.json from chain-gaia\n"
sleep 8 && gaiacli --home ibc-gaia/n0/gaiacli q ibc client header -o json >ibc-iris/n0/header.json
echo "\n*** export proof_try.json from chain-gaia with hight in header.json\n"
gaiacli --home ibc-gaia/n0/gaiacli q ibc channel proof bank chann-to-iris $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) -o json >ibc-iris/n0/chann_proof_try.json
echo "\n*** update client on chain-iris\n"
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc client update client-to-gaia ibc-iris/n0/header.json --from n0 -y --broadcast-mode=block
echo "\n*** open-ack\n"
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc channel open-ack bank chann-to-gaia ibc-iris/n0/chann_proof_try.json $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) --from n0 -y --broadcast-mode=block

echo "\n*** export header.json from chain-iris\n"
sleep 8 && iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
echo "\n*** export proof_ack.json from chain-iris with hight in header.json\n"
iriscli --home ibc-iris/n0/iriscli q ibc channel proof bank chann-to-gaia $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) -o json >ibc-gaia/n0/chann_proof_ack.json
echo "\n*** update client on chain-gaia\n"
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json --from n0 -y --broadcast-mode=block
echo "\n*** open-confirm\n"
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc channel open-confirm bank chann-to-iris ibc-gaia/n0/chann_proof_ack.json $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) --from n0 -y --broadcast-mode=block

echo "\n*** channel created ...\n"
echo "\n*** channel on chain-iris \n"
iriscli --home ibc-iris/n0/iriscli query ibc channel end bank chann-to-gaia | jq
echo "\n*** channel on chain-gaia \n"
gaiacli --home ibc-gaia/n0/gaiacli query ibc channel end bank chann-to-iris | jq
echo "\n*** ... end\n"
