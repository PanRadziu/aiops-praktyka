# lab02 — dziennik diagnozy

## Dziennik

| # | Objaw | Hipoteza (kto: AI / ja / k8sgpt) | Komenda weryfikująca | Wynik | Status | Poprawka |
|---|-------|----------------------------------|----------------------|-------|--------|----------|
| 1 | `kantyna-web`: gotowe 0/2, pody `ImagePullBackOff` | AI: obraz `kantyna/web:1.0.1` nie istnieje w ECR (tag ustawiony przez `kubectl set image` o 13:22) | `aws ecr describe-images --repository-name kantyna/web --image-ids imageTag=1.0.1 --region eu-central-1 --profile aiops` | `ImageNotFoundException`; w repo są tagi `1.0.0`, `1.1.0`, `1.3.0`… | ✅ | `helm upgrade` z wartościami release'u → obraz `web:1.0.0` (rewizja 2) |
| 2 | `kantyna-orders-api`: `CrashLoopBackOff`, w logach `psycopg.pool … Name or service not known` | AI: zła nazwa hosta bazy w konfiguracji orders-api (Postgres działa) | `kubectl -n radoslaw get rs kantyna-orders-api-b4f48b774 -o jsonpath='{.spec.template.spec.containers[0].env}'` | `DATABASE_URL=postgresql://…:***@kantyna-postgresql:5432/kantyna`, a Service nazywa się `kantyna-postgres` | ✅ | Naprawione przy okazji `helm upgrade` z p. 1 (szablon przywrócił `kantyna-postgres`) |
| 3 | `kantyna-worker`: `FailedCreate … exceeded quota: participant-quota, requested: requests.memory=2Gi` | AI (uwaga poboczna, bez diagnozy): request pamięci podniesiony ponad quotę | `kubectl -n radoslaw get rs kantyna-worker-54d954f566 -o jsonpath='{.spec.template.spec.containers[0].resources}'` | `requests.memory: 2Gi` przy quocie `2560Mi` i zużyciu `960Mi`; obecny RS: `128Mi` | ✅ | Naprawione przy okazji `helm upgrade` z p. 1 (szablon przywrócił `128Mi`/`256Mi`) |
| 4 | `check.sh`: menu i zamówienie przez web — `command terminated with exit code 1` | AI: NetworkPolicy `kantyna-orders-api-ingress` wpuszcza do orders-api tylko `app.kubernetes.io/name=frontend`, a web ma `name=web` | `kubectl -n radoslaw get pods -l app.kubernetes.io/name=frontend` + logi web: `upstream timed out … while connecting to upstream 172.20.195.19:8000` | `No resources found`; pody `web` istnieją | ✅ | `kubectl patch networkpolicy` → `from.podSelector: app.kubernetes.io/name=web` |

## 5. Podsumowanie: sugestie AI błędne, wymagające uprawnień lub niewdrożone

### Awaria 1: obraz `web:1.0.1`

- **Błędna sugestia:** hipoteza 2 (węzeł nie ma uprawnień IAM do pobrania z ECR). Odrzucona, bo ECR zwrócił `ImageNotFoundException`: problemem był brak obrazu, a nie autoryzacja.
- **Brak uprawnień:** pierwotny komunikat błędu pulla wygasł z eventów, więc do rozstrzygnięcia potrzebny był dostęp do AWS. Pierwsze `aws ecr describe-images` skończyło się `NoCredentials`, bo AI nie podało profilu `aiops`. Dopiero z `--profile aiops` dało się potwierdzić przyczynę.
- **Niewdrożone:**
  - Wariant A (zbudować i wypchnąć `web:1.0.1`): nie wiadomo było, czy wersja 1.0.1 jest gotowa do wydania.
  - Szybkie `kubectl set image`: odrzucone, bo tworzy rozjazd z Helmem, czyli dokładnie ten mechanizm, który spowodował awarię.

### Awaria 2: orders-api, zły host bazy

- **Błędna sugestia:** AI zaproponowało sprawdzenie zmiennej `DB_HOST`. Taka zmienna nie istnieje; host jest w `DATABASE_URL`.
- **Niezgodność z zasadą „jedna zmiana naraz”:** ta awaria została naprawiona przy okazji `helm upgrade` dla awarii 1, a nie osobną, świadomą zmianą. Przyczynę potwierdziłem dopiero po fakcie, porównując ReplicaSety.
- **Sekrety:** `DATABASE_URL` zawiera hasło. W dzienniku jest zastąpione `***` (to dane ćwiczeniowe, ale zasada obowiązuje).

### Awaria 3: worker ponad quotą

- **Brak diagnozy:** AI zanotowało tę awarię tylko jako „uwagę poboczną” i nie przedstawiło dla niej hipotez.
- **Niezgodność z zasadą „jedna zmiana naraz”:** naprawiona przy okazji `helm upgrade` dla awarii 1. Przyczynę potwierdziłem po fakcie.

### Awaria 4: NetworkPolicy blokuje web → orders-api

- **Błędna sugestia (najważniejsza w tym labie):** AI uznało za najbardziej prawdopodobną przyczynę konflikt `inbound-cidrs` na Ingressie/ALB i zaproponowało przeniesienie Ingressu do osobnej grupy ALB. Ta sugestia była błędna:
  - ALB nie ma tu znaczenia.
  - Ruch z zewnątrz działał mimo konfliktu: w logach web są żądania `200` przez stary ALB.
  - Zmiana zepsuła dostęp z zewnątrz (`404`). Wymagała rollbacku i dodatkowej poprawki (rewizje 4 i 5).
- **Brak uprawnień:**
  - `kubectl exec` jest zablokowany dla agenta, więc AI nie mogło samo uruchomić `check.sh` ani testu `wget`.
  - `targetgroupbindings` i `ingressclasses`: `Forbidden` dla użytkownika `radoslaw`. AI nie mogło sprawdzić stanu targetów ALB.
- **Niewdrożone:**
  - Usunięcie NetworkPolicy: odrzucone, bo `kubectl delete` jest zabroniony w repo, a polityka ma sens jako izolacja orders-api. Wybrałem `patch` selektora.
  - Wyrównanie `inbound-cidrs` z listą `ai/litellm` było początkowo odłożone, bo wymagało zgody innego zespołu (później wdrożone przy naprawie mojej własnej zmiany, poza zakresem tego dziennika).

## Wynik

- `setup/check.sh` po zmianie NetworkPolicy: **`SUKCES: 11/11`** (2026-11-25).

## Otwarte

- Polityka wpuszcza na port 8000 tylko pody `web` z namespace `radoslaw`. Jeśli Prometheus z innego namespace scrapuje `/metrics` orders-api, będzie zablokowany: osobny objaw do osobnej diagnozy.
