The Ethereum wallet contract for centralized crypto-currency exchange

# Features

1. No ether dust for collecting ERC20 tokens
2. Better way to check internal ether deposit tx

# Why and How?

On centralized cryptocurrency exchanges, each user has their own address to top up their Ether or ERC20 tokens(e.g. USDT).

If a user just tops up ERC20 tokens, but not ETH,if the wallet wants to collect these tokens into one address, it needs to first transfer some ETH as miner fee.

But the ETH of the cost is estimated and may be more than what is actually needed.

In the long run, the address of users will have many exceptionally small dust ETH.

This program solves this unavoidable problems.

You can check out [this blog](https://github.com/islishude/blog/issues/221) to get it.
