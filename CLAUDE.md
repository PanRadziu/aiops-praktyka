# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A training repo ("AIOps w praktyce", Sages). Two parts:
- `app/` — **Kantyna**, a canteen ordering system (microservices, deployed to EKS). Most code lives here. See `app/README.md` for the full service/endpoint/env-var reference.
- `labs/`, `docs/`, `setup/` — Polish-language lab instructions, materials and the environment check script. Lab READMEs are instructions for participants, not code to change.

Participants work in their own forks and in their own Kubernetes namespace on a shared cluster. Don't touch other namespaces.

## Commands

All app commands run from `app/` (the Makefile lives there).

```bash
# Local stack (Postgres, payments, orders-api :8000, worker, web UI :8088)
docker compose up -d --build
docker compose --profile loadgen up -d loadgen   # optional synthetic traffic

# Tests
make test                 # both suites
make test-orders-api      # = cd orders-api && uv run pytest -q
make test-payments        # go test in golang:1.23 container (no local Go needed)

# Single Python test (pytest config lives in orders-api/pyproject.toml)
cd orders-api && uv run pytest -q tests/test_api.py::<test_name>
cd orders-api && uv run pytest -q tests/test_flags.py

# Single Go test
docker run --rm -v "$PWD/payments:/src" -w /src golang:1.23 go test -run <TestName> ./...

# Helm
make helm-lint
make helm-template REGISTRY=<registry> VERSION=1.0.0

# Images (ECR; `make ecr-login` first). VARIANT adds a second tag, e.g. 1.1.0-receipt-v2
make build push VERSION=1.1.0 VARIANT=receipt-v2

# Environment check for a participant's namespace (from repo root)
setup/check.sh            # expects "SUKCES: 11/11"
```

Dependencies: orders-api uses `uv` with `uv.lock`; worker and loadgen use `requirements.txt`; payments is plain Go (`go.mod`).

## Architecture (big picture)

**Request path.** Browser → `web` (nginx serving `app/web/html`, proxies `/api/*` to `orders-api`) → `orders-api` (FastAPI, Postgres via psycopg pool) → `payments` (Go, `POST /pay`). An order is only written to Postgres after payments accepts it, in one transaction. After commit, if `QUEUE_URL` is set, `orders-api` publishes to SQS.

**Async path.** `worker` long-polls SQS, "prepares" the order and writes a JSON receipt to S3 (`receipts/YYYY/MM/DD/<order_id>.json`). Failed messages return to the queue and go to the DLQ after 5 receives. Locally `QUEUE_URL` and `RECEIPTS_BUCKET` are unset, so the worker idles.

**Traffic.** `loadgen` replays a daily traffic curve (`app/loadgen/app/curve.py`, Europe/Warsaw time, weekend factor) against `orders-api`. It is only a traffic source; it has no effect on the order logic.

**Runtime flags (the chaos/resilience switches).** Each service reads a `flags.json` (per-service sections: `orders-api`, `payments`, `worker`) and re-reads it about every 15 seconds, so no restart is needed. Locally the file is `app/deploy/local/flags.json`, mounted into containers. On Kubernetes it is the ConfigMap `kantyna-flags`, rendered from the `flags:` block in `app/deploy/helm/kantyna/values.yaml`. Env vars are the fallback; file values win when present. The flag names are defined in `orders-api/app/flags.py` (`_SPEC`), `payments/flags.go`, and `worker/app/flags.py`. Keep the local JSON, Helm `values.yaml`, and these definitions in sync when adding a flag. Injected behaviour (error rate, latency, memory leak, CPU burn, DB pool leak, slow menu query) lives in `orders-api/app/runtime.py`, and the observability middleware in `orders-api/app/main.py` applies it.

**Build variants.** `APP_VARIANT` (`stable`, `receipt-v2`, `menu-v2`) is baked in at build time and reported by `/version`, metrics and logs. `orders-api/Dockerfile.legacy` is a separate Python 3.9 image built from `requirements-legacy.txt`.

**Observability is part of the app.** Every service exposes `/metrics` (Prometheus). `orders-api` emits JSON logs with `trace_id`, and OpenTelemetry traces (`telemetry.py`). Alert rules are in `deploy/helm/kantyna/templates/prometheusrule.yaml`, and each alert's `runbook_url` points to `app/runbooks/`. Runbooks there also define "safe" vs "caution" actions for on-call.

**Kubernetes.** Helm chart `app/deploy/helm/kantyna` (one release per namespace). AWS access for `orders-api` and `worker` comes from IAM roles bound to their ServiceAccounts through EKS Pod Identity, not from secrets in the chart.

## Things to know before changing code

- `app/.env` contains **fake** credentials for exercises; it is committed on purpose. Don't treat it as real and don't copy real secrets into the repo or into prompts.
- `.claude/settings.json` sets the permission policy for this repo: `kubectl get/describe/logs/top` allowed; `kubectl set/patch/edit/rollout/apply` ask first; `kubectl delete`, `kubectl exec`, and any secret reads are denied. Don't work around these.
- The `.github/` workflows referenced in labs (lab03) are not in this repo's tracked files; participants create them in their forks.
- Lab READMEs describe exercises with a success condition (`SUKCES`). Changing the app to fix a lab deliberately breaks it, so check the lab before "fixing" something that looks like a bug.

## Tooling versions

Versions checked on the local machine (2026-11-25):
- Helm: `v3.17.3` (`helm version --short`)
- kubectl (client): `v1.35.9` (`kubectl version --client`)

Use these as the baseline when writing Helm or kubectl commands. Check again with the commands above if behaviour differs.

## Checking changes

- Check Helm chart changes with: `helm lint app/deploy/helm/kantyna`
- Never run `kubectl delete`, even if a task seems to require it. Ask the user first.
