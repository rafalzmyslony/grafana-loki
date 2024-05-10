#!/bin/bash
kubectl get pvc -o json | jq .items.[].metadata.name;
for i in $(kubectl get pvc -o json | jq .items.[].metadata.name);   do     kubectl delete pvc $(echo $i | sed 's/"//g'); done;
