# Pointbreak Debug Security Policy

Pointbreak Debug controls an IDE's native debugger and can inspect code and process state. Please
report suspected vulnerabilities privately.

## Supported version

VS Code extension `0.2.5` is the final Pointbreak Debug release. Reports should reproduce against
that version when possible. Older Debug versions are not supported.

## Report a vulnerability

Do not open a public GitHub issue or Discussion. Email `security@withpointbreak.com` with the subject
`Security Vulnerability in Pointbreak Debug` and include:

1. a description and expected impact;
2. affected versions and environment details;
3. minimal reproduction steps or a proof of concept;
4. any suggested mitigation; and
5. your preferred name or handle for credit, if any.

Avoid accessing data beyond what is necessary to demonstrate the issue, harming users or services,
or disclosing the vulnerability before a fix or coordinated disclosure date. Good-faith research
that follows this policy is considered authorized, and we will not pursue legal action against it.

For non-security Debug defects, use
[GitHub Issues](https://github.com/withpointbreak/pointbreak-debug/issues). For general questions, use
[Discussions](https://github.com/withpointbreak/pointbreak-debug/discussions).

The new Pointbreak product has a separate architecture. This policy covers only the legacy
Pointbreak Debug extension, CLI, bridge, and MCP debugging features represented by this repository.
