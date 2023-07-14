---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab components sub-charts

Use the following list to learn more about the available GitLab component
service sub-charts:

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
