# Schemathesis CLI — Developer Checklist

## 0) Quick start (baseline)

```bash
schemathesis run openapi-docs.yaml \
  -u "$BASE_URL" \
  --checks all --validate-schema --exclude-deprecated \
  --phases examples,coverage --mode all \
  -n 5 -w auto
```

**Flags:**

- `-u, --base-url` target API
- `--checks all` enable built-ins
- `--validate-schema` fail fast on bad OAS
- `--exclude-deprecated` skip deprecated
- `--phases examples,coverage` examples then generation
- `--mode all` cover all methods
- `-n 5` examples per op (speed vs depth)
- `-w auto` parallel workers

---

## 1) Auth & headers

```bash
# Bearer
token
-H "Authorization: Bearer $(cat .schemathesis_token)"

# API key
-H "X-API-Key: $API_KEY"

# Cookies
--cookies "session=$SID"
```

**Tip:** repeat `-H` for multiple headers; mask secrets in CI logs.

---

## 2) What to test (selection)

```bash
--methods GET,POST
--endpoints /users,/orders
--include-pattern "/(users|orders)"
--exclude-pattern "/admin|/internal"
--operation-id-pattern "^(GetUser|ListOrders)$"
--tags users,orders
```

---

## 3) Stateful testing (request chaining)

```bash
--stateful=links
```

Follows OAS links (e.g., create → get → delete) when your spec models them.

---

## 4) Stability, timeouts, reproducibility

```bash
--request-timeout 15
--connect-timeout 5
--hypothesis-seed 12345
--hypothesis-deadline 500
--hypothesis-verbosity normal
```

---

## 5) Output & artifacts (for CI / Allure)

```bash
--report=junit --report-file schemathesis-run/junit.xml
# or:
--report=junit --report-dir schemathesis-run

# Console log
> schemathesis-run/output.txt 2>&1
```

(For HAR/traffic, use your version’s network logging flag if available, or capture via proxy/app interceptor.)

---

## 6) Performance knobs

```bash
# Fast smoke
--phases examples -n 1 -w auto

# Balanced coverage
--phases examples,coverage -n 5 -w auto

# Debug single-threaded
-w 1
```

---

## 7) Inspect / dry runs

```bash
schemathesis inspect openapi-docs.yaml -u "$BASE_URL"   # list planned scope (version-dependent)
--verbosity fail                                       # only failures (version-dependent)
```

---

## 8) Ready-to-use profiles

### A) Smoke (fast)

```bash
schemathesis run openapi-docs.yaml -u "$BASE_URL" \
  --checks all --exclude-deprecated \
  --phases examples --mode all \
  -n 1 -w auto \
  --report=junit --report-file schemathesis-run/junit.xml
```

### B) Coverage (deeper)

```bash
schemathesis run openapi-docs.yaml -u "$BASE_URL" \
  --checks all --validate-schema --exclude-deprecated \
  --phases examples,coverage --mode all \
  -n 5 -w auto --stateful=links \
  --request-timeout 15 --connect-timeout 5 \
  --hypothesis-seed 12345 --hypothesis-deadline 500 \
  --report=junit --report-file schemathesis-run/junit.xml
```

### C) Targeted debug (single resource)

```bash
schemathesis run openapi-docs.yaml -u "$BASE_URL" \
  --methods POST \
  --include-pattern "/orders" \
  --phases examples,coverage \
  -n 3 -w 1 \
  --report=junit --report-file schemathesis-run/junit.xml
```

---

## 9) Env var cheat (drop in your runner)

```bash
BASE_URL="https://api.example.com"
SCHEMA="openapi-docs.yaml"
TOKEN="$(cat .schemathesis_token)"

schemathesis run "$SCHEMA" -u "$BASE_URL" \
  -H "Authorization: Bearer $TOKEN" \
  --checks all --exclude-deprecated \
  --phases examples,coverage --mode all \
  -n 5 -w auto \
  --report=junit --report-file schemathesis-run/junit.xml \
  > schemathesis-run/output.txt 2>&1
```

---

## 10) Gotchas & tips

- `--validate-schema` will fail fast on invalid schemas; fix or skip in smoke runs.
- `--stateful=links` needs proper links in OAS.
- Tune `-n` & `-w` for rate limits and CI time budgets.
- Redact secrets (e.g., `Authorization`) in any saved logs/HAR.
