# Extensions

A _Flare Compute Extension_ (FCE) packages an application that runs on FCC: a set of supported code versions plus a set of registered TEE machines that run them.
The built-in [system extension](SystemExtension.md) hosts FCC's PMW and FDC2 applications; custom extensions follow the same pattern with their own code and TEE machines.

| Page | Contents |
|---|---|
| [Concepts](Concepts.md) | Extension data model, system-vs-custom distinction, instructions senders, lifecycle, and management calls. |
| [SystemExtension](SystemExtension.md) | The built-in extension hosting PMW and FDC2. |
| [FDC2](FDC2/README.md) | FDC2 spec, verifier server, attestation types, and commands. |
| [PMW](PMW/README.md) | PMW spec, transactions, and commands. |
