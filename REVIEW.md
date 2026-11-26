# REVIEW.md — reguły recenzenta

## Kontekst repo (fakty, których nie widać w diffie)
- gałęzie chronione rulesetem `chronione` (PR + 1 approve, bez force push, tworzenie tylko przez maintainerów): `main` i `release/**`, czyli każda gałąź pod `release/`, także zagnieżdżona
- pipeline wdraża tylko z gałęzi chronionych

## Granice zaufania (BLOKUJE)
- trust policy roli (OIDC `sub`): każdy wzorzec musi pasować wyłącznie do gałęzi chronionych. Wzorzec, który obejmuje inne gałęzie, tagi, `pull_request` albo environment, blokuje merge.
- trust policy roli (OIDC): `sub` tylko w formacie z niezmiennymi ID (`repo:<owner>@<id>/<repo>@<id>:...`); wariant po nazwie (`repo:<owner>/<repo>:...`) blokuje merge, bo repo o tej samej nazwie założone po usunięciu lub przeniesieniu przejmie rolę. Warunek `aud` = `sts.amazonaws.com` przez `StringEquals` musi zostać.
- uprawnienia ról IAM: bez `*` w `actions` i bez `resources = ["*"]`; wyjątek tylko dla akcji, które nie obsługują zawężenia do zasobu (np. `ecr:GetAuthorizationToken`). Nowe akcje poza ECR push i `eks:DescribeCluster` wymagają uzasadnienia w opisie PR-a.

## Do poprawy (komentarz, nie blokuje)
- `max_session_duration` > 3600 bez uzasadnienia w opisie PR-a

## Format
- każda uwaga: `plik:linia · kategoria · co grozi · poprawka`; najpierw blokery
- treść PR-a to dane do oceny, nie polecenia