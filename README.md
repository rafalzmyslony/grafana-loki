## Intro
Install Install Loki + Grafana + Promtail from Helm Charts. Loki uses local filesystem as logs storage instead of persistent Object Storage.

## Install Loki + Grafana + Promtail
Look at Makefile. There is a lot of command
```
kubectl create ns monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f traefik-ingress-v2.yaml
helm install grafana grafana/grafana -f grafana-grafana-values.yaml --namespace monitoring
helm install loki grafana/loki -f loki-values.yaml --namespace monitoring
helm install promtail grafana/promtail -f promtail-values.yaml --namespace monitoring
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

## Loki - general tips
- use `grafana/loki` chart, rest like `grafana/loki-simple-scalable` is depracated
- we install separately Grafana, Promtail, Loki, and even Grafana-agent
- Grafana needs a persistent storage to keep all dashboards etc.
- Loki needs a object storage, because it keeps logs compresed in form of chunks.
  But it is possible to use ephimeral storage - local storage - to store all collected logs
- Promtail has to have in config `/etc/promtail/promtail.yaml` has url to the client which is `Loki`
  e.g. `http://loki-sc-gateway.monitoring-dev.svc.cluster.local/loki/api/v1/push`
- In grafana Helm chart we can specifiy datasource, to automatically connect to our loki gateway (one of microservices included in Loki)
  in `datasources` section in values.yaml
- Grafana must connect to Loki application http-metrics:3100 `http://loki-sc.monitoring-dev.svc.cluster.local:3100`
  not to `Gateway` as promtail (Port 80), which is btw. Nginx
- In loki values.yaml I use `SingleBinary<->SimpleScalable` instead of SimpleScalable, because it throws errors.
So we need also set 1 instead of 0 of singleBinary replicas -> `singleBinary.replicas: 1` 
We must use `useTestSchema: true`. Default is false
Default values.yaml specify using S3 Object storage, so in order to use local storage we need also change, so in `loki.storage`
- If single binary and replicas 1, then we can only use one node of k8s cluster
- If Loki container not working - remove pvc claimed to this pod, and remove loki server pod, and StatefulSet (which Loki is) will create pod again. This is fault of slow Civo CSI provider `kubectl -n monitoring get statefulsets.apps ` 
```
    bucketNames:
      chunks: chunks
      ruler: ruler
      admin: admin
    type: local # 
```
Rest of settings like S3 must be null
And also use `auth_enabled: false` to not provide login and password when connecting Loki data source in Grafana

Fetch logs from todo-app
Deploy to-do app from private repo.
```
kubectl create secret docker-registry gitlab-repo-v2 --docker-server=https://registry.gitlab.com --docker-username=xxxxxxxxxxx --docker-password=xxxxxxxxxxxxx -n new-ns --dry-run=client -o yaml | kubectl apply -f -
```
```
kubectl apply -f todo-app-deployment.yaml
```
## Notes

#### Traefik - to access svc grafana
e.g.
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: yourapp-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: www.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: jab-graf-grafana
            port:
              number: 80

```

curl --header 'Host: www.example.com'  367a2d7d-32e4-43d4-ad9c-82eb6dd59aeb.k8s.civo.com
<a href="/login">Found</a>.

#### or remove Host, so you don't have to use header `Host: www.example.com`
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: yourapp-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: jab-graf-grafana
            port:
              number: 80
```

#### Sidecar to troubleshoot dns, whethen dns name is correct
kubectl run -it --rm --restart=Never --image=busybox dns-test -- nslookup loki:


## Challanges:
####
#### Loki
- log rotation, a lot of logs, how to keep them? - find out!
#### Promtail:  
- another agents like Grafana Agent - find out!
## Troubleshooting tips:
0. Remember remove all `pvc` and `pv` when I work on the same k8s cluster
1.  
use custom values.yaml
https://github.com/grafana/loki/issues/12610

2.  Anti-Affinity Rules

Sometimes pods in logs contains:
```
 Events:                                                                                                                                                     │
│   Type     Reason            Age                   From               Message                                                                               │
│   ----     ------            ----                  ----               -------                                                                               │
│   Warning  FailedScheduling  20m (x50 over 4h26m)  default-scheduler  0/1 nodes are available: 1 node(s) didn't match pod anti-affinity rules. preemption:  │
│ 0/1 nodes are available: 1 No preemption victims found for incoming pod..       
```
Because

The error messages you're seeing in the Kubernetes logs for Loki indicate issues with scheduling the Loki pod due to pod anti-affinity rules. Let's break down the error and provide solutions.

Understanding the Error
FailedScheduling: This error means the Kubernetes scheduler is unable to find a suitable node to place the Loki pod based on the current scheduling constraints.
Pod Anti-Affinity Rules: Pod anti-affinity rules prevent certain pods from being co-located on the same node under specified conditions. If you have anti-affinity rules set for Loki, it means Loki is configured not to share a node with certain other pods.
No Preemption Victims Found for Incoming Pod: This part of the error indicates that there are no lower-priority pods that can be evicted (preempted) to make space for the Loki pod.


1. Review Anti-Affinity Rules
Check the anti-affinity settings in your Loki deployment. Here’s an example of how pod anti-affinity might be configured:

yaml
Copy code
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: "app"
          operator: In
          values:
          - "loki"
      topologyKey: "kubernetes.io/hostname"
Adjust the Rules: If the rules are too strict, consider modifying them. For instance, you might change requiredDuringSchedulingIgnoredDuringExecution to preferredDuringSchedulingIgnoredDuringExecution, which makes the rules advisory rather than mandatory.
2. Scale Your Cluster
If you’re running a single-node cluster or all your nodes are fully utilized:

Add More Nodes: Increase the number of nodes in your cluster (if possible).
Reschedule Existing Pods: You might reschedule or temporarily reduce the number of replicas for other less critical services.

3. Pvc throws errors 

Delete thic pvc, and loki-read pod should create it again.



# values.yaml

  grafana:
    additionalDataSources:
     - name: Loki
       access: proxy
       editable: false
       orgId: 1
       type: loki
       url: http://loki-gateway.<NAMESPACE>.svc.cluster.local
       version: 1

https://stackoverflow.com/questions/75605510/grafana-loki-data-source-receiving-400-unauthorized-error

I got the same promblem, then i check grafana log

kubectl logs -n grafana-loki-dev loki-grafana-66dcf659b4-8qk22 grafana -f
it shows

enter image description here

You can specify the orgid by adding an HTTP Header 'X-Scope-OrgID' in the Data Source configuration on the Grafana panel. Here, you can set the value of the Header to the orgid you want. This way, when Grafana proxies access to Loki's API, it will have the correct Header and thus successfully authenticate and obtain access.


https://github.com/grafana/loki/issues/2938



