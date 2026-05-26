# PMW Operations

Operations defined by the [PMW](../../README.md) application of the [system extension](../../../FCC/FCE/System.md).
For the cross-FCE infrastructure operations, see [Reference/Operations](../../../FCC/Reference/Operations/README.md).

| `opType` | `opCommand` | Kind | Description |
|---|---|---|---|
| `F_XRP` | [`PAY`](Pay.md) | Instruction | Signs an XRP Ledger multisig payment transaction using TEE-managed keys. |
| `F_XRP` | [`REISSUE`](Reissue.md) | Instruction | Re-signs a previously issued XRP payment for resubmission. |
