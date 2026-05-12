# onai-helm-charts

Helm charts for the ONAI multi-node stack.

| Chart | Path | Description |
|---|---|---|
| `onai-three-node` | [`./onai-three-node`](./onai-three-node) | Four-pod architecture (M1/M2/M3/M4) — web frontend, vLLM GPU inference, gateway/storage, vLLM gateway. |

> Directory named `three-node` for historical reasons. Currently ships **four** components (M1–M4). Each `mN` block in `values.yaml` independently toggleable via `mN.enabled`.

---

## `onai-three-node`

- **Chart version:** `0.1.0`
- **App version:** `1.0.0`
- **Release name:** `spider`
- **Target namespace:** `spider`

### Components

| Pod | Role | Default image | Default tag |
|---|---|---|---|
| **M1** | Web frontend (Debian) — HTTP `80`/`443` ingress via Gateway API | `us-west4-docker.pkg.dev/aardant-489720/aardant-repo/okn.us-website` | `0.0.11` |
| **M2** | vLLM GPU inference (default model: `Qwen/Qwen3-14B-AWQ`) | `vllm/vllm-openai` | `latest-cu129` |
| **M3** | Gateway / storage relay (fast SSD, externally exposed TCP) | `us-west4-docker.pkg.dev/aardant-489720/aardant-repo/aardant-unc-relay` | `0.77.1` |
| **M4** | vLLM gateway — sits between M2 and outside world | `us-west4-docker.pkg.dev/aardant-489720/aardant-repo/aardant-vllm-gateway` | `0.0.1` |

### What gets deployed (per pod)

For each `mN` (where `mN.enabled: true`):

- `Deployment` (`templates/mN-deployment.yaml`)
- `Service` (`templates/mN-service.yaml`)
- `PersistentVolumeClaim` (`templates/mN-pvc.yaml`)

Plus cluster-wide:

- `ServiceAccount` (`templates/serviceaccount.yaml`)
- GKE Gateway `HTTPRoute` + `GCPBackendPolicy` + `HealthCheckPolicy` for M1 (`templates/gateway.yaml`)
- Optional `NetworkPolicy` (`templates/networkpolicy.yaml`, gated by `networkPolicy.enabled`)

### Install / upgrade

```bash
helm upgrade --install spider ./charts/onai-helm-charts/onai-three-node \
  --namespace spider --create-namespace \
  -f my-values.yaml
```

Render-only (preview manifests):

```bash
helm template spider ./charts/onai-helm-charts/onai-three-node -f my-values.yaml
```

### Key values

| Key | Default | Notes |
|---|---|---|
| `m1.enabled` / `m2.enabled` / `m3.enabled` / `m4.enabled` | `true` | Toggle individual pods |
| `m1.image.{repository,tag}` | see table above | Web frontend image |
| `m2.image.{repository,tag}` | `vllm/vllm-openai:latest-cu129` | vLLM image |
| `m2.gpu.enabled` | `true` | Requests `nvidia.com/gpu` |
| `m2.gpu.accelerator` | `nvidia-l4` | GKE GPU node-pool selector |
| `m2.env.VLLM_MODEL` | `Qwen/Qwen3-14B-AWQ` | Model served by vLLM |
| `m3.ssd.size` | `250Gi` | Fast SSD PVC for M3 |
| `m3.service.externalEnabled` | `true` | Expose M3 external TCP port |
| `m4.service.externalEnabled` | `true` | Expose M4 external TCP port |
| `gateway.enabled` | `true` | GKE Gateway HTTPRoute for M1 |
| `gateway.host` | `okn.us` | Hostname routed to M1 |
| `gateway.parentRefs` | `ingress-gateway/ingress` | Existing parent Gateway |
| `tcpRoute.enabled` | `false` | Optional TCPRoute for M3 |
| `networkPolicy.enabled` | `false` | Lock down inter-pod traffic |

Full schema in [`onai-three-node/values.yaml`](./onai-three-node/values.yaml).

---

## Bumping images

Each pod has its own `image.repository` / `image.tag` block under `m1`, `m2`, `m3`, `m4`. Bump only the one you need. Both paths below go through Helm so release history stays intact for rollback.

### Option A — edit `values.yaml` then upgrade

```yaml
# onai-three-node/values.yaml
m2:
  image:
    repository: vllm/vllm-openai
    tag: "v0.7.3"   # was latest-cu129

m4:
  image:
    repository: us-west4-docker.pkg.dev/aardant-489720/aardant-repo/aardant-vllm-gateway
    tag: "0.0.2"    # was 0.0.1
```

Apply:

```bash
helm upgrade spider ./charts/onai-helm-charts/onai-three-node --namespace spider
```

> Avoid floating tags like `latest-cu129` in production — pin digest or semver tag so rollouts reproducible. See [Kubernetes image policy](https://kubernetes.io/docs/concepts/containers/images/#image-names).

### Option B — one-off `--set` override

Bump one or more pod tags without editing values:

```bash
helm upgrade spider ./charts/onai-helm-charts/onai-three-node \
  --namespace spider --reuse-values \
  --set m2.image.tag=v0.7.3 \
  --set m4.image.tag=0.0.2
```

`--reuse-values` keeps prior overrides. Docs: https://helm.sh/docs/helm/helm_upgrade/

> Always go through Helm so revisions track in release history. Out-of-band edits (`kubectl edit`, `kubectl set image`) bypass release history and break `helm rollback` — avoid them.

### Verify

```bash
helm -n spider get values spider
helm -n spider status spider
helm -n spider history spider
```

Docs: https://helm.sh/docs/helm/helm_history/

### Rollback

List revisions, roll back to prior good one:

```bash
helm -n spider history spider
helm -n spider rollback spider <REVISION>
```

Docs: https://helm.sh/docs/helm/helm_rollback/

---

## GPU notes (M2)

- Requires GKE node pool with NVIDIA GPUs and NVIDIA device plugin installed: https://cloud.google.com/kubernetes-engine/docs/how-to/gpus
- Adjust `m2.gpu.accelerator` to match node pool label (`nvidia-l4`, `nvidia-tesla-t4`, `nvidia-a100-80gb`, ...).
- HuggingFace cache PVC (`m2.modelCache`) separate from code PVC so model downloads survive pod restarts.

## References

- Helm install: https://helm.sh/docs/helm/helm_install/
- Helm upgrade: https://helm.sh/docs/helm/helm_upgrade/
- Helm rollback: https://helm.sh/docs/helm/helm_rollback/
- Helm values files: https://helm.sh/docs/chart_template_guide/values_files/
- Kubernetes Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- GKE Gateway API: https://cloud.google.com/kubernetes-engine/docs/concepts/gateway-api
- vLLM server args: https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html
