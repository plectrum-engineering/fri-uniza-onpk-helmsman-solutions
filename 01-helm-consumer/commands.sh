#!/usr/bin/env bash
# Mission 1 - reference solution (run step by step, not as a script)
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update
helm search repo podinfo --versions | head -5
helm show values podinfo/podinfo | less              # find ui.message / ui.color / replicaCount

# 1.1 install with a values file
helm install paint podinfo/podinfo -n mission1 --create-namespace -f my-values.yaml
kubectl -n mission1 port-forward svc/paint-podinfo 9898:9898   # open http://localhost:9898

# 1.2 upgrade with --set (values file + override)
helm upgrade paint podinfo/podinfo -n mission1 -f my-values.yaml --set ui.color="#ff6f00" --set replicaCount=3

# 1.3 inspect
helm list -n mission1
helm history paint -n mission1
helm get values paint -n mission1            # only YOUR overrides
helm get values paint -n mission1 --all      # everything
helm get manifest paint -n mission1 | grep -A3 PODINFO_UI

# 1.4 roll back to revision 1 (note: rollback creates a NEW revision 3)
helm rollback paint 1 -n mission1
helm history paint -n mission1

# 1.5 same chart, second release, OCI registry
helm install paint2 oci://ghcr.io/stefanprodan/charts/podinfo -n mission1 --set ui.message="I came from OCI"

# cleanup
helm uninstall paint paint2 -n mission1
