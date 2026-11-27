# Lab03 — dziennik

| # | Objaw (krok, komunikat) | Hipoteza (AI / ja) | Jak sprawdziłem | Poprawka | Status |
|---|---|---|---|---|---|
| 1 | `build`, krok `configure-aws-credentials`: `Not authorized to perform sts:AssumeRoleWithWebIdentity` (12 prób) | AI: trust policy roli nie pasuje do `sub` tokenu albo rola nie istnieje. Ja: `role/radoslaw` to nazwa mojego użytkownika IAM, nie roli | `aws sts get-caller-identity` (to `user/radoslaw`), `aws iam get-role` → AccessDenied; właściwą rolę znalazłem w AWS | `gh variable set AWS_ROLE_ARN` → `arn:aws:iam::574921529806:role/aiops-ci-radoslaw` | ✅ (log: `assumed-role/aiops-ci-radoslaw/GitHubActions`) |
| 2 | `build`, push do ECR: `denied: ... not authorized to perform: ecr:GetDownloadUrlForLayer on ... repository/kantyna/web` | AI: roli brakuje akcji odczytu ECR potrzebnych buildx. Ja: rola może mieć dostęp tylko do moich repozytoriów | `aws ecr describe-repositories` → każdy uczestnik ma `<login>/kantyna/<serwis>`, jest `radoslaw/kantyna/*` | `ECR_REGISTRY` z prefiksem `/radoslaw`; workflow bez zmian | ⏳ do potwierdzenia ponownym przebiegiem |

## Sugestia AI, której nie wdrożyłem

**Sugestia:** dodać do joba `deploy` tymczasowy krok, który dekoduje token OIDC i wypisuje w logu jego claims (`sub`, `aud`, `iss`). Celem było porównanie ich z trust policy roli przy błędzie `AssumeRoleWithWebIdentity`.

**Dlaczego nie:**
- Przyczynę dało się znaleźć bez zmiany pipeline'u. Zmienna `AWS_ROLE_ARN` wskazywała na `role/radoslaw`, czyli nazwę mojego użytkownika IAM, a nie rolę CI.
- Krok działa tylko przy przebiegu z `main`, więc każda próba oznaczałaby commit na `main` i pełne wdrożenie do namespace tylko po to, żeby coś zdiagnozować.
- Wypisywanie zawartości tokenu do logów to niepotrzebne odsłanianie szczegółów uwierzytelniania. Taki krok łatwo potem zostawić w workflow.
