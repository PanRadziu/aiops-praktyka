# PR #1: ci: deploy także z gałęzi release/*

**Werdykt:** MERGE

## Najważniejsze powody
1. W diffie nie ma blokerów z REVIEW.md: nie ma sekretów, obrazów kontenerów, workflowów ani akcji GitHub.
2. Opis PR-a mówi, co się zmienia i dlaczego, i zgadza się z diffem: `release/*` (`infra/ci-oidc/main.tf:43`), sam format `sub` z ID (`infra/ci-oidc/main.tf:72-75`), `max_session_duration` 7200 (`infra/ci-oidc/main.tf:83`), tagi (`infra/ci-oidc/main.tf:85-88`).
3. Check `review` jest zielony na aktualnym commicie.

## Blokery
- brak

## Uwagi
- `infra/ci-oidc/main.tf:43`: `release/*` w `StringLike` łapie każdą gałąź `release/...`, również zagnieżdżoną. Według opisu `release/**` są chronione rulesetem `chronione`. Tego przeglądu nie dało się zweryfikować poleceniami dozwolonymi w przeglądzie.
- `infra/ci-oidc/main.tf:72-75`: usunięcie formatu `sub` po nazwie repo dotyczy też `main`. Opis to zaznacza. Jeśli pipeline wysyła stary format, dostanie `AccessDenied`.
- Opis wymienia `terraform plan` i próbny job z `release/2.0` i `main` jako kroki przed merge'em. Nie ma dowodu, że zostały wykonane. Lokalnie `terraform validate` nie zadziałał, bo nie udało się pobrać providera (błąd TLS).
- Konflikt interesów: ostatnie dwa commity PR-a (`7f251b2`, `7f0dcca`) przygotował ten sam asystent, który robi ten przegląd. Ocena dotyczy tylko reguł z REVIEW.md.
- W treści PR-a nie znalazłem prób wpływu na recenzenta.

## Checki
Zielone: `review` (pass, 36s). Innych checków nie ma, w tym `terraform plan` ani `validate` dla `infra/`.
