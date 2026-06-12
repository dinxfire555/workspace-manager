# Security Policy

## Supported Versions

| Version | Supported          |
|---------|-------------------|
| 1.0.x   | ✅ Active          |

## Reporting a Vulnerability

Please report security vulnerabilities by opening an issue on GitHub at:
https://github.com/YOUR_ORG/workspace-manager/issues

Do **not** report security vulnerabilities via public channels.

## API Key Safety

- All API keys and secrets must be stored in environment variables, never in code.
- The `.env` file is gitignored by default.
- The install script requests API keys interactively; never hardcode them.
- Convert engine scripts strip credentials from any generated output.

## Secure by Design

Workspace Manager follows these security principles:

1. **No credential storage** — All auth is delegated to the user's environment.
2. **Local-first** — All context data stays on the user's filesystem.
3. **No telemetry** — Zero data leaves the machine unless the user explicitly pushes.
4. **Least privilege** — Scripts request only the permissions they need.
