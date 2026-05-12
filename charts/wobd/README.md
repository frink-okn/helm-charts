# wobd

Helm chart for the `wobd-ui` frontend.

- **Chart version:** `0.1.0`
- **App version:** `1.16.0`
- **Default image:** `containers.renci.org/frink/wobd-ui:v0.0.1`

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

## Install / upgrade (Helm users)

```bash
# from repo root
helm upgrade --install wobd ./charts/wobd \
  --namespace wobd --create-namespace \
  -f my-values.yaml
```

To pin an image tag without editing `values.yaml`:

```bash
helm upgrade --install wobd ./charts/wobd \
  --set image.tag=v0.0.2
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

## Bumping the image (non-Helm users)

If your team does **not** run `helm upgrade` directly (e.g. GitOps via Argo CD / Flux, or hand-edited manifests), you still bump the image the same way — change the tag and let your pipeline reconcile.

### Option A — edit `values.yaml`, let GitOps reconcile

1. Open `charts/wobd/values.yaml`.
2. Change `image.tag`:
   ```yaml
   image:
     repository: containers.renci.org/frink/wobd-ui
     tag: "v0.0.2"   # was v0.0.1
   ```
3. Commit + push. Argo CD / Flux re-render the chart and apply the new Deployment.

### Option B — override in environment values file

Keep `values.yaml` as defaults, override per environment:

```yaml
# values/prod.yaml
image:
  tag: "v0.0.2"
```

Then in your Argo CD `Application` / Flux `HelmRelease`, point `valueFiles` at `values/prod.yaml`.

- Argo CD `Application` spec: https://argo-cd.readthedocs.io/en/stable/user-guide/helm/
- Flux `HelmRelease`: https://fluxcd.io/flux/components/helm/helmreleases/

### Option C — one-off `helm upgrade --set`

No values file edit. Pins tag via release args:

```bash
helm upgrade wobd ./charts/wobd \
  --namespace wobd --reuse-values \
  --set image.tag=v0.0.2
```

`--reuse-values` keeps prior overrides. Docs: https://helm.sh/docs/helm/helm_upgrade/

> Always go through Helm so revisions track in release history — needed for `helm rollback`.

### Verify the new image is running

```bash
helm -n wobd get values wobd
helm -n wobd status wobd
helm -n wobd history wobd
```

Docs: https://helm.sh/docs/helm/helm_history/

### Rollback

List revisions, roll back to prior:

```bash
helm -n wobd history wobd
helm -n wobd rollback wobd <REVISION>
```

Docs: https://helm.sh/docs/helm/helm_rollback/

Rollback only works for changes applied via Helm. Out-of-band edits (e.g. `kubectl edit`, `kubectl set image`) bypass release history and break rollback — avoid them.

## References

- Helm install: https://helm.sh/docs/helm/helm_install/
- Helm values overrides: https://helm.sh/docs/chart_template_guide/values_files/
- Helm upgrade: https://helm.sh/docs/helm/helm_upgrade/
- Helm rollback: https://helm.sh/docs/helm/helm_rollback/
- Kubernetes Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- GKE Gateway API: https://cloud.google.com/kubernetes-engine/docs/concepts/gateway-api
