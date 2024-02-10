require 'hash_deep_merge'
require 'helm_template_helper'
require 'spec_helper'
require 'yaml'

describe 'PodDisruptionBudget configuration' do
  let(:values) { {} }
  let(:helm_args) { '' }
  let(:gitlab_subcharts) { %w[gitaly gitlab-pages gitlab-shell kas sidekiq spamcheck webservice] }
  let(:subcharts) { %w[minio nginx-ingress registry] }
  let(:template) { HelmTemplate.new(default_values.deep_merge(values), 'test', helm_args) }

  let :default_values do
    HelmTemplate.with_defaults(%(
      global:
        pages:
          enabled: true
        kas:
          enabled: true
        spamcheck:
          enabled: true
    ))
  end

  let :api_versions do
    template.mapped.select { |k, v| k.start_with? 'PodDisruptionBudget/' }.to_h { |k, v| [v.dig('metadata', 'labels', 'app'), v['apiVersion']] }
  end

  describe 'apiVersion' do
    context 'when not specified' do
      it 'uses policy/v1beta1' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
        expect(api_versions.values).to all(eq 'policy/v1beta1')
      end
    end

    context 'when policy/v1 is supported' do
      let :helm_args do
        '--api-versions=policy/v1/PodDisruptionBudget --api-versions=policy/v1beta1/PodDisruptionBudget'
      end

      it 'uses policy/v1' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
        expect(api_versions.values).to all(eq 'policy/v1')
      end
    end

    context 'when global override is set' do
      let :values do
        YAML.safe_load(%(
          global:
            pdb:
              apiVersion: policy/global/v1
        ))
      end

      it 'uses the global value' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
        expect(api_versions.values).to all(eq 'policy/global/v1')
      end
    end

    context 'when local and global overrides are set' do
      let :values do
        v = YAML.safe_load(%(
          global:
            pdb:
              apiVersion: policy/global/v1
          gitlab: {}
        ))

        subcharts.each do |n|
          v[n] = { 'pdb' => { 'apiVersion' => "policy/#{n}/v1" } }
        end

        gitlab_subcharts.each do |n|
          v['gitlab'][n] = { 'pdb' => { 'apiVersion' => "policy/#{n}/v1" } }
        end

        v
      end

      it 'uses the local value' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        api_versions.each_pair do |k, v|
          expect(v).to eq("policy/#{k}/v1")
        end
      end
    end
  end
end
