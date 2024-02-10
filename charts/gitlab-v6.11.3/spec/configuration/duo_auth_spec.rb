require 'spec_helper'
require 'helm_template_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Duo Auth configuration' do
  shared_examples 'configured with duoAuth' do
    it 'populates duoAuth to gitlab.yml', :aggregate_failures do
      expect(template.exit_code).to eq(0)

      gitlab_yml_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb')
      gitlab_yml = YAML.safe_load(gitlab_yml_erb)
      expect(gitlab_yml["production"]["duo_auth"]).not_to be_nil
      expect(gitlab_yml["production"]["duo_auth"]["enabled"]).to eq(true)
      expect(gitlab_yml["production"]["duo_auth"]["hostname"]).to eq('test.api.hostname')
      expect(gitlab_yml["production"]["duo_auth"]["integration_key"]).to eq('dummy_integration_key')
      expect(gitlab_yml["production"]["duo_auth"]["secret_key"]).to_not be_nil
    end
  end

  shared_examples 'not configured with duoAuth' do
    it 'populates duoAuth to gitlab.yml', :aggregate_failures do
      expect(template.exit_code).to eq(0)

      gitlab_yml_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb')
      gitlab_yml = YAML.safe_load(gitlab_yml_erb)
      expect(gitlab_yml["production"]["duo_auth"]).not_to be_nil
      expect(gitlab_yml["production"]["duo_auth"]["enabled"]).to eq(false)
    end
  end

  context 'when duoAuth is enabled' do
    let(:default_values) do
      HelmTemplate.with_defaults(%(
        global:
          appConfig:
            duoAuth:
              enabled: true
              hostname: test.api.hostname
              integrationKey: dummy_integration_key
              secretKey:
                secret: SecretName
                key: KeyName
      ))
    end

    let(:template) { HelmTemplate.new(default_values) }

    context 'when webservice' do
      let(:chart) { 'webservice' }

      it_behaves_like 'configured with duoAuth'
    end

    context 'when sidekiq' do
      let(:chart) { 'sidekiq' }

      it_behaves_like 'configured with duoAuth'
    end

    context 'when toolbox' do
      let(:chart) { 'toolbox' }

      it_behaves_like 'configured with duoAuth'
    end
  end

  context 'when duoAuth is not enabled' do
    let(:default_values) do
      HelmTemplate.with_defaults(%(
        global:
          appConfig:
            duoAuth:
              enabled: false
      ))
    end

    let(:template) { HelmTemplate.new(default_values) }

    context 'when sidekiq' do
      let(:chart) { 'sidekiq' }

      it_behaves_like 'not configured with duoAuth'
    end

    context 'when toolbox' do
      let(:chart) { 'toolbox' }

      it_behaves_like 'not configured with duoAuth'
    end

    context 'when webservice' do
      let(:chart) { 'webservice' }

      it_behaves_like 'not configured with duoAuth'
    end
  end
end
