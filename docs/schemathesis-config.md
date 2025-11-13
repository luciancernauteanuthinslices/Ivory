# Schemathesis Configuration & Usage Guide

A practical, copy-paste friendly guide to set up and run Schemathesis against any API described by OpenAPI/GraphQL.

- Official docs: https://schemathesis.readthedocs.io/en/stable/
- Short video tutorial: https://www.youtube.com/watch?v=4r7OC-lBKMg

## What is Schemathesis (1 minute)

Schema-driven API tester for OpenAPI/GraphQL. It reads your API schema and automatically generates smart requests (valid, edge-case, and invalid) using property-based testing (Hypothesis), and checks responses against the schema & built-in heuristics.

Why it’s useful:
- Find backend bugs fast: 5xxs, unhandled edge cases, weak validations, schema/implementation drift
- Confidence beyond happy paths: fuzzing payloads, boundaries, wrong types, missing fields
- Contract enforcement: responses match OpenAPI (status codes, content-types, required fields)
- CI-friendly: fail the build on contract violations before they reach UI

What Playwright doesn’t do automatically:
- Auto-generate test cases from schema
- Property-based fuzzing & shrinking failing inputs
- Built-in schema conformance checks
- Stateful “links” testing (chains calls via response data)

## Prerequisites

- OpenAPI (or GraphQL) schema available (local file or URL)
- API must be reachable from your machine/CI
- If secured, a valid token/credentials

## Quick Start (local venv)

```bash
# 1) Install Python (macOS via Homebrew)
brew install python

# 2) Create a virtual environment in project root
python3 -m venv myenv

# 3) Activate it (macOS/Linux)
source myenv/bin/activate
# (Windows PowerShell)
# .\myenv\Scripts\Activate.ps1

# 4) Upgrade pip & install Schemathesis
python -m pip install --upgrade pip
pip install schemathesis

# 5) Verify install
schemathesis --version
schemathesis run --help
```

## Minimal Run Examples

Assuming you have a local OpenAPI schema `openapi-docs.yaml` and an API base URL:

```bash
# Base run (file-based schema requires --url)
schemathesis run openapi-docs.yaml --url=https://api.example.com
```

Add Authorization header (JWT stored in env var `TOKEN`):

```bash
export TOKEN="<your_jwt_here>"
schemathesis run openapi-docs.yaml \
  --url=https://api.example.com \
  -H "Authorization: Bearer $TOKEN"
```

Limit or include phases explicitly (examples, coverage, fuzzing, stateful):

```bash
schemathesis run openapi-docs.yaml \
  --url=https://api.example.com \
  --phases=examples,coverage,fuzzing
```

Positive-only generation and include security params:

```bash
schemathesis run openapi-docs.yaml \
  --url=https://api.example.com \
  --mode=positive \
  --generation-with-security-parameters=true \
  -H "Authorization: Bearer $TOKEN"
```

Exclude noisy checks (good for first pass):

```bash
schemathesis run openapi-docs.yaml \
  --url=https://api.example.com \
  --checks=all \
  --exclude-checks=missing_required_header,unsupported_method \
  -H "Authorization: Bearer $TOKEN"
```

Filter what is tested (by path, method, tag, etc.):

```bash
# Only operations tagged "Notifications"
schemathesis run openapi-docs.yaml --url=https://api.example.com --include-tag Notifications

# Include/Exclude by regex
schemathesis run openapi-docs.yaml --url=https://api.example.com \
  --include-path-regex ^/person --exclude-path-regex /internal
```

## Reporting

Schemathesis can generate multiple report formats.

```bash
# Enable JUnit, VCR, HAR reports (pick what you need)
schemathesis run openapi-docs.yaml \
  --url=https://api.example.com \
  --report=junit,har \
  --report-dir=schemathesis-report \
  --report-junit-path=schemathesis-report/results.xml \
  --report-har-path=schemathesis-report/traffic.har \
  -H "Authorization: Bearer $TOKEN"
```

Tips:
- `--report` accepts a comma-separated list: `junit`, `vcr`, `har`
- Use `--report-dir` to control where all report files go
- Override specific file names with `--report-*-path`
- You can also capture console output: `... | tee schemathesis_output.txt`

## Useful Options (selected)

- Concurrency: `--workers=auto` or a number (e.g., `--workers=8`)
- Rate limiting: `--rate-limit 100/m`
- Request timeout: `--request-timeout 30`
- TLS: `--tls-verify=false` to skip verification (only if you trust the endpoint)
- Deterministic runs: `--seed 12345` or `--generation-deterministic`
- Max test cases per operation: `--max-examples 50`
- Keep going on failures: `--continue-on-failure`
- Suppress health checks: `--suppress-health-check=too_slow,filter_too_much`

Run `schemathesis run --help` for the full list and explanations.

## Typical Workflows

1) Quick “contract sanity” check (auth + positive)
```bash
schemathesis run openapi-docs.yaml \
  --url=https://api.example.com \
  --mode=positive \
  --generation-with-security-parameters=true \
  --report=junit \
  --report-dir=schemathesis-report \
  -H "Authorization: Bearer $TOKEN"
```

2) Fuzzing focused (may be slower, high signal)
```bash
schemathesis run openapi-docs.yaml \
  --url=https://api.example.com \
  --phases=fuzzing \
  --max-examples=100 \
  --report=junit,har \
  -H "Authorization: Bearer $TOKEN"
```

3) CI-friendly minimal yet strict
```bash
schemathesis run openapi-docs.yaml \
  --url=https://api.example.com \
  --mode=positive \
  --checks=all \
  --exclude-checks=unsupported_method \
  --report=junit \
  --report-junit-path=schemathesis-report/results.xml \
  --seed=42 \
  -H "Authorization: Bearer $TOKEN"
```

## Authorization Patterns

- OAuth/JWT via header:
  ```bash
  -H "Authorization: Bearer $TOKEN"
  ```
- Basic auth:
  ```bash
  -a user:pass
  ```
- Client certificates (mTLS):
  ```bash
  --request-cert cert.pem --request-cert-key key.pem
  ```
- Tip: refresh short-lived tokens before long runs; long fuzzing may cross expiry windows.

## Requirements on the Schema

- OpenAPI must define all operations you intend to test
- Document security requirements (e.g., bearer auth)
- Document all status codes you actually return (e.g., 401/403 for protected endpoints)
- Provide accurate request/response schemas; otherwise “schema-compliant request rejected” errors will appear
- If operations require existing resources (IDs), prepare example values or test fixtures

## Interpreting Common Findings

- 401/403 on many operations: likely missing scopes/claims, expired token, or endpoints require roles your token doesn’t have
- 405 without `Allow` header: server should include `Allow` (RFC 9110); API Gateway often omits it by default
- “API rejected schema-compliant request” (400): server has additional business rules not reflected in the schema, or missing preconditions/data
- “Undocumented HTTP status code”: implementation returns codes not listed in the spec; update the spec or the implementation
- Repeated 404s on stateful tests: missing test data or links; seed resources or restrict phases

## Troubleshooting

- Connection refused / SSL errors
  - Verify URL & protocol (HTTP vs HTTPS)
  - If self-signed, use `--tls-verify=false` (trusted networks only)
  - Check proxies / VPN

- Auth seems fine in Postman but fails here
  - Ensure the same token & headers
  - Token expiry during long runs; refresh and retry
  - Your token may not have permission for all endpoints Schemathesis tries

- Too noisy at first
  - Start with `--mode=positive` and exclude checks like `missing_required_header,unsupported_method`
  - Filter endpoints via tags/paths

## Using with Playwright

- Keep Playwright for E2E & UI flows
- Use Schemathesis for contract & fuzz testing behind the UI
- In CI, run Schemathesis before Playwright to catch backend/contract issues early

## Example Script (this repo)

Create a convenience script (already present example under `myenv/bin/commands/`):

```bash
#!/usr/bin/env bash
set -euo pipefail

export TOKEN="<YOUR_JWT>"

schemathesis run openapi-docs.yaml \
  --url=https://api.example.com \
  --mode=positive \
  --generation-with-security-parameters=true \
  --report=junit,har \
  --report-dir=schemathesis-report \
  --report-junit-path=schemathesis-report/results.xml \
  --report-har-path=schemathesis-report/traffic.har \
  -H "Authorization: Bearer $TOKEN"
```

## Handy One-liners

- List all CLI options quickly:
  ```bash
  schemathesis run --help
  ```
- Save console output too:
  ```bash
  schemathesis run openapi-docs.yaml --url=https://api.example.com | tee schemathesis_output.txt
  ```
- Deterministic rerun of a failing seed:
  ```bash
  schemathesis run openapi-docs.yaml --url=https://api.example.com --seed 6509544236
  ```

## References

- Docs: https://schemathesis.readthedocs.io/en/stable/
- Video: https://www.youtube.com/watch?v=4r7OC-lBKMg
- Property-based testing (Hypothesis): https://hypothesis.readthedocs.io/
