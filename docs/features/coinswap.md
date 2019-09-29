# Coinswap User Guide

## Introduction

This document describes the implementation of the [uniswap](https://uniswap.io/) token exchange protocol on IRISHub. It supports Token to Token, Token to IRIS, and IRIS to Token. The entire redemption process is completely done by the IRISHub. Before the transaction, the market maker needs to deposit the token to the liquidity pool at the current market price (based on the IRIS token), and then the two token exchange ratios will be changed in real time by the exchange rate on the IRISHub. When the exchange rate in the liquidity pool is inconsistent with the current market, the arbitrageurs will be profitable. They exchange the other tokens to bring the exchange rate closer to the market price. During the redemption process, the 3/1000 handling fee will be deducted and re-added to the liquidity pool to provide liquidity as a market maker. Market makers can retrieve their tokens at any time without a lock-up period. When the run-off situation occurs, it is useful for the market maker to withdraw the deposit token in time to avoid excessive losses. Therefore, the greater the amount of tokens deposit in the liquidity pool, the greater the exchange rate change caused by the exchange process, and the greater the yield of the market maker.

## Concepts

### Liquidity Pool

A system account for depositing mortgage tokens and no private key control. The account consists of three parts, IRIS, Token, and liquidity securities (as a market maker to hold liquidity and can be transferred). Each token (except IRIS) has its own pool of liquidity to calculate the relative price of the two.

### Liquidity

Two assets that can be exchanged in the liquidity pool and mortgaged to the liquidity pool can be considered as providing liquidity for the liquidity pool. When the mortgage assets are retrieved, the user can automatically obtain the charge when the user exchanges the transaction.

### Maker

Any individual, organization, or institution that mortgages tokens to a liquidity pool.

### Maker formula

Use a constant product as the market making formula: $x \ast y=k$  `x` represents the number of x tokens, and `y` represents the number of y tokens. During the redemption process, the value of `k` remains the same, and the value changes only when the market maker increases/decreases the liquidity.


## Actions

- **Add  Liquidity**

  In order to obtain the handling fee during the redemption process, market makers can deposit their tokens into the liquidity pool, mainly in two cases:

  - **Create  Liquidity Pool**

    If there is no liquidity pool of the token in the IRISHub, the market maker needs to mortgage a fixed amount of tokens and IRIS according to the current market conditions. This step is equivalent to initializing the liquidity pool and pricing the token. If the market maker does not price according to the current market, then the arbitrageur finds that there is a difference in the price, and the exchange behavior will occur until the price is close to the current market price. In this process, the relative price of the token is adjusted entirely by market demand.

  - **Add  Liquidity**

    If there is a liquidity pool of the token in the IRISHub, when the market maker mortgages the token, it is necessary to mortgage the two tokens according to the current liquidity pool exchange rate. When calculating, we calculate the IRIS token as the benchmark. The amount of another token that needs to be mortgaged, if the token's token ratio does not match the current liquidity pool's conversion ratio, the transaction will fail. In this way, as far as possible, the market makers are prevented from making market losses due to the existence of arbitrageurs.

  After the mortgage is completed, the system will lock the deposit token and issue a liquidity certificate to the user account, which can also participate in the transfer transaction.

- **Swap Token**

  When there is a certain pool of liquidity pool, the user can initiate a redemption transaction according to his own needs. In the redemption process, the 3/1000 fee is deducted from the input token (this parameter can be changed by the governance module). From the classification of transactions, there are two cases in total:

  - Buy Token

    If the user purchases a fixed amount of tokens, the IRISHub will calculate the amount of another token the user needs to pay, based on the number of tokens purchased and the current inventory of the liquidity pool. The amount of tokens paid by the user is less than The IRISHub calculates the value and the transaction fails.

  - Sell Token

    If the user sells a fixed amount of tokens, the IRISHub will calculate the amount of another token the user receives, based on the number of tokens sold and the current pool of liquidity, if the number of tokens specified by the user is greater than The IRISHub calculates the value and the transaction fails.

  In both cases, the IRISHub supports Token's redemption of Token, which requires the collaterality of both tokens. The system will be redeemed twice, Token1 --> IRIS, IRIS-->Token2. A 3/1000 handling fee will be charged for each redemption.

- **Remove  Liquidity**

  After the market maker deposit the token to the IRISHub, he receives the liquidity certificate corresponding to the token, which can be exchanged for the mortgage token and obtain the market-making reward. After the liquidity is withdrawn, the same amount of liquidity certificate will be destroyed from the user's account and the  pool.

## Additional information

This module does not provide a command entry, only provides the relevant REST interface, you can initiate the above transaction through the API, here we provide a [coinswap](https://github.com/zhiqiang-bianjie/coinswap) front-end interface, the specific use method see instructions.