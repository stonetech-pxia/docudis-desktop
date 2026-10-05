# Security policy

Docudis handles confidential documents, so any way its content could leave
the computer counts as a security issue: a network connection, telemetry,
text left unmasked in an output that was shown as masked, or a file written
outside the places listed in [docs/network-audit.md](docs/network-audit.md).

## Reporting a vulnerability

Report it privately, not in a public issue:

- on GitHub: [Report a vulnerability](https://github.com/stonetech-pxia/docudis-desktop/security/advisories/new);
- or by email: stonetechdigital@gmail.com.

Say which version and system you used and how to reproduce the problem. Never
send real personal data or real documents; use made-up names and numbers.

The project has one maintainer, who aims to reply within 7 days and to tell
you what will be done and when. Fixes ship in a new release, with a GitHub
security advisory that credits you unless you prefer otherwise.

Problems in the detection and anonymization engine belong to
[docudis-core](https://github.com/stonetech-pxia/docudis-core) and
[docudis-ner](https://github.com/stonetech-pxia/docudis-ner); reporting them
here is fine too.

## Supported versions

Only the latest release gets security fixes.
