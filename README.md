# Context
The provided code, MintableToken.sol, is a simplified ERC20 stablecoin token, like USDC. The token is backed by US dollars. For each dollar we receive in an offchain bank account, we mint the corresponding amount of USDC onchain.

# Requirements
To secure this minting operation, implement a m/n multisig, where m of the n signers must approve a mint before it is executed. (To execute the mint, use the _mint(address, uint256) function inherited from ERC20.sol.)