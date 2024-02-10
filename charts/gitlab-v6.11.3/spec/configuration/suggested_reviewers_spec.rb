require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Suggested Reviewers configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
        global:
          appConfig:
            suggested_reviewers:
              secret: #{custom_secret_name}
              key: #{custom_secret_key}
    ))
  end

  let(:custom_secret_key) { 'suggested_reviewers_custom_secret_key' }
  let(:custom_secret_name) { 'suggested_reviewers_custom_secret_name' }

  let(:template) { HelmTemplate.new(default_values) }

  shared_examples 'configured with suggested_reviewers' do
    it 'populates suggested_reviewers to gitlab.yml', :aggregate_failures do
      expect(template.exit_code).to eq(0)

      gitlab_yml_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb')
      expect(gitlab_yml_erb).to include('secret_file: /etc/gitlab/suggested_reviewers/.gitlab_suggested_reviewers_secret')
    end

    it 'includes suggested_reviewers in configure script' do
      configure = template.dig("ConfigMap/test-#{chart}", 'data', 'configure')
      expect(configure).to match(/# optional\nfor secret in.*suggested_reviewers.*; do/m)
    end

    it 'mounts shared secret' do
      shared_secret_mount = secret_mounts.select do |item|
        item['secret']['name'] == custom_secret_name && item['secret']['items'][0]['key'] == custom_secret_key
      end

      expect(shared_secret_mount.length).to eq(1)
    end
  end

  context 'when webservice' do
    let(:chart) { 'webservice' }
    let(:secret_mounts) do
      template.projected_volume_sources(
        'Deployment/test-webservice-default',
        'init-webservice-secrets'
      )
    end

    it_behaves_like 'configured with suggested_reviewers'
  end

  context 'when sidekiq' do
    let(:chart) { 'sidekiq' }
    let(:secret_mounts) do
      template.projected_volume_sources(
        'Deployment/test-sidekiq-all-in-1-v2',
        'init-sidekiq-secrets'
      )
    end

    it_behaves_like 'configured with suggested_reviewers'
  end

  context 'when toolbox' do
    let(:chart) { 'toolbox' }
    let(:secret_mounts) do
      template.projected_volume_sources(
        'Deployment/test-toolbox',
        'init-toolbox-secrets'
      )
    end

    it_behaves_like 'configured with suggested_reviewers'
  end
end
