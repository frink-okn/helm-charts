# wobd

Helm chart for the `wobd-ui` frontend.

- **Chart version:** `0.1.0`
- **App version:** `1.16.0`
- **Default image:** `containers.renci.org/frink/wobd-ui:v0.0.1`
- **Target namespace:** `frink`

## What this chart deploys

| Resource | Template |
|---|---|
| Deployment (`wobd-ui` container) | `templates/deployment.yaml` |
| Service (ClusterIP, port `3000`) | `templates/service.yaml` |
| ServiceAccount | `templates/serviceaccount.yaml` |
| GKE Gateway `HTTPRoute` + `GCPBackendPolicy` | `templates/gateway.yaml` |
| Optional `Ingress` | `templates/ingress.yaml` |
| Optional `HorizontalPodAutoscaler` | `templates/hpa.yaml` |
| Optional `PodDisruptionBudget` | `templates/pdb.yaml` |

Ingress mode (`ingress.enabled`) and Gateway-API mode (`gateway.enabled`) are independent — pick whichever your cluster supports. Defaults: gateway on, ingress off.

## Install / upgrade

```bash
# from repo root
helm upgrade --install wobd ./charts/wobd \
  --namespace frink --create-namespace \
  -f my-values.yaml
```

Render manifests without applying:

```bash
helm template wobd ./charts/wobd -f my-values.yaml > rendered.yaml
```

## Key values

| Key | Default | Notes |
|---|---|---|
| `replicaCount` | `1` | Pod replicas |
| `image.repository` | `containers.renci.org/frink/wobd-ui` | |
| `image.tag` | `v0.0.1` | **Bump to release new app version** |
| `image.pullPolicy` | `Always` | |
| `service.port` | `3000` | Container/service port |
| `probes.path` | `/wobd/` | Liveness/readiness path |
| `gateway.enabled` | `true` | Use GKE Gateway API |
| `gateway.host` | `apps.okn.us` | Hostname matched by `HTTPRoute` |
| `gateway.path` | `/wobd` | Path prefix |
| `gateway.parentRefs` | `ingress-gateway/ingress` | Existing parent Gateway |
| `ingress.enabled` | `false` | Classic Ingress instead of Gateway |
| `resources.limits` | `1 CPU / 2Gi` | |
| `autoscaling.enabled` | `false` | HPA toggle |
| `pdb.enabled` | `false` | PodDisruptionBudget toggle |

See `values.yaml` for full schema.

---

## Bumping the image

Two paths, both via Helm so release history stays intact for rollback.

### Option A — edit `values.yaml` then upgrade

1. Open `charts/wobd/values.yaml`.
2. Change `image.tag`:
   ```yaml
   image:
     repository: containers.renci.org/frink/wobd-ui
     tag: "v0.0.2"   # was v0.0.1
   ```
3. Apply:
   ```bash
   helm upgrade wobd ./charts/wobd --namespace frink
   ```

### Option B — one-off `--set` override

No values file edit. Pin tag via release args:

```bash
helm upgrade wobd ./charts/wobd \
  --namespace frink --reuse-values \
  --set image.tag=v0.0.2
```

`--reuse-values` keeps prior overrides. Docs: https://helm.sh/docs/helm/helm_upgrade/

> Always go through Helm so revisions track in release history. Out-of-band edits (`kubectl edit`, `kubectl set image`) bypass release history and break `helm rollback` — avoid them.

### Verify

```bash
helm -n frink get values wobd
helm -n frink status wobd
helm -n frink history wobd
```

Docs: https://helm.sh/docs/helm/helm_history/

### Rollback

List revisions, roll back to prior:

```bash
helm -n frink history wobd
helm -n frink rollback wobd <REVISION>
```

Docs: https://helm.sh/docs/helm/helm_rollback/

## References

- Helm install: https://helm.sh/docs/helm/helm_install/
- Helm upgrade: https://helm.sh/docs/helm/helm_upgrade/
- Helm rollback: https://helm.sh/docs/helm/helm_rollback/
- Helm values files: https://helm.sh/docs/chart_template_guide/values_files/
- Kubernetes Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- GKE Gateway API: https://cloud.google.com/kubernetes-engine/docs/concepts/gateway-api
