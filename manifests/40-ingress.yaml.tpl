---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-www
  labels:
    app.kubernetes.io/part-of: k8s-ingress-assignment
spec:
  ingressClassName: nginx
  rules:
    - host: www.__DOMAIN__
      http:
        paths:
          - path: /about
            pathType: Prefix
            backend:
              service:
                name: app-about
                port:
                  number: 80
          - path: /research
            pathType: Prefix
            backend:
              service:
                name: app-research
                port:
                  number: 80
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: app-api
                port:
                  number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-admin
  labels:
    app.kubernetes.io/part-of: k8s-ingress-assignment
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /edit
spec:
  ingressClassName: nginx
  rules:
    - host: admin.__DOMAIN__
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-research
                port:
                  number: 80
