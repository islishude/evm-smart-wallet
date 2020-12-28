The Ethereum wallet contract for centralized crypto-currency exchange 

[![Test](https://github.com/islishude/eth-create2-wallet/workflows/test/badge.svg?branch=main)]()

# Features

1. No ether dust for collecting ERC20 tokens
2. Better way to check internal ether deposit

# Why and How?

on centralized cryptocurrency exchanges, each user has their own address to top up their Ether or ERC20 tokens(e.g. USDT).

if a user just tops up ERC20 tokens, but not ETH,if the wallet wants to collect these tokens into one address, it needs to first transfer some ETH as miner fee.

but the ETH of the cost is estimated and may be more than what is actually needed.

in the long run, the address of users will have many exceptionally small dust ETH.

this program solves this unavoidable problems.

the deposit addresses are not created by the private key but by [CREATE2](https://eips.ethereum.org/EIPS/eip-1014),and the address with permissions could call function to transfer tokens.

so the operation of paying the fee is diverted to other address.

You can find out more by reading [this blog](https://github.com/islishude/blog/issues/221).
