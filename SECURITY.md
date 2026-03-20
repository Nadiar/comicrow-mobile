# Security Policy

## Reporting a Vulnerability

If you find a security vulnerability in ComicRow, please report it responsibly:

1. **Do not** open a public issue
2. Email the maintainer or use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
3. Include steps to reproduce and potential impact

You should receive a response within 7 days.

## Scope

ComicRow is a client application that connects to OPDS servers. Security concerns include:

- Credential storage and transmission
- Handling of untrusted server responses (XML/JSON parsing)
- Local file storage and cache management

## Supported Versions

Only the latest version receives security updates.
