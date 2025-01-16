# FdcHub

The main functionality of the FdcHub is encompassed by

```Solidity
function requestAttestation(bytes calldata _data) external payable;
```

that accepts encoded requests.
It requires that the value sent with the request is greater or equal than the required minimal fee for the attestation type and source of the request.
If the minimal fee is not configured for the attestation type and source of the request, the request is rejected.

If a request is successfully made an event

```Solidity
event AttestationRequest(bytes data, uint256 fee);
```

is emitted.

If the request is confirmed by the FDC, the fee is distributed among the providers, otherwise it is burned.

## Minimal fee

The required minimal fee is managed on `FdcRequestFeeConfigurations` smart contract by Governance
(The management is expected to be passed on to the data providers at some point).

Users can check the minimal fee using:

```Solidity
function getRequestFee(bytes calldata _data) external view returns (uint256);
```

on FdcRequestFeeConfigurations smart contract.
