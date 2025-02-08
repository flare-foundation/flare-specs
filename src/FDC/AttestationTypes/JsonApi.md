# JsonApi WIP (CURRENTLY ONLY ON COSTON and COSTON2)

## Description

An attestation request that fetches data from the given url and then edits the information with a

- jq transformation.

**Supported sources:** WEB2

## Request body

| Field           | Solidity type | Description                                              |
| --------------- | ------------- | -------------------------------------------------------- |
| `url`           | `string`      | URL of the data source.                                  |
| `postprocessJq` | `string`      | JQ filter to postprocess the json received from the url. |
| `abi_signature` | `string`      | ABI signature of struct for encoding.                    |

## Response body

| Field              | Solidity type | Description       |
| ------------------ | ------------- | ----------------- |
| `abi_encoded_data` | `bytes`       | ABI encoded data. |

## Lowest Used Timestamp

For `lowestUsedTimestamp`, `0xffffffffffffffff` ($2^{64}-1$ in hex) is used.

## Verification

Query the URL with GET method.
If the query is unsuccessful or does not return a json, reject the request.

Apply the jq filter specified in the request to the received json.

ABI encode the filtered json with the abi_signature provided in the request and return it as abi_encoded_data.

`LowestUsedTimestamp` is unlimited.
