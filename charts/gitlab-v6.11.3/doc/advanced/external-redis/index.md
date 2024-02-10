---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure the GitLab chart with an external Redis

This document intends to provide documentation on how to configure this Helm chart with an external Redis service.

If you don't have Redis configured, for on-premise or deployment to VM,
consider using our [Omnibus GitLab package](external-omnibus-redis.md).

## Configure the chart

Disable the `redis` chart and the Redis service it provides, and point the other services to the external service.

You must set the following parameters:

- `redis.install`: Set to `false` to disable including the Redis chart.
- `global.redis.host`: Set to the hostname of the external Redis, can be a domain or an IP address.
- `global.redis.password.enabled`: Set to `false` if the external Redis does not require a password.
- `global.redis.password.secret`: The name of the [secret which contains the token for authentication](../../installation/secrets.md#redis-password).
- `global.redis.password.key`: The key in the secret, which contains the token content.

Items below can be further customized if you are not using the defaults:

- `global.redis.port`: The port the database is available on, defaults to `6379`.

For example, pass these values via Helm's `--set` flag while deploying:

```shell
helm install gitlab gitlab/gitlab  \
  --set redis.install=false \
  --set global.redis.host=redis.example \
  --set global.redis.password.secret=gitlab-redis \
  --set global.redis.password.key=redis-password \
```

If you are connecting to a Redis HA cluster that has Sentinel servers
running, the `global.redis.host` attribute needs to be set to the name of
the Redis instance group (such as `mymaster` or `resque`), as
specified in the `sentinel.conf`. Sentinel servers can be referenced
using the `global.redis.sentinels[0].host` and `global.redis.sentinels[0].port`
values for the `--set` flag. The index is zero based.

## Use multiple Redis instances

GitLab supports splitting several of the resource intensive
Redis operations across multiple Redis instances. This chart supports distributing
those persistence classes to other Redis instances.

More detailed information on configuring the chart for using multiple Redis
instances can be found in the [globals](../../charts/globals.md#multiple-redis-support)
documentation.

## Specify secure Redis scheme (SSL)

To connect to Redis using SSL, use the `rediss` (note the double `s`) scheme parameter:

```shell
--set global.redis.scheme=rediss
```

## `redis.yml` override

If you want to override the contents of the [`redis.yml` config file introduced in GitLab 15.8](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106854)
you can do so by defining values under
`global.redis.redisYmlOverride`. All values and sub-values under that
key will be rendered into `redis.yml` as-is.

The `global.redis.redisYmlOverride` setting is intended for use with
external Redis services. You must set `redis.install` to `false`. See
[configure Redis settings](../../charts/globals.md#configure-redis-settings)
for further details.

Example:

```yaml
redis:
  install: false
global:
  redis:
    redisYmlOverride:
      exotic_redis:
        host: redis.example.com:6379
        password: <%= File.read('/path/to/secret').strip.to_json %>
      mystery_setting:
        deeply:
          nested: value
```

Assuming `/path/to/secret` contains `THE SECRET`, his will cause the
following to be rendered in `redis.yml`:

```yaml
production:
  exotic_redis:
    host: redis.example.com:6379
    password: "THE SECRET"
  mystery_setting:
    deeply:
      nested: value
```

### Things to look out for

The flip side of the flexibility of `redisYmlOverride` is that it is less user friendly. For example:

1. To insert passwords into `redis.yml` you must write correct ERB
   `<%= File.read('/path/to/secret').strip.to_json %>` statements yourself, using
   whatever path the secret is mounted in the container at.
1. In `redisYmlOverride` you must follow the naming conventions of
   GitLab Rails. For example, the "SharedState" instance is not called
   `sharedState` but `shared_state`.
1. There is no inheritance of configuration values. For example, if
   you have three Redis instances that share a single set of Sentinels,
   you have to repeat the Sentinel configuration three times.
1. The CNG images [expect a valid `resque.yml` and `cable.yml`](https://gitlab.com/gitlab-org/build/CNG/-/blob/4d314e505edb25ccefd4297d212bfbbb5bc562f9/gitlab-rails/scripts/lib/checks/redis.rb#L54)
  so you still need to configure at least `global.redis.host` to get a
  `resque.yml` file.
