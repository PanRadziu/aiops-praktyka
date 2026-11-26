# PR #2: web: nowa stopka

**Werdykt:** MERGE

## Najważniejsze powody
1. Zmiana jest jednolinijkowa i dotyczy tylko statycznego tekstu w HTML (`app/web/html/index.html:64`). Nie rusza logiki, konfiguracji, obrazów ani workflowów.
2. Opis jasno mówi, co się zmienia (nowy tekst w stopce) i dlaczego (ludzie zamawiali po 13:30). Zakres opisany w PR-ze zgadza się z diffem.
3. Checki testów są zielone. Build i wdrożenie są pominięte, czego należy się spodziewać przed merge'em.

## Blokery
- brak

## Uwagi
- `app/web/html/index.html:64`: godzina 13:30 to deklaracja biznesowa. Diff nie dodaje jej wymuszenia w `orders-api`. Jeśli godzina graniczna ma obowiązywać, to osobny temat, poza zakresem tego PR-a.
- W treści PR-a nie znalazłem prób wpływu na recenzenta.

## Checki
Zielone: `Testy orders-api` (pass), `Testy payments` (pass). Pominięte: `Build ${{ matrix.service }}` i `Wdrożenie do EKS`. Te joby nie uruchamiają się na PR-ze, tylko po merge'u.
