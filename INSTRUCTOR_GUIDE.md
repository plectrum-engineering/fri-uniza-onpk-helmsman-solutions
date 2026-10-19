# Operation Helmsman - instructor guide

Helm & Kustomize block for ONPK 2026. About 4 hours: lecture blocks alternate with hands-on missions.

Files:

- `helm_kustomize.pptx` - lecture (62 slides, speaker notes on the important ones)
- `helm_kustomize_challenge.pptx` - challenge deck for the students (missions, briefs, hint cards)
- `operation-helmsman-starter.zip` - for the students
- `operation-helmsman-solutions.zip` - for you (this guide is inside it)

---

## 1. Preparation (day before)

1. Run the whole pack once on the lab machines: `minikube start`, `./00-setup/check-tools.sh`.
2. Images the labs pull (pre-pull them if the Wi-Fi is weak, e.g. `minikube image pull <image>`):
   - `ghcr.io/stefanprodan/podinfo:6.14.0`, `ghcr.io/stefanprodan/podinfo:6.15.0`
   - `us-docker.pkg.dev/google-samples/containers/gke/gb-frontend:v5`
   - `us-docker.pkg.dev/google-samples/containers/gke/gb-redis-follower:v2`
   - `registry.k8s.io/redis@sha256:cb111d1bd870a6a471385a4a69ad17469d326e9dd91e0e455350cacf36e1b3ee`
   - `busybox:1.37`, `nginx:1.27`, `nginx:1.27-alpine`
3. Students need internet access to `stefanprodan.github.io` and `ghcr.io` (Mission 1). Missions 5-7 work offline: the podinfo chart is vendored.
4. Print or prepare the leaderboard (whiteboard is fine): teams x missions.
5. Optional: enable the ingress addon (`minikube addons enable ingress`) if you want to show M2.5.

### What was tested and what was not

- Tested: every chart with `helm lint` and `helm template` (Helm 4.0), every Kustomize overlay with `kustomize build` (v5.8.1), all rendered output against the Kubernetes 1.33 JSON schemas (`kubeconform -strict`), both self-check scripts (`verify.sh`, `check.sh`) against the starter and the solution.
- **Not tested on a live cluster** (no cluster was available while building the pack). Do one full dry run on minikube before class, especially `helm test` for the guestbook and the lighthouse, and M3.3 (the failing upgrade).

---

## 2. Timing

| Time | Block | Slides / folder |
|------|-------|-----------------|
| 0:00-0:35 | Lecture: why packaging, Helm fundamentals, using charts | lecture 1-20 |
| 0:35-0:55 | Mission 1 - Paint the pod | lecture 21, `01-helm-consumer` |
| 0:55-1:20 | Lecture: writing charts, release lifecycle (live demo: `helm create`, `helm template`) | lecture 22-41 |
| 1:20-2:10 | Mission 2 (35 min) + Mission 3 (15 min) | lecture 35 + 42, `02-...`, `03-...` |
| 2:10-2:20 | Break | |
| 2:20-2:50 | Lecture: Kustomize, patches, generators, Helm vs Kustomize | lecture 43-54, then 56-59 after Mission 4 if you prefer |
| 2:50-3:20 | Mission 4 - Three environments | lecture 55, `04-kustomize` |
| 3:20-3:55 | Side quests: Boss level / Escape room / Kustomize golf | lecture 60, challenge deck 11-15 |
| 3:55-4:00 | Leaderboard, takeaways | |

If you are behind: make Mission 3 a demo, and let students do only one side quest. If you are ahead: the side quests have no upper limit.

---

## 3. Missions - answers and what to watch

### Mission 1 - Paint the pod (10 pts)

Reference: `01-helm-consumer/commands.sh`.

- Learning point: `helm rollback paint 1` creates **revision 3**. History is append-only.
- `helm get values` shows only user values; `--all` shows the merged result.
- Typical problem: after the upgrade the port-forward still points to a terminated pod. Restart it.

### Mission 2 - Chart the guestbook (30 + 10 pts)

Reference chart: `02-guestbook-chart/guestbook`.

Checks:

```bash
helm lint ./guestbook
helm template gb ./guestbook | kubectl apply --dry-run=server -f -
helm install gb ./guestbook -n guestbook-dev --create-namespace
helm test gb -n guestbook-dev
```

What to watch:

- **Service names must not change** (`redis-leader`, `redis-follower`, `frontend`): the PHP app resolves them via DNS. Ask why we cannot prefix names with `.Release.Name`. Answer: the app hard-codes the hostnames, so there can be only one release per namespace. Good discussion of "chart authors vs. app authors".
- The starter fixes the overlapping selector from the original guestbook example (leader and follower both selected only `app: redis`); selectors now include `role` and `tier`.
- `toYaml .Values.x.resources | nindent 12` - the most common indentation error.
- M2.2: `digest` wins over `tag`; `required` makes an empty tag fail with a clear message.
- Bonus schema: `values.schema.json` limits `environment` to dev/staging/prod and `replicas` to 1-10.

### Mission 3 - Release day (15 pts)

Reference: `03-release-day/` (values files + `commands.sh`).

- M3.3 is the highlight. `--set frontend.image.tag=v999 --rollback-on-failure --timeout 90s` produces `ImagePullBackOff`; Helm waits, times out and rolls back. `helm history` shows a `failed` revision and a `Rollback to N` revision.
- Users barely notice: the Deployment keeps old pods until new ones are ready (rolling update with default 25% maxUnavailable). Good moment to connect to probes and rolling updates from the previous lecture.
- With Helm 3 the flag is `--atomic`.
- M3.5: Helm (the schema) rejects `replicas=0` before anything reaches Kubernetes.

### Mission 4 - Three environments (25 pts)

Reference: `04-kustomize/`.

```bash
kubectl kustomize overlays/dev       # also staging, prod
kubectl apply -k overlays/dev
kubectl -n podinfo-dev port-forward svc/dev-podinfo 9898:9898
```

- dev: green UI, chaos-monkey on -> refresh several times, you will see errors and delays.
- staging: `replicas:` and `images:` fields, **no patch**.
- prod: strategic merge patch (resources), JSON 6902 patch on `command/3` (`--level=warn`), PDB `minAvailable: 2`.
- M4.5: enabling the maintenance component changes the generated ConfigMap -> new hash -> new name -> the Deployment changes -> pods roll. That is the "why do they restart" answer.
- Common error: `labels` with `includeSelectors: true` on an already deployed overlay -> immutable selector error. Delete and re-apply, then explain.

### Quest 5 - Boss level: The franchise (30 pts) - code word `SEXTANT`

Reference: `05-boss-franchise/`.

- The only change in `base/` is `skipTests: true` in `helmCharts` (the podinfo chart ships 3 test pods with random names).
- Rendered names: Deployment and Service `storefront-podinfo`, container `podinfo`.
- Bistro Byte: `namespace`, Namespace object, `labels`, a strategic merge patch with a `target` for the two env vars.
- Rocket Rentals: same, plus `replicas` (3) and `images` (`newTag: 6.14.0`).
- Gotcha: a patch without `target` may not match, because Helm renders the objects with the namespace already set. Using `target` avoids it.
- `kubectl kustomize --enable-helm` needs `helm` on the PATH.

### Quest 6 - Escape room: The lighthouse (25 pts, -3 per hint card) - code word `ANCHOR`

Reference (fixed chart): `06-escape-room/lighthouse`. The locks appear in this order:

| Lock | Hint card | Where | Bug | Found by |
|------|-----------|-------|-----|----------|
| 1 | A | `values.yaml` | `tag:` indented with 1 space instead of 2 | `helm lint` (YAML error) |
| 2 | B | `Chart.yaml` | `apiVersion: v1` together with `type:` | `helm lint` |
| 3 | C | `templates/service.yaml` | `.Values.servce.port` typo -> nil pointer | `helm lint` / `helm template` |
| 4 | D | `templates/deployment.yaml` | `indent 12` instead of `nindent 12` for resources | `helm template --debug` |
| 5 | E | `templates/deployment.yaml` | `PODINFO_PORT` value not quoted (number) | `kubeconform -strict` or `helm install` |
| 6 | F | `templates/_helpers.tpl` | selectorLabels `lighthouse-app` vs labels `lighthouse` | `helm install` (selector does not match template labels) |
| 7 | G | `templates/service.yaml` | `targetPort: web`, the container port is named `http` | `helm test` fails, no endpoints |
| 8 | H | `templates/deployment.yaml` | `b64enc` instead of `b64dec` -> message shows `UVU1RFNFOVM=` | reading the UI |

Install: `helm install beacon ./lighthouse -n lighthouse --create-namespace`, then port-forward per NOTES and `helm test beacon -n lighthouse`.
Final UI message: **The code word is ANCHOR**.

### Quest 7 - Kustomize golf (10 pts per hole, +5 under par)

Reference answers: `07-kustomize-golf/puzzle-*/kustomization.yaml` (they define par: 8 / 37 / 42).

- Hole 1: `namespace`, `nameSuffix`, `commonAnnotations`. Can be done in 5 lines (`resources: [../base]` on one line, and Kustomize tolerates a missing `apiVersion`/`kind`).
- Hole 2: `images` with `newTag: 1.27-alpine`, `configMapGenerator` from `app.properties`, `secretGenerator` with `API_TOKEN=s3cr3t`, JSON patch adding the volume, volumeMount and `envFrom`. Hashes are deterministic, so the output matches only with identical content. A strategic merge patch is a valid shorter route.
- Hole 3: `namePrefix: golf-`, `labels` with `includeSelectors: true`, `replicas`, JSON patch removing `ports/1`, strategic merge patch adding the `log-shipper` sidecar, `replacements` copying the Service name into `BACKEND_HOST`.
- `check.sh` uses the standalone `kustomize` if present, otherwise `kubectl kustomize`. Very old kubectl versions may order fields differently; if a student is sure the answer is right, compare with the reference.

---

## 4. Scoring sheet

| Mission | Points |
|---------|--------|
| 1 Paint the pod | 10 |
| 2 Chart the guestbook | 30 (+10 schema bonus) |
| 3 Release day | 15 |
| 4 Three environments | 25 |
| 5 Boss level (`SEXTANT`) | 30 |
| 6 Escape room (`ANCHOR`) | 25, minus 3 per hint card |
| 7 Golf | 10 per hole, +5 under par |
| First team to demo a mission | +5 |

---

## 5. Discussion questions for the wrap-up

1. Your company runs 40 microservices. Helm chart per service, one shared chart, or Kustomize? Why?
2. Where would you keep the `values-prod.yaml` - with the chart or in a separate GitOps repo?
3. What is the risk of `helm upgrade --reuse-values` after a chart upgrade?
4. Why does a Kustomize ConfigMap change restart pods, and how do you get the same with Helm? (`checksum/config` annotation with `sha256sum`)
5. Which of the 8 lighthouse bugs would a CI pipeline catch, and with which tool?

## 6. Versions used

Helm 4 (current line 4.3; Helm 3 gets security fixes until 11 Nov 2026), Kustomize 5.8, podinfo chart/app 6.15.0, Kubernetes schemas 1.33.
Helm 4 renamed flags: `--atomic` -> `--rollback-on-failure`, `--force` -> `--force-replace`. Students on Helm 3 can do every mission with the old flag names.
