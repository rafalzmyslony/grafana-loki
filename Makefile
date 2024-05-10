helm_create_all:
	kubectl create ns monitoring --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f traefik-ingress-v2.yaml
	helm install grafana grafana/grafana -f grafana-grafana-values.yaml --namespace monitoring
	helm install loki grafana/loki -f loki-values.yaml --namespace monitoring
	helm install promtail grafana/promtail -f promtail-values.yaml --namespace monitoring
	kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
	
delete_all_pvc:
	./remove-existing-pvc.sh

helm_delete_all:
	helm uninstall --namespace monitoring grafana loki promtail
	make delete_all_pvc
	
civo_create_cluster:
	civo kubernetes create civo-cluster -n 1 -s g4s.kube.large --create-firewall --firewall-rules "all" --region FRA1 --wait --save --merge --switch
civo_delete_cluster:
	civo kubernetes remove civo-cluster --yes

civo_delete_all_volumes:
	./remove-existing-civo-volumes.sh
