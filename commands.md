1. Create namespace for Loki
```
kubectl create ns monitoring --dry-run=client -o yaml | kubectl apply -f -
```
2. Create Ingress for Grafana, to access Grafana from internet (if we have load balancer in our cluster)
```
kubectl apply -f traefik-ingress-v2.yaml
```
3. Install Loki, Grafana and Promtail
```
helm install grafana grafana/grafana -f grafana-grafana-values.yaml --namespace monitoring
helm install loki grafana/loki -f loki-values.yaml --namespace monitoring
helm install promtail grafana/promtail -f promtail-values.yaml --namespace monitoring
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
4. Deploy todo app to see its logs
```
kubectl apply -f todo-app-deployment.yaml
```