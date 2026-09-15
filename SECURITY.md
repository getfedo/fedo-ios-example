# Security Policy

## Supported versions

Security fixes go to the latest release and to `main`. Older releases are not supported; update to the latest release.

| Version                  | Supported |
| ------------------------ | --------- |
| 0.3.x (latest release)   | Yes       |
| `main`                   | Yes       |
| Older releases           | No        |

## Reporting a vulnerability

**Do not report security vulnerabilities through public issues, discussions or pull requests.**

Report them privately with GitHub private vulnerability reporting:
https://github.com/getfedo/fedo-ios-example/security/advisories/new

The maintainers will follow up in the private advisory.

## What to include

- A description of the vulnerability and its impact
- Steps to reproduce or a proof of concept
- Affected files and the commit SHA you tested
- iOS version, device or simulator, and FedoKit version

## Never share secrets

Never paste Fedo API keys, the contents of `Secrets.xcconfig`, or any other credentials in issues, pull requests, discussions or advisory reports. Redact them from logs and screenshots. If a key was exposed, rotate it in Fedo right away.

## FedoKit SDK vulnerabilities

This repository only contains the example app. Report vulnerabilities in the FedoKit SDK itself to the Fedo team at https://getfedo.com, not here.
