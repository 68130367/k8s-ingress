#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

die() { echo "ERROR: $*" >&2; exit 1; }
get() { grep -E "^$1=" config.env | head -1 | cut -d= -f2-; }

ID_SUFFIX="$(get ID_SUFFIX)"
[[ "$ID_SUFFIX" =~ ^[0-9]{3}$ ]] || die "config.env: ID_SUFFIX ต้องเป็นตัวเลข 3 หลัก (ตอนนี้: '$ID_SUFFIX')"
DOMAIN="id-${ID_SUFFIX}.com"
render_ingress() { sed "s/__DOMAIN__/${DOMAIN}/g" manifests/40-ingress.yaml.tpl; }

if [[ "${1:-}" == "--render" ]]; then render_ingress; exit 0; fi

command -v kubectl >/dev/null || die "ไม่พบ kubectl"
kubectl cluster-info >/dev/null 2>&1 || die "kubectl ต่อ cluster ไม่ได้ (ตรวจ kubectl config current-context)"
echo "==> context: $(kubectl config current-context)   domain: ${DOMAIN}"

if ! kubectl get ingressclass nginx >/dev/null 2>&1; then
  die "ยังไม่มี IngressClass 'nginx' -> ติดตั้ง ingress-nginx ก่อน (ดู README ข้อ 1)"
fi

PHOTO=""
for ext in jpg jpeg png webp; do
  [[ -f "app-about/photo.${ext}" ]] && { PHOTO="app-about/photo.${ext}"; break; }
done
[[ -n "$PHOTO" ]] || die "ไม่พบ app-about/photo.*"
PHOTO_KEY="photo.${PHOTO##*.}"

cm() { kubectl create configmap "$@" --dry-run=client -o yaml | kubectl apply -f - ; }
echo "==> ConfigMaps"
cm student-info      --from-env-file=config.env
cm app-about-code    --from-file=app.py=app-about/app.py
cm app-about-photo   --from-file="${PHOTO_KEY}=${PHOTO}"
cm app-research-code --from-file=app.py=app-research/app.py
cm app-research-seed --from-file=research.seed.md=app-research/research.seed.md
cm app-api-code      --from-file=app.py=app-api/app.py

echo "==> Storage"
DEFAULT_SC="$(kubectl get storageclass -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name}{end}' 2>/dev/null || true)"
if [[ -z "$DEFAULT_SC" ]]; then
  echo "ไม่มี default StorageClass -> สร้าง hostPath PV"
  kubectl apply -f manifests/storage-hostpath.yaml
else
  echo "ใช้ default StorageClass: ${DEFAULT_SC}"
fi

echo "==> Apps + Services"
kubectl apply -f manifests/10-app-about.yaml -f manifests/20-app-research.yaml -f manifests/30-app-api.yaml

echo "==> Ingress (${DOMAIN})"
render_ingress | kubectl apply -f -

if [[ "${1:-}" == "--restart" ]]; then
  kubectl rollout restart deployment/app-about deployment/app-research deployment/app-api
fi

echo "==> รอ pod พร้อม"
for d in app-about app-research app-api; do kubectl rollout status "deployment/$d" --timeout=180s; done

cat <<EOF

เสร็จแล้ว. ขั้นต่อไป:
  1) หา IP ของ ingress controller แล้วเพิ่มใน /etc/hosts:
       <INGRESS_IP>  www.${DOMAIN} admin.${DOMAIN}
     (minikube: \`minikube ip\`; kubeadm/VM: IP ของ node หรือ LoadBalancer ตาม lab)
  2) ตรวจสอบ:  INGRESS_IP=<ip> INGRESS_PORT=<port> ./tests/check.sh
EOF
