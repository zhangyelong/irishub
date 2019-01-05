package types

import "github.com/irisnet/irishub/codec"

// Register the sdk message type
func RegisterCodec(cdc *codec.Codec) {
	cdc.RegisterInterface((*Msg)(nil), nil)
	cdc.RegisterInterface((*Tx)(nil), nil)
	cdc.RegisterConcrete(&UpgradeConfig{}, "irishub/protocol/UpgradeConfig", nil)
}
