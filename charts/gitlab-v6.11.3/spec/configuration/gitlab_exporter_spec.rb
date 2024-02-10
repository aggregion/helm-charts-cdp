require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'gitlab-exporter configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global: {}
      gitlab:
        gitlab-exporter:
          serviceAccount:
            enabled: true
            create: true
    ))
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
        gitlab:
          gitlab-exporter:
            common:
              labels:
                global: exporter
                exporter: exporter
            podLabels:
              pod: true
              global: pod
            serviceLabels:
              service: true
              global: service
      )).deep_merge(default_values)
    end

    it 'Populates the additional labels in the expected manner' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      expect(t.dig('ConfigMap/test-gitlab-exporter', 'metadata', 'labels')).to include('global' => 'exporter')
      expect(t.dig('Deployment/test-gitlab-exporter', 'metadata', 'labels')).to include('foo' => 'global')
      expect(t.dig('Deployment/test-gitlab-exporter', 'metadata', 'labels')).to include('global' => 'exporter')
      expect(t.dig('Deployment/test-gitlab-exporter', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('Deployment/test-gitlab-exporter', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
      expect(t.dig('Deployment/test-gitlab-exporter', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
      expect(t.dig('Deployment/test-gitlab-exporter', 'spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
      expect(t.dig('Service/test-gitlab-exporter', 'metadata', 'labels')).to include('global' => 'service')
      expect(t.dig('Service/test-gitlab-exporter', 'metadata', 'labels')).to include('global_service' => 'true')
      expect(t.dig('Service/test-gitlab-exporter', 'metadata', 'labels')).to include('service' => 'true')
      expect(t.dig('Service/test-gitlab-exporter', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('ServiceAccount/test-gitlab-exporter', 'metadata', 'labels')).to include('global' => 'exporter')
    end
  end

  context 'When customer enables TLS' do
    let(:template) do
      values = YAML.safe_load(%(
      gitlab:
        gitlab-exporter:
          tls:
            enabled: true
            secretName: exporter-tls-secret
      )).deep_merge(default_values)
      HelmTemplate.new values
    end

    it 'should render the template without error' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
    end

    it 'should mount the TLS certificates' do
      volumes = template.dig('Deployment/test-gitlab-exporter', 'spec', 'template', 'spec', 'volumes')
      init_secrets = volumes.find { |v| v["name"] == "init-gitlab-exporter-secrets" }
      tls_secret = init_secrets.dig("projected", "sources").find { |s| s.dig("secret", "name") == "exporter-tls-secret" }

      expect(tls_secret).not_to be_nil
      expect(tls_secret["secret"]["items"]).to include({ 'key' => 'tls.crt', 'path' => 'gitlab-exporter/tls.crt' })
      expect(tls_secret["secret"]["items"]).to include({ 'key' => 'tls.key', 'path' => 'gitlab-exporter/tls.key' })
    end

    it 'should configure TLS usage' do
      config = template.dig('ConfigMap/test-gitlab-exporter', 'data', 'gitlab-exporter.yml.erb')
      expect(config).to include 'tls_enabled: true'
    end
  end
end
