# frozen_string_literal: true
require 'spec_helper'
require 'hash_deep_merge'
require 'helm_template_helper'
require 'yaml'

describe 'spamcheck configuration' do
  let(:default_values) do
    HelmTemplate.defaults
  end

  let(:required_resources) do
    %w[Deployment ConfigMap Service HorizontalPodAutoscaler PodDisruptionBudget]
  end

  context 'with spamcheck disabled' do
    let(:spamcheck_disabled_values) do
      YAML.safe_load(%(
        gitlab:
          spamcheck:
            enabled: false
        global:
          spamcheck:
            enabled: false
      )).deep_merge(default_values)
    end

    let(:spamcheck_disabled_template) { HelmTemplate.new(spamcheck_disabled_values) }

    it 'does not create any spamcheck related resources' do
      required_resources.each do |resource|
        resource_name = "#{resource}/test-spamcheck"

        expect(spamcheck_disabled_template.resources_by_kind(resource)[resource_name]).to be_nil
      end
    end
  end

  context 'when spamcheck is enabled' do
    let(:spamcheck_enabled_values) do
      YAML.safe_load(%(
        gitlab:
          spamcheck:
            enabled: true
        global:
          spamcheck:
            enabled: true
      ))
    end

    let(:spamcheck_enabled_template) do
      HelmTemplate.new(default_values.merge(spamcheck_enabled_values))
    end

    it 'creates all spamcheck related required_resources' do
      required_resources.each do |resource|
        resource_name = "#{resource}/test-spamcheck"

        expect(spamcheck_enabled_template.resources_by_kind(resource)[resource_name]).to be_kind_of(Hash)
      end
    end

    context 'When customer provides additional labels' do
      let(:spamcheck_label_values) do
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
            spamcheck:
              common:
                labels:
                  global: spamcheck
                  spamcheck: spamcheck
              podLabels:
                pod: true
                global: pod
              serviceAccount:
                create: true
                enabled: true
              serviceLabels:
                service: true
                global: service
        )).deep_merge(spamcheck_enabled_values.deep_merge(default_values))
      end

      it 'Populates the additional labels in the expected manner' do
        t = HelmTemplate.new(spamcheck_label_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        expect(t.dig('ConfigMap/test-spamcheck', 'metadata', 'labels')).to include('global' => 'spamcheck')
        expect(t.dig('Deployment/test-spamcheck', 'metadata', 'labels')).to include('foo' => 'global')
        expect(t.dig('Deployment/test-spamcheck', 'metadata', 'labels')).to include('global' => 'spamcheck')
        expect(t.dig('Deployment/test-spamcheck', 'metadata', 'labels')).not_to include('global' => 'global')
        expect(t.dig('Deployment/test-spamcheck', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
        expect(t.dig('Deployment/test-spamcheck', 'spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
        expect(t.dig('Deployment/test-spamcheck', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
        expect(t.dig('HorizontalPodAutoscaler/test-spamcheck', 'metadata', 'labels')).to include('global' => 'spamcheck')
        expect(t.dig('PodDisruptionBudget/test-spamcheck', 'metadata', 'labels')).to include('global' => 'spamcheck')
        expect(t.dig('Service/test-spamcheck', 'metadata', 'labels')).to include('global' => 'service')
        expect(t.dig('Service/test-spamcheck', 'metadata', 'labels')).to include('global_service' => 'true')
        expect(t.dig('Service/test-spamcheck', 'metadata', 'labels')).to include('service' => 'true')
        expect(t.dig('Service/test-spamcheck', 'metadata', 'labels')).not_to include('global' => 'global')
        expect(t.dig('ServiceAccount/test-spamcheck', 'metadata', 'labels')).to include('global' => 'spamcheck')
      end
    end
  end
end
