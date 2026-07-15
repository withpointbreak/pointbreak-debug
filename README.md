# Pointbreak Debug

> [!IMPORTANT]
> This repository is the home of the legacy Pointbreak Debug product. VS Code extension `0.2.5`
> is its final release. The next Pointbreak extension is an incompatible, Review-focused product;
> this repository is not the canonical open-source repository for that new product.

Pointbreak Debug gives AI assistants access to an IDE's native debugger through the Model Context
Protocol. It can set breakpoints, step through execution, and inspect variables from tools such as
Claude Code, Codex, Cursor, and GitHub Copilot.

## Product status

- The VS Code extension remains available under the existing `pointbreak.pointbreak` Marketplace
  identity, with `0.2.5` as the final Pointbreak Debug release.
- Historical Debug binaries and installer sources remain available, but no new Debug architecture
  is planned.
- New Pointbreak development is separate and incompatible with the Debug extension, bridge, and MCP
  debugging features described here.

## Install the final Debug release

Install the VS Code extension from the
[Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=pointbreak.pointbreak).

For AI assistants that need the standalone Debug CLI, use the stable installer URLs:

```bash
# macOS / Linux
curl -fsSL https://withpointbreak.com/install.sh | sh

# Windows (PowerShell)
irm https://withpointbreak.com/install.ps1 | iex
```

The installer source is retained in this repository:

- [macOS/Linux installer](https://github.com/withpointbreak/pointbreak-debug/blob/main/scripts/install.sh)
- [Windows installer](https://github.com/withpointbreak/pointbreak-debug/blob/main/scripts/install.ps1)

Those scripts download the historical Debug CLI from `download.withpointbreak.com`. This public
repository does not publish GitHub Releases. Raw URLs under the former unsuffixed repository slug
are unsupported after that slug is reused; use the stable website URLs above or the explicit Debug
source URLs.

## Support and security

- [Report a Pointbreak Debug bug](https://github.com/withpointbreak/pointbreak-debug/issues/new?template=bug_report.yml)
- [Ask a question](https://github.com/withpointbreak/pointbreak-debug/issues/new?template=question.yml)
- [Join a discussion](https://github.com/withpointbreak/pointbreak-debug/discussions)
- Read the [security policy](SECURITY.md) before reporting a vulnerability

The legacy hosted Debug documentation is being retired. New Pointbreak documentation will describe
the new product and will not serve these Debug instructions under the same identity.

## License

Pointbreak Debug binaries are proprietary software governed by the [Pointbreak Debug EULA](LICENSE).
This repository's visibility does not grant an open-source license to the historical binaries or
their private source code.

Copyright (c) 2025 Kevin Swiber. All rights reserved.
