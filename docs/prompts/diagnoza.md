# Diagnoza awarii

Skopiuj blok niżej i uzupełnij pola `<...>`. Dane wklejaj przycięte i zredagowane (bez haseł, kluczy, danych osobowych).

```text
Jesteś SRE. Środowisko: EKS 1.36 (serwer v1.36.5, nody v1.36.1), namespace kantyna, komponent orders-api w wersji 1.0.0 (wariant default), zależności: postgres 17 i payments.
Objaw: $ARGUMENTS Zbierz dane komendami read-only (kubectl get/describe/logs). Zredaguj sekrety przed analizą.
Dane:
lab01b/awaria-zred.txt
Już sprawdziłem: Ingress i Service web działają, web zwraca stronę. Błąd pojawia się dopiero przy wywołaniu orders-api.
Zadanie: podaj 3 najbardziej prawdopodobne hipotezy, od najbardziej prawdopodobnej.
Ograniczenia: proponuj tylko komendy read-only. Nie proponuj jeszcze poprawki.
Jeśli brakuje danych, napisz, jakiej komendy potrzebujesz, zamiast zgadywać.
Format: tabela | hipoteza | dowód z danych powyżej | komenda weryfikująca |.
```
