# frozen_string_literal: true
require 'spec_helper'
require 'hash_deep_merge'
require 'helm_template_helper'
require 'yaml'

describe 'kas configuration' do
  let(:default_values) do
    HelmTemplate.defaults
  end

  let(:custom_secret_key) { 'kas_custom_secret_key' }
  let(:custom_secret_name) { 'kas_custom_secret_name' }
  let(:custom_config) { {} }

  let(:default_kas_values) do
    YAML.safe_load(%(
      gitlab:
        kas:
          customConfig: #{custom_config.to_json}
      global:
        image:
          pullPolicy: Always
        appConfig:
          gitlab_kas:
            key: #{custom_secret_key}
            secret: #{custom_secret_name}
    ))
  end

  let(:kas_values) { default_kas_values }

  let(:required_resources) do
    %w[Deployment ConfigMap Ingress Service HorizontalPodAutoscaler PodDisruptionBudget]
  end

  context 'when kas is disabled' do
    let(:disable_kas) do
      { 'global' => { 'kas' => { 'enabled' => false } } }
    end

    it 'does not create any kas related resource' do
      template = HelmTemplate.new(default_values.merge!(disable_kas))

      required_resources.each do |resource|
        resource_name = "#{resource}/test-kas"

        expect(template.resources_by_kind(resource)[resource_name]).to be_nil
      end
    end
  end

  context 'When customer provides additional labels' do
    let(:kas_label_values) do
      YAML.safe_load(%(
        global:
          common:
            labels:
              global: global
              foo: global
          kas:
            enabled: true
          pod:
            labels:
              global_pod: true
          service:
            labels:
              global_service: true
        gitlab:
          kas:
            common:
              labels:
                global: kas
                kas: kas
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
      )).merge(default_values)
    end

    it 'Populates the additional labels in the expected manner' do
      t = HelmTemplate.new(kas_label_values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      expect(t.dig('ConfigMap/test-kas', 'metadata', 'labels')).to include('global' => 'kas')
      expect(t.dig('Deployment/test-kas', 'metadata', 'labels')).to include('foo' => 'global')
      expect(t.dig('Deployment/test-kas', 'metadata', 'labels')).to include('global' => 'kas')
      expect(t.dig('Deployment/test-kas', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('Deployment/test-kas', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
      expect(t.dig('Deployment/test-kas', 'spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
      expect(t.dig('Deployment/test-kas', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
      expect(t.dig('HorizontalPodAutoscaler/test-kas', 'metadata', 'labels')).to include('global' => 'kas')
      expect(t.dig('Ingress/test-kas', 'metadata', 'labels')).to include('global' => 'kas')
      expect(t.dig('PodDisruptionBudget/test-kas', 'metadata', 'labels')).to include('global' => 'kas')
      expect(t.dig('Service/test-kas', 'metadata', 'labels')).to include('global' => 'service')
      expect(t.dig('Service/test-kas', 'metadata', 'labels')).to include('global_service' => 'true')
      expect(t.dig('Service/test-kas', 'metadata', 'labels')).to include('service' => 'true')
      expect(t.dig('Service/test-kas', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('ServiceAccount/test-kas', 'metadata', 'labels')).to include('global' => 'kas')
    end
  end

  context 'when kas is enabled with custom values' do
    let(:kas_enabled_template) do
      HelmTemplate.new(default_values.merge(kas_values))
    end

    it 'creates all kas related required_resources' do
      required_resources.each do |resource|
        resource_name = "#{resource}/test-kas"

        expect(kas_enabled_template.resources_by_kind(resource)[resource_name]).to be_kind_of(Hash)
      end
    end

    it 'mounts shared secret on webservice deployment' do
      webservice_secret_mounts = kas_enabled_template.projected_volume_sources(
        'Deployment/test-webservice-default',
        'init-webservice-secrets'
      )

      shared_secret_mount = webservice_secret_mounts.select do |item|
        item['secret']['name'] == custom_secret_name && item['secret']['items'][0]['key'] == custom_secret_key
      end

      expect(shared_secret_mount.length).to eq(1)
    end

    it 'mounts shared secret on kas deployment' do
      kas_secret_mounts = kas_enabled_template.projected_volume_sources(
        'Deployment/test-kas',
        'init-etc-kas'
      )

      shared_secret_mount = kas_secret_mounts.select do |item|
        item.dig('secret', 'name') == custom_secret_name && item.dig('secret', 'items', 0, 'key') == custom_secret_key
      end

      expect(shared_secret_mount.length).to eq(1)
    end

    it 'mounts config on kas deployment' do
      volume_mount = kas_enabled_template.projected_volume_sources(
        'Deployment/test-kas',
        'init-etc-kas'
      )

      config_map_mounts = volume_mount.select do |item|
        item['configMap'] && item['configMap']['name'] == 'test-kas'
      end

      expect(config_map_mounts.length).to eq(1)
    end

    describe 'templates/configmap.yaml' do
      subject(:config_yaml_data) do
        YAML.safe_load(kas_enabled_template.dig('ConfigMap/test-kas', 'data', 'config.yaml'), permitted_classes: [Symbol])
      end

      it 'uses the default configuration' do
        expect(config_yaml_data['gitlab']).not_to be_nil
      end

      it 'sets the external url for GitLab' do
        expect(config_yaml_data['gitlab']['external_url']).to eq('https://gitlab.example.com')
      end

      describe 'tls config' do
        shared_context 'privateApi with tls' do
          it 'configures the privateApi with certificate files' do
            expected_config = {
              "listen" => {
                "address" => :"8155",
                "authentication_secret_file" => "/etc/kas/.gitlab_kas_private_api_secret",
                "ca_certificate_file" => "/etc/ssl/certs/ca-certificates.crt",
                "certificate_file" => "/etc/kas/tls.crt",
                "key_file" => "/etc/kas/tls.key"
              }
            }

            expect(config_yaml_data['private_api']).to eq(expected_config)
          end
        end

        context 'when global.kas.tls is enabled' do
          let(:kas_values) do
            default_kas_values.deep_merge!(YAML.safe_load(%(
                global:
                  kas:
                    tls:
                      enabled: true
              )))
          end

          it 'configures agent servers with certificate files' do
            expected_config = {
              "listen" => {
                "address" => :"8150",
                "websocket" => true,
                "certificate_file" => "/etc/kas/tls.crt",
                "key_file" => "/etc/kas/tls.key"
              },
              "kubernetes_api" => {
                "listen" => {
                  "address" => :"8154",
                  "certificate_file" => "/etc/kas/tls.crt",
                  "key_file" => "/etc/kas/tls.key"
                },
                "url_path_prefix" => "/k8s-proxy"
              }
            }

            expect(config_yaml_data['agent']).to eq(expected_config)
          end

          it 'configures the server for GitLab requests with certificate files' do
            expected_config = {
              "listen" => {
                "address" => :"8153",
                "authentication_secret_file" => "/etc/kas/.gitlab_kas_secret",
                "certificate_file" => "/etc/kas/tls.crt",
                "key_file" => "/etc/kas/tls.key"
              }
            }

            expect(config_yaml_data['api']).to eq(expected_config)
          end

          it_behaves_like 'privateApi with tls'
        end

        context 'when privateApi.tls is enabled' do
          let(:kas_values) do
            default_kas_values.deep_merge!(YAML.safe_load(%(
                gitlab:
                  kas:
                    privateApi:
                      tls:
                        enabled: true
              )))
          end

          it_behaves_like 'privateApi with tls'
        end
      end

      context 'when customConfig is given' do
        let(:custom_config) do
          YAML.safe_load(%(
            example: config
            agent:
              listen:
                websocket: false
          ))
        end

        it 'deeply merges the custom config' do
          expect(config_yaml_data['example']).to eq('config')
          expect(config_yaml_data['agent']['listen']['address']).not_to be_nil
          expect(config_yaml_data['agent']['listen']['websocket']).to eq(false)
        end
      end

      describe 'redis config' do
        let(:sentinels) do
          YAML.safe_load(%(
            redis:
              host: global.host
              sentinels:
              - host: sentinel1.example.com
                port: 26379
              - host: sentinel2.example.com
                port: 26379
          ))
        end

        context 'when redis is disabled' do
          let(:kas_values) do
            default_kas_values.deep_merge!(YAML.safe_load(%(
              gitlab:
                kas:
                  redis:
                    enabled: false
            )))
          end

          it 'does not have redis config' do
            expect(config_yaml_data['redis']).to eq(nil)
          end
        end

        context 'when redisConfigName is empty' do
          context 'when global redis has no password' do
            let(:kas_values) do
              default_kas_values.deep_merge!(YAML.safe_load(%(
                global:
                  redis:
                    password:
                      enabled: false
              )))
            end

            it 'does not set password_file' do
              expect(config_yaml_data['redis']).not_to have_key("password_file")
            end
          end

          context 'when no sentinel is setup' do
            it 'takes the global redis config' do
              expect(config_yaml_data['redis']).to include(YAML.safe_load(%(
                password_file: /etc/kas/redis/redis-password
                server:
                  address: test-redis-master.default.svc:6379
              )))
            end
          end

          context 'when sentinel is setup' do
            let(:kas_values) do
              vals = default_kas_values
              vals['global'].deep_merge!(sentinels)
              vals.deep_merge!('redis' => { 'install' => false })
            end

            it 'takes the global sentinel redis config' do
              expect(config_yaml_data['redis']).to include(YAML.safe_load(%(
                sentinel:
                  addresses:
                    - sentinel1.example.com:26379
                    - sentinel2.example.com:26379
                  master_name: global.host
              )))
            end
          end
        end

        context 'when a redis sharedState is setup' do
          let(:kas_values) do
            vals = default_kas_values
            vals['global'].deep_merge!(redis_shared_state_config)
            vals.deep_merge!('redis' => { 'install' => false })
          end

          let(:redis_password_enabled) { true }

          let(:redis_shared_state_config) do
            YAML.safe_load(%(
              redis:
                host: global.host
                sharedState:
                  host: shared.redis
                  port: 6378
                  password:
                    enabled: #{redis_password_enabled}
                    secret: shared-secret
                    key: shared-key
                  sentinels: #{sentinels.to_json}
            ))
          end

          context 'when no sharedState sentinel is setup' do
            context 'with no sentinels' do
              let(:sentinels) { {} }
              it 'configures a sharedState server config' do
                expect(config_yaml_data['redis']).to include(YAML.safe_load(%(
                  password_file: /etc/kas/redis/sharedState-password
                  server:
                    address: shared.redis:6378
                )))
              end
            end
          end

          context 'when sharedState sentinel is setup' do
            let(:sentinels) do
              YAML.safe_load(%(
                - host: sentinel1.shared.com
                  port: 26379
                - host: sentinel2.shared.com
                  port: 26379
              ))
            end

            it 'configures a sharedState sentinel config' do
              expect(config_yaml_data['redis']).to include(YAML.safe_load(%(
                password_file: /etc/kas/redis/sharedState-password
                sentinel:
                  addresses:
                    - sentinel1.shared.com:26379
                    - sentinel2.shared.com:26379
                  master_name: shared.redis
              )))
            end
          end

          context 'when redis has no password' do
            let(:redis_password_enabled) { false }

            it 'does not set password_file' do
              expect(config_yaml_data['redis']).not_to have_key("password_file")
            end
          end
        end

        describe 'tls' do
          let(:kas_values) { default_kas_values }

          it 'is empty by default' do
            expect(config_yaml_data['redis']).not_to include('tls')
          end

          context 'when redis scheme is "rediss"' do
            let(:kas_values) do
              default_kas_values.deep_merge!(YAML.safe_load(%(
                global:
                  redis:
                    scheme: rediss
              )))
            end

            it 'is enabled' do
              expect(config_yaml_data['redis']).to include(YAML.safe_load(%(
                tls:
                  enabled: true
              )))
            end
          end
        end
      end

      context 'when observability.port is given' do
        let(:kas_values) do
          default_kas_values.deep_merge!(YAML.safe_load(%(
            gitlab:
              kas:
                observability:
                  port: 4242
          )))
        end

        it 'sets the correct observability address' do
          expect(config_yaml_data['observability']['listen']['address']).to eq(:"4242")
        end
      end

      context 'when observability probe endpoints are given' do
        let(:kas_values) do
          default_kas_values.deep_merge!(YAML.safe_load(%(
            gitlab:
              kas:
                observability:
                  livenessProbe:
                    path: '/lP'
                  readinessProbe:
                    path: '/rP'
          )))
        end

        it 'sets the correct observability url paths' do
          expect(config_yaml_data['observability']['liveness_probe']).to include(YAML.safe_load(%(
            url_path: '/lP'
          )))
          expect(config_yaml_data['observability']['readiness_probe']).to include(YAML.safe_load(%(
            url_path: '/rP'
          )))
        end
      end
    end

    describe 'templates/service.yaml' do
      subject(:service) { kas_enabled_template.resources_by_kind('Service')['Service/test-kas'] }

      context 'when type is LoadBalancer' do
        let(:service_values) { {} }

        let(:kas_values) do
          default_kas_values.deep_merge!(
            'gitlab' => {
              'kas' => {
                'service' => {
                  'type' => 'LoadBalancer'
                }.merge!(service_values)
              }
            }
          )
        end

        it 'has LoadBalancer type and no customizations by default' do
          expect(service['spec']).to include('type' => 'LoadBalancer')
          expect(service['spec']).not_to have_key('loadBalancerIP')
          expect(service['spec']).not_to have_key('loadBalancerSourceRanges')
        end

        context 'when service.loadBalancerIP is given' do
          let(:service_values) { { 'loadBalancerIP' => 'the ip' } }

          it 'contains the loadBalancerIP customization' do
            expect(service['spec']).to include('loadBalancerIP' => 'the ip')
          end
        end

        context 'when service.loadBalancerSourceRanges is given' do
          let(:service_values) { { 'loadBalancerSourceRanges' => ['a', 'b', 'c'] } }

          it 'contains the loadBalancerSourceRanges customization' do
            expect(service['spec']).to include('loadBalancerSourceRanges' => ['a', 'b', 'c'])
          end
        end
      end

      context 'when metrics.enabled is given' do
        let(:metrics_enabled) { true }
        let(:kas_values) do
          default_kas_values.deep_merge!(
            'gitlab' => {
              'kas' => {
                'metrics' => {
                  'enabled' => metrics_enabled
                }
              }
            }
          )
        end

        context 'when metrics.enabled is true' do
          let(:metrics_enabled) { true }

          it 'exports metrics port' do
            expect(service['spec']['ports']).to include(include("name" => "http-metrics"))
          end
        end

        context 'when metrics.enabled is false' do
          let(:metrics_enabled) { false }

          it 'exports no metrics port' do
            expect(service['spec']['ports']).not_to include(include("name" => "http-metrics"))
          end
        end
      end
    end

    describe 'templates/deployment.yaml' do
      subject(:deployment) { kas_enabled_template.resources_by_kind('Deployment')['Deployment/test-kas'] }

      let(:global_values) { {} }
      let(:deployment_values) { {} }

      let(:kas_values) do
        default_kas_values.deep_merge!(
          **global_values,
          'gitlab' => {
            'kas' => {
              'deployment' => {}.merge!(deployment_values)
            }
          }
        )
      end

      it 'does not specify minReadySeconds' do
        expect(deployment['spec']).not_to have_key('minReadySeconds')
      end

      context 'env' do
        let(:env) { deployment['spec']['template']['spec']['containers'].first['env'] }

        it 'sets OWN_PRIVATE_API_URL to use grpc' do
          expect(env).to include(
            { "name" => "OWN_PRIVATE_API_URL", "value" => "grpc://$(POD_IP):8155" }
          )
        end

        it 'sets OWN_PRIVATE_API_HOST to use its service host' do
          expect(env).to include(
            { "name" => "OWN_PRIVATE_API_HOST", "value" => "test-kas.default.svc" }
          )
        end

        context 'extraEnv is set' do
          let(:global_values) do
            YAML.safe_load(%(
              global:
                extraEnv:
                  EXTRA_ENV_VAR_A: global-a
                  EXTRA_ENV_VAR_B: global-b
            ))
          end

          it 'inherits global values' do
            expect(env).to include(
              { 'name' => 'EXTRA_ENV_VAR_A', 'value' => 'global-a' },
              { 'name' => 'EXTRA_ENV_VAR_B', 'value' => 'global-b' }
            )
          end
        end

        context 'extraEnvFrom is set' do
          let(:global_values) do
            YAML.safe_load(%(
              global:
                extraEnvFrom:
                  EXTRA_ENV_VAR_C:
                    secretKeyRef:
                      key: "keyC"
                      name: "nameC"
                  EXTRA_ENV_VAR_D:
                    secretKeyRef:
                      key: "keyD"
                      name: "nameD"
            ))
          end

          it 'inherites global values' do
            expect(env).to include(
              { 'name' => 'EXTRA_ENV_VAR_C', 'valueFrom' => { "secretKeyRef" => { "name" => "nameC", "key" => "keyC" } } },
              { 'name' => 'EXTRA_ENV_VAR_D', 'valueFrom' => { "secretKeyRef" => { "name" => "nameD", "key" => "keyD" } } }
            )
          end
        end
      end

      context 'when deployment.minReadySeconds is given' do
        let(:deployment_values) { { 'minReadySeconds' => 60 } }

        it 'contains the minReadySeconds customization' do
          expect(deployment['spec']).to include('minReadySeconds' => 60)
        end
      end

      describe 'tls' do
        shared_context 'a deployment with tls' do
          it 'sets OWN_PRIVATE_API_URL to use grpcs' do
            expect(deployment['spec']['template']['spec']['containers'].first['env']).to include(
              { "name" => "OWN_PRIVATE_API_URL", "value" => "grpcs://$(POD_IP):8155" }
            )
          end

          it 'creates the TLS secret volume' do
            init_etc_kas_volume = deployment['spec']['template']['spec']['volumes'].find do |volume|
              volume['name'] == 'init-etc-kas'
            end

            expect(init_etc_kas_volume['projected']['sources']).to include(
              {
                "secret" => {
                  "name" => "example-tls",
                  "items" => [
                    { "key" => "tls.crt", "path" => "tls.crt" },
                    { "key" => "tls.key", "path" => "tls.key" }
                  ]
                }
              }
            )
          end
        end

        context 'when privateApi.tls is enabled' do
          let(:kas_values) do
            default_kas_values.deep_merge!(YAML.safe_load(%(
                gitlab:
                  kas:
                    privateApi:
                      tls:
                        enabled: true
                        secretName: example-tls
              )))
          end

          it_behaves_like 'a deployment with tls'
        end

        context 'when global.kas.tls is enabled' do
          let(:kas_values) do
            default_kas_values.deep_merge!(YAML.safe_load(%(
                global:
                  kas:
                    tls:
                      enabled: true
                      secretName: example-tls
              )))
          end

          it_behaves_like 'a deployment with tls'
        end
      end

      context 'when metrics.enabled is given' do
        let(:metrics_enabled) { true }
        let(:service_monitor_enabled) { false }

        let(:kas_values) do
          default_kas_values.deep_merge!(
            'gitlab' => {
              'kas' => {
                'metrics' => {
                  'enabled' => metrics_enabled,
                  'serviceMonitor' => {
                    'enabled' => service_monitor_enabled
                  }
                }
              }
            }
          )
        end

        context 'when metrics.enabled is true' do
          let(:metrics_enabled) { true }

          context 'when metrics.serviceMonitor.enabled is true' do
            let(:service_monitor_enabled) { true }

            it 'does not set prometheus annotations' do
              expect(deployment['spec']['template']['metadata']['annotations'].keys).not_to include(include("prometheus"))
            end
          end

          context 'when metrics.serviceMonitor.enabled is false' do
            let(:service_monitor_enabled) { false }

            it 'does set prometheus annotations' do
              expect(deployment['spec']['template']['metadata']['annotations'].keys).to include(include("prometheus"))
            end
          end
        end

        context 'when metrics.enabled is false' do
          let(:metrics_enabled) { true }

          context 'when metrics.serviceMonitor.enabled is true' do
            let(:service_monitor_enabled) { true }

            it 'does not set prometheus annotations' do
              expect(deployment['spec']['template']['metadata']['annotations'].keys).not_to include(include("prometheus"))
            end
          end
        end
      end

      context 'when observability probe endpoints are given' do
        let(:kas_values) do
          default_kas_values.deep_merge!(YAML.safe_load(%(
            gitlab:
              kas:
                observability:
                  livenessProbe:
                    path: '/lP'
                  readinessProbe:
                    path: '/rP'
          )))
        end

        it 'configures livenessProbe' do
          expect(deployment['spec']['template']['spec']['containers'].first['livenessProbe']['httpGet']).to eq({ "path" => "/lP", "port" => 8151 })
        end

        it 'configures readinessProbe' do
          expect(deployment['spec']['template']['spec']['containers'].first['readinessProbe']['httpGet']).to eq({ "path" => "/rP", "port" => 8151 })
        end
      end
    end
  end

  describe 'gitlab.yml.erb/gitlab_kas' do
    let(:helm_template) do
      HelmTemplate.new(default_values.merge(kas_values))
    end

    def gitlab_yml(chart)
      YAML.safe_load(
        helm_template.resources_by_kind('ConfigMap')["ConfigMap/test-#{chart}"]['data']['gitlab.yml.erb']
      )['production']['gitlab_kas']
    end

    %w[webservice toolbox sidekiq].each do |chart|
      context "for #{chart}" do
        it 'has the correct defaults' do
          expect(gitlab_yml(chart)).to include(YAML.safe_load(%(
            enabled: true
            internal_url: grpc://test-kas.default.svc:8153
            external_url: wss://kas.example.com
          )))
        end

        context 'when using a custom external hostname' do
          let(:kas_values) do
            default_kas_values.deep_merge!(YAML.safe_load(%(
              global:
                hosts:
                  kas:
                    name: kas.other.example.com
            )))
          end

          it 'uses the custom host for the external URL' do
            expect(gitlab_yml(chart)).to include(YAML.safe_load(%(
              external_url: wss://kas.other.example.com
            )))
          end
        end

        context 'when using custom URLs' do
          let(:kas_values) do
            default_kas_values.deep_merge!(YAML.safe_load(%(
              global:
                appConfig:
                  gitlab_kas:
                    externalUrl: wss://custom-external-url.example.com
                    internalUrl: grpc://custom-internal-url.example.com
            )))
          end

          it 'uses the custom external URL' do
            expect(gitlab_yml(chart)).to include(YAML.safe_load(%(
              external_url: wss://custom-external-url.example.com
              internal_url: grpc://custom-internal-url.example.com
            )))
          end
        end

        context 'when kas is fully disabled' do
          let(:kas_values) do
            default_kas_values.deep_merge!(YAML.safe_load(%(
              global:
                kas:
                  enabled: false
            )))
          end

          it 'is not present' do
            expect(gitlab_yml(chart)).to be(nil)
          end
        end

        context 'when kas chart is disabled, but gitlab_kas is enabled in the appConfig' do
          let(:kas_values) do
            default_kas_values.deep_merge!(YAML.safe_load(%(
              global:
                kas:
                  enabled: false
                appConfig:
                  gitlab_kas:
                    enabled: true
                    externalUrl: wss://custom-external-url.example.com
                    internalUrl: grpc://custom-internal-url.example.com
            )))
          end

          it 'renders the custom values in gitlab.yml.erb' do
            expect(gitlab_yml(chart)).to include(YAML.safe_load(%(
              enabled: true
              external_url: wss://custom-external-url.example.com
              internal_url: grpc://custom-internal-url.example.com
            )))
          end
        end
      end
    end
  end
end
