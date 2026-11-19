#!/usr/bin/env bash
set -euo pipefail
L=app.kubernetes.io/part-of=k8s-ingress-assignment
kubectl delete ingress,service,deployment,pvc,pv -l "$L" --ignore-not-found
kubectl delete configmap student-info app-about-code app-about-photo app-research-code app-research-seed app-api-code --ignore-not-found
