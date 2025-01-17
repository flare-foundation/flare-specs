# Daemon

FlareDaemon is an automatically triggered smart contract that subsequently calls all daemonized contracts.
FlareDaemon smart contract is deployed at
`0x1000000000000000000000000000000000000002`.
The call is triggered at the end of the first successful transaction in every block.

The list of daemonzed contracts is available by calling the function

```Solidity
function getDaemonizedContractsData() external view;
```

on FlareDaemon smart contract.
