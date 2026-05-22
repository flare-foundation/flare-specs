# FCE

A _Flare Compute Extension_ (FCE) packages an application that runs on FCC: a set of supported code versions plus a set of registered TEE machines that run them.
The built-in [system FCE](System.md) hosts FCC's [PMW](../PMW/README.md) and [FDC2](../FDC2/README.md) applications; custom FCEs follow the same pattern with their own code and TEE machines.

| Page | Contents |
|---|---|
| [Concepts](Concepts.md) | Extension data model, system-vs-custom distinction, instructions senders, lifecycle, and management calls. |
| [System](System.md) | The built-in FCE hosting PMW and FDC2. |
| [Reference/Api](Reference/Api.md) | The HTTP contract between a TEE machine and its FCE process. _(pending)_ |
| [Workflows/Configuration](Workflows/Configuration.md) | Register and configure an FCE on `FlareTeeManager`. |
| [Workflows/Instructions](Workflows/Instructions.md) | Submit a custom instruction to an FCE. |
