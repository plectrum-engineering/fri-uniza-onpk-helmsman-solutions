#!/usr/bin/env bash
# Mission 3 - Release day (reference solution; run from 03-release-day/, chart in ../02-guestbook-chart/guestbook)
CHART=../02-guestbook-chart/guestbook

# 3.1 two environments from one chart
helm install gb $CHART -n guestbook-dev  --create-namespace -f values-dev.yaml
helm install gb $CHART -n guestbook-prod --create-namespace -f values-prod.yaml
helm list -A
helm test gb -n guestbook-dev

# 3.2 dry run + diff of rendered output before an upgrade
helm template gb $CHART -f values-prod.yaml --set frontend.replicas=5 > /tmp/next.yaml
helm get manifest gb -n guestbook-prod > /tmp/current.yaml
diff /tmp/current.yaml /tmp/next.yaml

# 3.3 the bad release: an image tag that does not exist
helm upgrade gb $CHART -n guestbook-prod -f values-prod.yaml \
  --set frontend.image.tag=v999 --rollback-on-failure --timeout 90s
#   -> ImagePullBackOff, wait times out, Helm rolls back automatically
helm history gb -n guestbook-prod     # see the "failed" + "rollback" revisions
kubectl -n guestbook-prod get pods    # most old pods kept serving (rolling update never finished)

# 3.4 package & install from the archive
helm package $CHART                   # -> guestbook-0.1.0.tgz
helm upgrade gb guestbook-0.1.0.tgz -n guestbook-dev -f values-dev.yaml

# 3.5 schema saves the day
helm upgrade gb $CHART -n guestbook-dev --set frontend.replicas=0   # rejected by values.schema.json

# cleanup
helm uninstall gb -n guestbook-dev; helm uninstall gb -n guestbook-prod
