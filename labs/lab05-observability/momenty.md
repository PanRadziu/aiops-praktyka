## Krok 0 (bez podłączenia)
ile zdążyłem: 3 z 3
co zajęło najwięcej czasu: szukanie nazwy metryki i etykiet (http_requests_total, namespace, route)
ile razy kopiowałem coś między Claude a Grafaną: 3

## Krok 3 (momenty z ostatnich 4 dni, namespace demo, czas polski)
wt 24.11 11:35–12:15 | p95 POST /api/orders 2,4 s zamiast ~0,048 s (50× wolniej); w logach brak błędów, czyli samo opóźnienie | histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{namespace="demo", route="/api/orders", method="POST"}[5m])))
wt 24.11 13:05–14:45 | kolejka workera rośnie z 0 do ~10 600 wiadomości: worker przetwarza 0,46 msg/s przy ~4,5 zamówienia/s (13:05–13:45), potem nadrabia 5,4 msg/s i kolejka spada do 0 o 14:45 | max(worker_queue_visible_messages{namespace="demo"})  +  sum(rate(worker_messages_processed_total{namespace="demo"}[5m]))
wt 24.11 14:30–15:05 | ~570 nieudanych płatności (reason="gateway_error", ~95 na 5 min); Loki: 576× "Payment failed for order" | sum by (reason) (increase(payments_failed_total{namespace="demo"}[5m]))  /  {namespace="demo", app="orders-api"} | json | level=~"ERROR|WARNING"
wt 24.11 19:05–19:35 | pamięć orders-api skacze z ~78 MiB do kilkuset MiB (max w godzinie ~1,8 GB), 4 restarty każdego z 2 podów (wyciek pamięci → OOM) | sum by (pod) (max_over_time(container_memory_working_set_bytes{namespace="demo", container="orders-api"}[1h]))  +  sum by (pod) (increase(kube_pod_container_status_restarts_total{namespace="demo"}[1h]))
śr 25.11 08:05–08:35 | p95 wszystkich GET (/api/menu, /api/menu/search, /api/orders/{id}) ~0,24 s zamiast ~0,005 s (50× wolniej) | histogram_quantile(0.95, sum by (le, route) (rate(http_request_duration_seconds_bucket{namespace="demo", route=~"/api/.*"}[5m])))
śr 25.11 14:25–14:50 | znów wyciek pamięci orders-api (max w godzinie ~1,5 GB), 3 restarty każdego poda; wcześniej 12:40 pojedynczy skok do 367 MiB i 1 restart | jak wyżej (pamięć + restarty)
śr 25.11 14:30–16:00 | ~25% odpowiedzi to 5xx (route="unmatched", status 500; ~6 600 błędów); Loki: UpstreamUnavailableError "order pipeline dependency returned an unexpected response" z runtime.raise_synthetic_error (wstrzyknięty error rate) | sum(rate(http_requests_total{namespace="demo", status=~"5.."}[5m])) / sum(rate(http_requests_total{namespace="demo"}[5m]))  /  {namespace="demo", app="orders-api"} | json | level="ERROR"

## Krok 0 z podłączeniem
czas: ~2 min (szacunkowo; bez podłączenia ~15 min)  |  co asystent zrobił sam, a co wcześniej robiłem ja: sam znalazł nazwy metryk i etykiet w kodzie, wykonał zapytania przez gcx (req/s per route, 5xx z 1h) i zbudował dashboard przez API; wcześniej to ja szukałem metryk w Metrics browser i 3 razy przepisywałem zapytania między Claude a Grafaną — teraz 0 kopiowań
gdzie się pomylił: zakładał krok 15 min, a Grafana dla zakresu 4 dni zwracała punkty co 1 h (trzeba było zmienić okna na [1h] i doprecyzować krokiem 5 min); jednostka MB zamiast MiB w panelu pamięci (poprawione); parsowanie wyjścia gcx psuły doklejane podpowiedzi (przeszedł na --jq). Czas polski podany poprawnie.
