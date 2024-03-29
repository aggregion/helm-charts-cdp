require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'gitlab-exporter configuration' do
  let(:default_values) do
    YAML.safe_load(%(
      certmanager-issuer:
        email: test@example.com
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
end
