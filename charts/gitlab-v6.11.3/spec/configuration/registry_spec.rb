require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'registry configuration' do
  let(:default_values) do
    HelmTemplate.defaults
  end

  context 'When customer provides additional labels' do
    let(:values) do
      YAML.safe_load(%(
        global:
          common:
            labels:
              global: global
              foo: global
          pod:
            labels:
              global_pod: true
          service:
            labels:
              global_service: true
        registry:
          common:
            labels:
              global: registry
              registry: registry
          networkpolicy:
            enabled: true
          podLabels:
            pod: true
            global: pod
          serviceAccount:
            create: true
            enabled: true
          serviceLabels:
            service: true
            global: service
      )).deep_merge(default_values)
    end

    it 'Populates the additional labels in the expected manner' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      expect(t.dig('ConfigMap/test-registry', 'metadata', 'labels')).to include('global' => 'registry')
      expect(t.dig('Deployment/test-registry', 'metadata', 'labels')).to include('foo' => 'global')
      expect(t.dig('Deployment/test-registry', 'metadata', 'labels')).to include('global' => 'registry')
      expect(t.dig('Deployment/test-registry', 'metadata', 'labels')).not_to include('global' => 'pod')
      expect(t.dig('Deployment/test-registry', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('Deployment/test-registry', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
      expect(t.dig('Deployment/test-registry', 'spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
      expect(t.dig('Deployment/test-registry', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
      expect(t.dig('HorizontalPodAutoscaler/test-registry', 'metadata', 'labels')).to include('global' => 'registry')
      expect(t.dig('Ingress/test-registry', 'metadata', 'labels')).to include('global' => 'registry')
      expect(t.dig('NetworkPolicy/test-registry-v1', 'metadata', 'labels')).to include('global' => 'registry')
      expect(t.dig('PodDisruptionBudget/test-registry-v1', 'metadata', 'labels')).to include('global' => 'registry')
      expect(t.dig('Service/test-registry', 'metadata', 'labels')).to include('global' => 'service')
      expect(t.dig('Service/test-registry', 'metadata', 'labels')).to include('global_service' => 'true')
      expect(t.dig('Service/test-registry', 'metadata', 'labels')).to include('service' => 'true')
      expect(t.dig('Service/test-registry', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('ServiceAccount/test-registry', 'metadata', 'labels')).to include('global' => 'registry')
    end
  end

  describe 'service TLS is configured' do
    let(:tls_values) do
      YAML.safe_load(%(
        global:
          hosts:
            registry:
              protocol: https
        registry:
          tls:
            enabled: true
      )).deep_merge(default_values)
    end

    context 'when enabled without configuration' do
      it 'renders default configuration, volume content, ingress annotations, port definitions' do
        t = HelmTemplate.new(tls_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        expect(t.dig('ConfigMap/test-registry', 'data', 'config.yml')).to include(
          <<~TLS_CONFIG
          http:
            addr: :5000
            # `host` is not configurable
            # `prefix` is not configurable
            tls:
              certificate: /etc/docker/registry/tls/tls.crt
              key: /etc/docker/registry/tls/tls.key
              minimumTLS: "tls1.2"
          TLS_CONFIG
        )

        tls_crt = t.find_projected_secret_key('Deployment/test-registry', 'registry-secrets', 'test-registry-tls', 'tls.crt')
        expect(tls_crt).not_to be_empty

        ingress_annotations = t.annotations('Ingress/test-registry')
        expect(ingress_annotations).to include(YAML.safe_load(%(
          nginx.ingress.kubernetes.io/backend-protocol: https
          nginx.ingress.kubernetes.io/proxy-ssl-verify: "on"
          nginx.ingress.kubernetes.io/proxy-ssl-name: test-registry.default.svc
        )))

        service_ports = t.dig('Service/test-registry', 'spec', 'ports')
        expect(service_ports[0]['targetPort']).to eq('https')

        container_ports = t.find_container('Deployment/test-registry', 'registry')['ports']
        expect(container_ports).to include({ 'containerPort' => 5000, 'name' => 'https' })
      end
    end

    context 'when provided internal TLS configuration' do
      let(:values) do
        YAML.safe_load(%(
          registry:
            tls:
              secretName: internal-hosts-tls
        )).deep_merge(tls_values)
      end

      it 'renders deployment as expected' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        expect(t.find_projected_secret('Deployment/test-registry', 'registry-secrets', 'internal-hosts-tls')).to be true
      end
    end

    context 'when provided global TLS configuration' do
      let(:values) do
        YAML.safe_load(%(
          global:
            registry:
              tls:
                secretName: global-tls
        )).deep_merge(tls_values)
      end

      it 'renders deployment with global TLS configuration' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        expect(t.find_projected_secret('Deployment/test-registry', 'registry-secrets', 'global-tls')).to be true
      end
    end

    context 'when provided global and internal TLS configuration' do
      let(:values) do
        YAML.safe_load(%(
          global:
            registry:
              tls:
                secretName: global-tls
          registry:
            tls:
              secretName: internal-hosts-tls
        )).deep_merge(tls_values)
      end

      it 'renders deployment with internal TLS configuration' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        expect(t.find_projected_secret('Deployment/test-registry', 'registry-secrets', 'internal-hosts-tls')).to be true
      end
    end

    context 'when provided extended TLS configuration' do
      let(:values) do
        YAML.safe_load(%(
          global:
            host:
              registry:
                protocol: https
          registry:
            tls:
              secretName: registry-service-tls
              clientCAs: [one, two, three]
              minimumTLS: "tls1.3"
              caSecretName: service-tls-ca
        )).deep_merge(tls_values)
      end

      it 'renders configuration, ingress as expected' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        expect(t.dig('ConfigMap/test-registry', 'data', 'config.yml')).to include(
          <<~TLS_CONFIG
          http:
            addr: :5000
            # `host` is not configurable
            # `prefix` is not configurable
            tls:
              certificate: /etc/docker/registry/tls/tls.crt
              key: /etc/docker/registry/tls/tls.key
              clientCAs:
                - one
                - two
                - three
              minimumTLS: "tls1.3"
          TLS_CONFIG
        )

        ingress_annotations = t.annotations('Ingress/test-registry')
        expect(ingress_annotations).to include(
          'nginx.ingress.kubernetes.io/proxy-ssl-secret' => 'default/service-tls-ca'
        )
      end
    end
  end

  describe 'templates/configmap.yaml' do
    describe 'redis cache config' do
      context 'when cache is enabled using global settings' do
        let(:values) do
          YAML.safe_load(%(
            global:
              redis:
                host: global.redis.example.com
                port: 16379
            registry:
              database:
                enabled: true
              redis:
                cache:
                  enabled: true
          )).deep_merge(default_values)
        end

        it 'populates the redis address with the global setting' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

          expect(t.dig('ConfigMap/test-registry', 'data', 'config.yml')).to include(
            <<~CONFIG
            redis:
              cache:
                enabled: true
                addr: "global.redis.example.com:16379"
            CONFIG
          )
        end
      end

      context 'when customer provides a custom redis cache configuration with a single host' do
        let(:values) do
          YAML.safe_load(%(
            registry:
              database:
                enabled: true
              redis:
                cache:
                  enabled: true
                  host: redis.example.com
                  port: 12345
                  db: 0
                  password:
                    enabled: true
                    secret: registry-redis-cache-secret
                    key: password
                  dialtimeout: 10ms
                  readtimeout: 10ms
                  writetimeout: 10ms
                  tls:
                    enabled: true
                    insecure: true
                  pool:
                    size: 10
                    maxlifetime: 1h
                    idletimeout: 300s
          )).deep_merge(default_values)
        end

        it 'populates the redis cache settings in the expected manner' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          expect(t.dig('ConfigMap/test-registry', 'data', 'config.yml')).to include(
            <<~CONFIG
            redis:
              cache:
                enabled: true
                addr: "redis.example.com:12345"
                password: "REDIS_CACHE_PASSWORD"
                db: 0
                dialtimeout: 10ms
                readtimeout: 10ms
                writetimeout: 10ms
                tls:
                  enabled: true
                  insecure: true
                pool:
                  size: 10
                  maxlifetime: 1h
                  idletimeout: 300s
            CONFIG
          )

          cache_secret = t.find_projected_secret_key('Deployment/test-registry', 'registry-secrets', 'registry-redis-cache-secret', 'password')
          expect(cache_secret).not_to be_empty
        end
      end

      context 'when customer provides a custom redis cache configuration with a single host without port' do
        let(:values) do
          YAML.safe_load(%(
            registry:
              database:
                enabled: true
              redis:
                cache:
                  enabled: true
                  host: redis.example.com
          )).deep_merge(default_values)
        end

        it 'populates the redis cache settings with the default port' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          expect(t.dig('ConfigMap/test-registry', 'data', 'config.yml')).to include(
            <<~CONFIG
            redis:
              cache:
                enabled: true
                addr: "redis.example.com:6379"
            CONFIG
          )
        end
      end

      context 'when customer provides a custom redis cache configuration with global sentinels' do
        let(:values) do
          YAML.safe_load(%(
            global:
              redis:
                host: redis.example.com
                sentinels:
                  - host: sentinel1.example.com
                    port: 26379
                  - host: sentinel2.example.com
                    port: 26379
            registry:
              database:
                enabled: true
              redis:
                cache:
                  enabled: true
        )).deep_merge(default_values)
        end

        it 'populates the redis cache settings in the expected manner' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          expect(t.dig('ConfigMap/test-registry', 'data', 'config.yml')).to include(
            <<~CONFIG
            redis:
              cache:
                enabled: true
                addr: "sentinel1.example.com:26379,sentinel2.example.com:26379"
                mainname: redis.example.com
            CONFIG
          )
        end
      end

      context 'when customer provides a custom redis cache configuration with local sentinels' do
        let(:values) do
          YAML.safe_load(%(
            registry:
              database:
                enabled: true
              redis:
                cache:
                  enabled: true
                  host: redis.example.com
                  sentinels:
                    - host: sentinel1.example.com
                      port: 26379
                    - host: sentinel2.example.com
                      port: 26379
        )).deep_merge(default_values)
        end

        it 'populates the redis cache settings in the expected manner' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          expect(t.dig('ConfigMap/test-registry', 'data', 'config.yml')).to include(
            <<~CONFIG
            redis:
              cache:
                enabled: true
                addr: "sentinel1.example.com:26379,sentinel2.example.com:26379"
                mainname: redis.example.com
            CONFIG
          )
        end
      end

      context 'when customer provides a custom redis cache configuration with local and global sentinels' do
        let(:values) do
          YAML.safe_load(%(
            global:
              redis:
                host: redis.example.com
                sentinels:
                  - host: global1.example.com
                    port: 26379
                  - host: global2.example.com
                    port: 26379
            registry:
              database:
                enabled: true
              redis:
                cache:
                  enabled: true
                  host: local.example.com
                  sentinels:
                    - host: local1.example.com
                      port: 26379
                    - host: local2.example.com
                      port: 26379
        )).deep_merge(default_values)
        end

        it 'populates the redis cache settings with the local sentinels' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          expect(t.dig('ConfigMap/test-registry', 'data', 'config.yml')).to include(
            <<~CONFIG
            redis:
              cache:
                enabled: true
                addr: "local1.example.com:26379,local2.example.com:26379"
                mainname: local.example.com
            CONFIG
          )
        end
      end
    end
  end

  describe 'debug TLS is configured' do
    context 'when enabled without required configuration' do
      let(:test_values) do
        YAML.safe_load(%(
          registry:
            debug:
              tls:
                enabled: true
        )).deep_merge(default_values)
      end

      it 'fails to render' do
        expect(HelmTemplate.new(test_values).exit_code).not_to eq(0)
      end
    end

    context 'when enabled and service tls is configured' do
      let(:test_values) do
        YAML.safe_load(%(
          global:
            hosts:
              registry:
                protocol: https
          registry:
            tls:
              enabled: true
              secretName: registry-service-tls
            debug:
              tls:
                enabled: true
        )).deep_merge(default_values)
      end

      it 'renders default debug tls configuration and sets healthcheck scheme to HTTPS' do
        t = HelmTemplate.new(test_values)

        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        expect(t.dig('ConfigMap/test-registry', 'data', 'config.yml')).to include(
          <<~DEBUG_TLS_CONFIG
          http:
            addr: :5000
            # `host` is not configurable
            # `prefix` is not configurable
            tls:
              certificate: /etc/docker/registry/tls/tls.crt
              key: /etc/docker/registry/tls/tls.key
              minimumTLS: "tls1.2"
            debug:
              addr: :5001
              prometheus:
                enabled: false
                path: /metrics
              tls:
                enabled: true
          DEBUG_TLS_CONFIG
        )

        tls_crt = t.find_projected_secret_key('Deployment/test-registry', 'registry-secrets', 'registry-service-tls', 'tls.crt')
        expect(tls_crt).not_to be_empty

        liveness_probe = t.find_container('Deployment/test-registry', 'registry')['livenessProbe']['httpGet']
        expect(liveness_probe['scheme']).to eq('HTTPS')

        readiness_probe = t.find_container('Deployment/test-registry', 'registry')['readinessProbe']['httpGet']
        expect(readiness_probe['scheme']).to eq('HTTPS')
      end
    end

    context 'when minimum required configuration provided' do
      let(:test_values) do
        YAML.safe_load(%(
          registry:
            debug:
              tls:
                enabled: true
                secretName: registry-debug-tls
        )).deep_merge(default_values)
      end

      it 'renders default debug tls configuration and sets healthcheck scheme to HTTPS' do
        t = HelmTemplate.new(test_values)

        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        expect(t.dig('ConfigMap/test-registry', 'data', 'config.yml')).to include(
          <<~DEBUG_TLS_CONFIG
          http:
            addr: :5000
            # `host` is not configurable
            # `prefix` is not configurable
            debug:
              addr: :5001
              prometheus:
                enabled: false
                path: /metrics
              tls:
                enabled: true
                certificate: /etc/docker/registry/tls/tls-debug.crt
                key: /etc/docker/registry/tls/tls-debug.key
                minimumTLS: "tls1.2"
          DEBUG_TLS_CONFIG
        )

        tls_crt = t.find_projected_secret_key('Deployment/test-registry', 'registry-secrets', 'registry-debug-tls', 'tls.crt')
        expect(tls_crt).not_to be_empty

        liveness_probe = t.find_container('Deployment/test-registry', 'registry')['livenessProbe']['httpGet']
        expect(liveness_probe['scheme']).to eq('HTTPS')

        readiness_probe = t.find_container('Deployment/test-registry', 'registry')['readinessProbe']['httpGet']
        expect(readiness_probe['scheme']).to eq('HTTPS')
      end
    end

    context 'when provided extended TLS configuration' do
      let(:test_values) do
        YAML.safe_load(%(
          registry:
            debug:
              tls:
                enabled: true
                secretName: registry-debug-tls
                clientCAs: [one, two, three]
                minimumTLS: "tls1.3"
        )).deep_merge(default_values)
      end

      it 'renders configuration as expected' do
        t = HelmTemplate.new(test_values)

        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        expect(t.dig('ConfigMap/test-registry', 'data', 'config.yml')).to include(
          <<~DEBUG_TLS_CONFIG
          http:
            addr: :5000
            # `host` is not configurable
            # `prefix` is not configurable
            debug:
              addr: :5001
              prometheus:
                enabled: false
                path: /metrics
              tls:
                enabled: true
                certificate: /etc/docker/registry/tls/tls-debug.crt
                key: /etc/docker/registry/tls/tls-debug.key
                clientCAs:
                  - one
                  - two
                  - three
                minimumTLS: "tls1.3"
          DEBUG_TLS_CONFIG
        )
      end
    end
  end
end
