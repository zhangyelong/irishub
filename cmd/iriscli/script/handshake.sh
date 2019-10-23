cd ~/ibc-testnets

echo "\n*** create-client...\n"
gaiacli --home ibc-gaia/n0/gaiacli q ibc client self-consensus-state -o json >ibc-iris/n0/consensus_state.json
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc client create client-to-gaia ibc-iris/n0/consensus_state.json --from n0 -y --broadcast-mode=block
iriscli --home ibc-iris/n0/iriscli q ibc client self-consensus-state -o json >ibc-gaia/n0/consensus_state.json
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc client create client-to-iris ibc-gaia/n0/consensus_state.json --from n0 -y --broadcast-mode=block

echo "\n*** open-init...\n"
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc connection open-init conn-to-gaia client-to-gaia conn-to-iris client-to-iris --from n0 -y --broadcast-mode=block
echo "\n*** open-try...\n"
sleep 8 && iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
iriscli --home ibc-iris/n0/iriscli q ibc connection proof conn-to-gaia $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) -o json >ibc-gaia/n0/conn_proof_init.json
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json --from n0 -y --broadcast-mode=block
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc connection open-try conn-to-iris client-to-iris conn-to-gaia client-to-gaia 1.0.0 ibc-gaia/n0/conn_proof_init.json $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) --from n0 -y --broadcast-mode=block
echo "\n*** open-ack...\n"
sleep 8 && gaiacli --home ibc-gaia/n0/gaiacli q ibc client header -o json >ibc-iris/n0/header.json
gaiacli --home ibc-gaia/n0/gaiacli q ibc connection proof conn-to-iris $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) -o json >ibc-iris/n0/conn_proof_try.json
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc client update client-to-gaia ibc-iris/n0/header.json --from n0 -y --broadcast-mode=block
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc connection open-ack conn-to-gaia ibc-iris/n0/conn_proof_try.json $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) 1.0.0 --from n0 -y --broadcast-mode=block
echo "\n*** open-confirm...\n"
sleep 8 && iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
iriscli --home ibc-iris/n0/iriscli q ibc connection proof conn-to-gaia $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) -o json >ibc-gaia/n0/conn_proof_ack.json
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json --from n0 -y --broadcast-mode=block
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc connection open-confirm conn-to-iris ibc-gaia/n0/conn_proof_ack.json $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) --from n0 -y --broadcast-mode=block
echo "\n*** query-connection...\n"
iriscli --home ibc-iris/n0/iriscli q ibc connection end conn-to-gaia | jq
gaiacli --home ibc-gaia/n0/gaiacli q ibc connection end conn-to-iris | jq

echo "\n*** open-init...\n"
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc channel open-init bank chann-to-gaia bank chann-to-iris conn-to-gaia --unordered --from n0 -y --broadcast-mode=block
echo "\n*** open-try...\n"
sleep 8 && iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
iriscli --home ibc-iris/n0/iriscli q ibc channel proof bank chann-to-gaia $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) -o json >ibc-gaia/n0/chann_proof_init.json
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json --from n0 -y --broadcast-mode=block
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc channel open-try bank chann-to-iris bank chann-to-gaia conn-to-iris ibc-gaia/n0/chann_proof_init.json $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) --unordered --from n0 -y --broadcast-mode=block
echo "\n*** open-ack...\n"
sleep 8 && gaiacli --home ibc-gaia/n0/gaiacli q ibc client header -o json >ibc-iris/n0/header.json
gaiacli --home ibc-gaia/n0/gaiacli q ibc channel proof bank chann-to-iris $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) -o json >ibc-iris/n0/chann_proof_try.json
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc client update client-to-gaia ibc-iris/n0/header.json --from n0 -y --broadcast-mode=block
echo 12345678 | iriscli --home ibc-iris/n0/iriscli tx ibc channel open-ack bank chann-to-gaia ibc-iris/n0/chann_proof_try.json $(jq -r '.value.SignedHeader.header.height' ibc-iris/n0/header.json) --from n0 -y --broadcast-mode=block
echo "\n*** open-confirm...\n"
sleep 8 && iriscli --home ibc-iris/n0/iriscli q ibc client header -o json >ibc-gaia/n0/header.json
iriscli --home ibc-iris/n0/iriscli q ibc channel proof bank chann-to-gaia $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) -o json >ibc-gaia/n0/chann_proof_ack.json
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc client update client-to-iris ibc-gaia/n0/header.json --from n0 -y --broadcast-mode=block
echo 12345678 | gaiacli --home ibc-gaia/n0/gaiacli tx ibc channel open-confirm bank chann-to-iris ibc-gaia/n0/chann_proof_ack.json $(jq -r '.value.SignedHeader.header.height' ibc-gaia/n0/header.json) --from n0 -y --broadcast-mode=block
echo "\n*** query-channel...\n"
iriscli --home ibc-iris/n0/iriscli query ibc channel end bank chann-to-gaia | jq
gaiacli --home ibc-gaia/n0/gaiacli query ibc channel end bank chann-to-iris | jq
