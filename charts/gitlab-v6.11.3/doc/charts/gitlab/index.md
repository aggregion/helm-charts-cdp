---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Helm subcharts

The GitLab Helm chart is made up of multiple subcharts,
which provide the core GitLab components:

- [Gitaly](gitaly/index.md)
- [GitLab Exporter](gitlab-exporter/index.md)
- [GitLab Grafana](gitlab-grafana/index.md)
- [GitLab Pages](gitlab-pages/index.md)
- [GitLab Runner](gitlab-runner/index.md)
- [GitLab Shell](gitlab-shell/index.md)
- [GitLab agent server (KAS)](kas/index.md)
- [Mailroom](mailroom/index.md)
- [Migrations](migrations/index.md)
- [Praefect](praefect/index.md)
- [Sidekiq](sidekiq/index.md)
- [Spamcheck](spamcheck/index.md)
- [Toolbox](toolbox/index.md)
- [Webservice](webservice/index.md)

The parameters for each subchart must be under the `gitlab` key. For example,
GitLab Shell parameters would be similar to:

```yaml
gitlab:
  gitlab-shell:
    ...
```

Use these charts for optional dependencies:

- [MinIO](../minio/index.md)
- [NGINX](../nginx/index.md)
- [PostgreSQL](https://artifacthub.io/packages/helm/bitnami/postgresql)
- [Redis](https://artifacthub.io/packages/helm/bitnami/redis)
- [Registry](../registry/index.md)

Use these charts as optional additions:

- [Prometheus](https://artifacthub.io/packages/helm/prometheus-community/prometheus)
- [Grafana](https://artifacthub.io/packages/helm/grafana/grafana)
- [_Unprivileged_](https://docs.gitlab.com/runner/install/kubernetes.html#running-docker-in-docker-containers-with-gitlab-runner) [GitLab Runner](https://docs.gitlab.com/runner/) that uses the Kubernetes executor
- Automatically provisioned SSL from [Let's Encrypt](https://letsencrypt.org/), which uses [Jetstack](https://www.jetstack.io/)'s [cert-manager](https://cert-manager.io/docs/) with [certmanager-issuer](../certmanager-issuer/index.md)
