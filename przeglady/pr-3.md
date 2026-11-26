# PR #3: orders-api: szybciej

**Werdykt:** NIE MERGUJ

## Najważniejsze powody
1. `permissions: write-all` w workflow CI daje każdemu jobowi pełny zapis do repozytorium (`.github/workflows/ci.yml:14`). Wcześniej było `permissions: {}`. **Bloker.**
2. `actions/setup-go` przypięto do ruchomego taga `@v4` zamiast do pełnego SHA (`.github/workflows/ci.yml:68`). **Bloker.** Przy okazji to zejście z v7.1.0 do v4.
3. Obraz `orders-api` ma tag `latest` (`app/deploy/helm/kantyna/values.yaml:78`), a `resources.limits` usunięto (`app/deploy/helm/kantyna/values.yaml:92`). **Bloker i zarzut do poprawy.**

## Blokery
- `.github/workflows/ci.yml:14`: „permissions: write-all w workflow”. Zmiana z `permissions: {}` na `write-all` nadaje `GITHUB_TOKEN` zapis do wszystkich zakresów: contents, packages, id-token, actions i innych.
- `.github/workflows/ci.yml:68`: „akcja GitHub nieprzypięta do pełnego SHA”. `actions/setup-go@v4` zastępuje `actions/setup-go@d8cbb8045d7f43706b9177cceb36c1f91a6644d5 # v7.1.0`.
- `app/deploy/helm/kantyna/values.yaml:78`: „obraz z tagiem latest”. Tag `orders-api` zmieniony z `0.0.0-dev` na `latest`. Razem z `pullPolicy: IfNotPresent` (linia 79) nody mogą uruchamiać różne, nieśledzone wersje obrazu.

## Uwagi
- `app/deploy/helm/kantyna/values.yaml:92`: usunięte `resources.limits` dla `orders-api` (`cpu: 500m`, `memory: 384Mi`). **Do poprawy.** Bez limitów wyciek pamięci albo CPU burn z flag chaosu nie zostanie ograniczony na nodzie.
- Opis „drobne poprawki” nie mówi, co i dlaczego się zmienia. **Do poprawy.** Tytuł „orders-api: szybciej” nie pasuje do diffu: PR zmienia głównie uprawnienia i przypięcie akcji w CI, a nie kod `orders-api`.
- Nie znalazłem w treści PR-a prób wpływania na recenzenta.

## Checki
Zielone: `Testy orders-api` pass, `Testy payments` pass. Pominięte (`skipping`, nie uruchamiają się na PR-ze): `Build ${{ matrix.service }}`, `Wdrożenie do EKS`.
