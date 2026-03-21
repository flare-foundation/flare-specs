# PMWMultisigAccountConfigured

The `PMWMultisigAccountConfigured` attestation type proves that a multisig account on an external chain is configured correctly for use with Protocol Managed Wallets.

## Request

Attestation request body:

- `accountAddress` — Address of the multisig account.
- `publicKeys` — Public keys of the multisig account owners (keys are in concatenated format: `pubkey.X | pubkey.Y`).
- `threshold` — Threshold for the multisig account.

## Response

Attestation response body:

- `status` (`PMWMultisigAccountStatus` enum):
  - `OK` ($0$) — Account is correctly configured.
  - `ERROR` ($1$) — Account is incorrectly configured or the RPC query to the external chain failed validation checks.
- `sequence` (`uint64`) — Sequence number of the account. Set to $0$ when status is `ERROR`.

## Chain Support

Currently, `PMWMultisigAccountConfigured` is used for XRP.

## Verification

### XRP Ledger

1. Query [`account_info`](https://xrpl.org/docs/references/http-websocket-apis/public-api-methods/account-methods/account_info) on an XRP node for the given `accountAddress`, with `ledger_index: "validated"` and `signer_lists: true`.

2. **Validate signer list:**
   - Check [`signer_lists`](https://xrpl.org/docs/references/protocol/ledger-data/ledger-entry-types/signerlist) to obtain signer addresses and their weights.
   - Convert `publicKeys` from the request body to XRPL account addresses for matching.
   - Verify that each `SignerWeight` equals 1.

3. **Validate quorum:**
   - Check that `SignerQuorum` matches the requested `threshold`.

4. **Validate account flags** (from [`account_flags`](https://xrpl.org/docs/references/http-websocket-apis/public-api-methods/account-methods/account_info)):
   - `disableMasterKey` = `true`
   - `depositAuth` = `false`
   - `requireDestinationTag` = `false`
   - `disallowIncomingXRP` = `false`

5. **Validate no regular key:**
   - Check that `result.account_data.RegularKey` does not exist.

6. **Retrieve sequence:**
   - `sequence` = `result.account_data.Sequence`

### Result

- If all checks pass: `status` = `OK`, `sequence` = `result.account_data.Sequence`.
- If any validation check fails: `status` = `ERROR`, `sequence` = $0$. The response is still returned successfully (not an HTTP error).
- If the XRP RPC call itself fails (network error, node unreachable): an error is returned to the caller.

## Notes

Example `account_info` response for a correctly configured multisig account (`rhKxtU4Zgj6aCdBKQWHkqku72bmDvRgzRz`):

```json
{
  "result": {
    "account_data": {
      "Account": "rhKxtU4Zgj6aCdBKQWHkqku72bmDvRgzRz",
      "Balance": "159999460",
      "Flags": 1048576,
      "LedgerEntryType": "AccountRoot",
      "OwnerCount": 1,
      "Sequence": 9737863,
      "signer_lists": [
        {
          "Flags": 65536,
          "LedgerEntryType": "SignerList",
          "SignerEntries": [
            {
              "SignerEntry": {
                "Account": "rUVZF7vqHEP9gkcACiS2rQLhR6eUKv5mka",
                "SignerWeight": 1
              }
            },
            {
              "SignerEntry": {
                "Account": "rHPunzCR1YSjmDVLRHV78WUDVJXWbE5YM2",
                "SignerWeight": 1
              }
            },
            {
              "SignerEntry": {
                "Account": "rMagXXhTSTMNCe7FuswqQgTveRHQgj3e4v",
                "SignerWeight": 1
              }
            }
          ],
          "SignerListID": 0,
          "SignerQuorum": 1
        }
      ]
    },
    "account_flags": {
      "allowTrustLineClawback": false,
      "defaultRipple": false,
      "depositAuth": false,
      "disableMasterKey": true,
      "disallowIncomingCheck": false,
      "disallowIncomingNFTokenOffer": false,
      "disallowIncomingPayChan": false,
      "disallowIncomingTrustline": false,
      "disallowIncomingXRP": false,
      "globalFreeze": false,
      "noFreeze": false,
      "passwordSpent": false,
      "requireAuthorization": false,
      "requireDestinationTag": false
    },
    "status": "success"
  }
}
```

Example of an account that would **fail** verification (`rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh`) — has a `RegularKey` set and an empty `signer_lists`:

```json
{
  "result": {
    "account_data": {
      "Account": "rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh",
      "Balance": "90004118205822",
      "Flags": 1048576,
      "RegularKey": "raEBBs9myX31dF6jaEFUMfUhL6GpAjeeRp",
      "Sequence": 9,
      "signer_lists": []
    },
    "account_flags": {
      "disableMasterKey": true,
      "depositAuth": false,
      "requireDestinationTag": false,
      "disallowIncomingXRP": false
    },
    "status": "success"
  }
}
```
