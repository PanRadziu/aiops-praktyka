Trzy różnice między zly.yaml a dobry.yaml:

1. Obraz. W zly.yaml jest orders-api:latest, bez registry i z tagiem latest, więc nie wiadomo skąd i która wersja. W dobry.yaml jest pełny adres ECR z values.yaml i przypięty tag 0.0.0-dev.
2. Hasło do bazy. W zly.yaml hasło jest wpisane jawnie w DATABASE_URL (changeme). W dobry.yaml DATABASE_URL składa się z DB_USER i DB_PASSWORD, które pochodzą z Secretu kantyna-db przez secretKeyRef.
3. Port, probe i reszta konfiguracji. W zly.yaml jest port 8080 i ścieżka /health, a w dobry.yaml port 8000 z /healthz i /readyz, jak w szablonie chartu. zly.yaml nie ma też securityContext (non-root, read-only rootfs), adnotacji Prometheus, etykiet ani serviceAccountName.

Czego walidator (kubectl apply --dry-run=server) nie sprawdził: nie sprawdza, czy obiekty, do których manifest się odwołuje, istnieją. dobry.yaml odwołuje się do Secretu kantyna-db, ConfigMapy kantyna-flags i ServiceAccount kantyna-orders-api. Jeśli release nie nazywa się kantyna, dry-run przejdzie, a pod nie wystartuje. Sprawdzić to można przez kubectl get secret,configmap,sa -n <login>.

Dry-runu jeszcze nie uruchamiałem dla żadnego z plików, więc powyższe to wnioski z treści manifestów, a nie wynik walidatora.

Diagnoza awarii (awaria-zred.txt): brakujące dane, o które poprosił claude.

1. Zona PV pvc-3e8a91c4-27d5-4b0f-9c6e-5a1f0d7b2e48. Potrzebna komenda: kubectl get pv pvc-3e8a91c4-27d5-4b0f-9c6e-5a1f0d7b2e48 -o jsonpath='{.spec.nodeAffinity}'. Bez tego nie wiadomo, w której zonie jest wolumen, a nody w dumpie są wszystkie w eu-central-1a.
2. Pełny opis StatefulSetu kantyna-postgres (nodeSelector, tolerations, affinity). Potrzebna komenda: kubectl -n kantyna get statefulset kantyna-postgres -o yaml. W dumpie jest tylko fragment opisu poda.
3. Endpointy Service kantyna-postgres. Potrzebna komenda: kubectl -n kantyna get endpoints kantyna-postgres. Potwierdziłaby, że przyczyną jest brak poda postgresa, a nie błędna konfiguracja Service.
4. Tainty i etykiety nodów nowej node group. Potrzebna komenda: kubectl describe node <nazwa>. Dotyczy hipotezy 3, która jest słabo poparta.

