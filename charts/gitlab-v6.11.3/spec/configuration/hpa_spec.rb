require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'GitLab HPA configuration(s)' do
  def get_api_version(template, hpa_name)
    template.dig("HorizontalPodAutoscaler/#{hpa_name}", 'apiVersion')
  end

  let(:default_values) do
    HelmTemplate.defaults
  end

  let(:hpa_names) do
    %w[
      test-gitlab-shell
      test-gitlab-pages
      test-kas
      test-mailroom
      test-sidekiq-all-in-1-v2
      test-webservice-default
      test-spamcheck
      test-registry
    ]
  end

  let(:enable_all_hpas) do
    default_values.deep_merge(YAML.safe_load(%(
      global:
        appConfig:
          incomingEmail:
            enabled: true
            password:
              secret: foo
        kas:
          enabled: true
        pages:
          enabled: true
        spamcheck:
          enabled: true
      gitlab:
        gitlab-shell:
          hpa:
            cpu:
              targetType: AverageValue
              targetAverageValue: 100m
            behavior:
              scaleDown:
                stabilizationWindowSeconds: 300
        gitlab-pages:
          hpa:
            cpu:
              targetType: AverageValue
              targetAverageValue: 100m
            behavior:
              scaleDown:
                stabilizationWindowSeconds: 300
        kas:
          hpa:
            cpu:
              targetType: AverageValue
              targetAverageValue: 100m
            behavior:
              scaleDown:
                stabilizationWindowSeconds: 300
        mailroom:
          hpa:
            cpu:
              targetType: AverageValue
              targetAverageValue: 100m
            behavior:
              scaleDown:
                stabilizationWindowSeconds: 300
        sidekiq:
          hpa:
            cpu:
              targetType: AverageValue
              targetAverageValue: 100m
            behavior:
              scaleDown:
                stabilizationWindowSeconds: 300
        spamcheck:
          hpa:
            cpu:
              targetType: AverageValue
              targetAverageValue: 100m
            behavior:
              scaleDown:
                stabilizationWindowSeconds: 300
        webservice:
          hpa:
            cpu:
              targetType: AverageValue
              targetAverageValue: 100m
            behavior:
              scaleDown:
                stabilizationWindowSeconds: 300
      registry:
        enabled: true
        hpa:
          cpu:
            targetType: AverageValue
            targetAverageValue: 100m
          behavior:
            scaleDown:
              stabilizationWindowSeconds: 300
    )))
  end

  it 'All HPAs are tested' do
    template = HelmTemplate.new(enable_all_hpas)
    expect(template.exit_code).to eq(0)

    all_hpas = template.resources_by_kind("HorizontalPodAutoscaler").keys
    all_hpas.map! { |item| item.split('/')[1] }
    expect(all_hpas).to match_array(hpa_names)
  end

  describe 'api version' do
    let(:api_version_specified) do
      enable_all_hpas.deep_merge(YAML.safe_load(%(
        global:
          hpa:
            apiVersion: global/v0beta0
        gitlab:
          webservice:
            deployments:
              default:
                ingress:
                  path: /
                hpa:
                  apiVersion: local/v0beta0
      )))
    end

    context 'when not specified (without cluster connection)' do
      it 'sets default version (autoscaling/v2beta1)' do
        template = HelmTemplate.new(enable_all_hpas)
        expect(template.exit_code).to eq(0)

        hpa_names.each do |hpa_name|
          api_version = get_api_version(template, hpa_name)
          expect(api_version).to eq("autoscaling/v2beta1")
        end
      end
    end

    context 'when not specified (with cluster connection)' do
      it 'sets highest cluster-supported version' do
        api_versions_args = "--api-versions=autoscaling/v2beta1/HorizontalPodAutoscaler --api-versions=autoscaling/v2beta2/HorizontalPodAutoscaler --api-versions=autoscaling/v2/HorizontalPodAutoscaler"
        template = HelmTemplate.new(enable_all_hpas, 'test', api_versions_args)
        expect(template.exit_code).to eq(0)

        hpa_names.each do |hpa_name|
          api_version = get_api_version(template, hpa_name)
          expect(api_version).to eq('autoscaling/v2')
        end
      end
    end

    context 'when specified' do
      it 'sets proper API version' do
        template = HelmTemplate.new(api_version_specified)
        expect(template.exit_code).to eq(0)

        hpa_names.each do |hpa_name|
          api_version = get_api_version(template, hpa_name)

          if hpa_name.include? "webservice"
            expect(api_version).to eq("local/v0beta0")
          else
            expect(api_version).to eq("global/v0beta0")
          end
        end
      end
    end

    context 'when using HPA with autoscaling/v2beta1 API' do
      let(:api_version) do
        enable_all_hpas.deep_merge(YAML.safe_load(%(
            global:
              hpa:
                apiVersion: autoscaling/v2beta1
          )))
      end

      it 'does not set behavior configuration' do
        template = HelmTemplate.new(api_version)
        expect(template.exit_code).to eq(0)

        hpa_names.each do |hpa_name|
          behavior_config = template.dig("HorizontalPodAutoscaler/#{hpa_name}", 'spec', 'behavior')
          expect(behavior_config).to be_nil
        end
      end

      it 'sets autoscaling/v2beta1 style metric targets' do
        template = HelmTemplate.new(api_version)
        expect(template.exit_code).to eq(0)

        hpa_names.each do |hpa_name|
          cpu_resource_target = template.dig("HorizontalPodAutoscaler/#{hpa_name}", 'spec', 'metrics', 0, 'resource', 'targetAverageValue')
          expect(cpu_resource_target).to eq('100m')
        end
      end

      it 'does not set autoscaling/v2 style metric targets' do
        template = HelmTemplate.new(api_version)
        expect(template.exit_code).to eq(0)

        hpa_names.each do |hpa_name|
          cpu_resource_target = template.dig("HorizontalPodAutoscaler/#{hpa_name}", 'spec', 'metrics', 0, 'resource', 'target')
          expect(cpu_resource_target).to be_nil
        end
      end
    end

    %w[autoscaling/v2beta2 autoscaling/v2].each do |api_v2_version|
      context "when using HPA with #{api_v2_version} API" do
        let(:api_version) do
          enable_all_hpas.deep_merge(YAML.safe_load(%(
              global:
                hpa:
                  apiVersion: #{api_v2_version}
            )))
        end

        it 'sets behavior configuration' do
          template = HelmTemplate.new(api_version)
          expect(template.exit_code).to eq(0)

          hpa_names.each do |hpa_name|
            behavior_config = template.dig("HorizontalPodAutoscaler/#{hpa_name}", 'spec', 'behavior')
            expect(behavior_config).to eq({ "scaleDown" => { "stabilizationWindowSeconds" => 300 } })
          end
        end

        it 'does not set autoscaling/v2beta1 style metric targets' do
          template = HelmTemplate.new(api_version)
          expect(template.exit_code).to eq(0)

          hpa_names.each do |hpa_name|
            cpu_resource_target = template.dig("HorizontalPodAutoscaler/#{hpa_name}", 'spec', 'metrics', 0, 'resource', 'targetAverageValue')
            expect(cpu_resource_target).to be_nil
          end
        end

        it 'sets autoscaling/v2 style metric targets' do
          template = HelmTemplate.new(api_version)
          expect(template.exit_code).to eq(0)

          hpa_names.each do |hpa_name|
            cpu_resource_target = template.dig("HorizontalPodAutoscaler/#{hpa_name}", 'spec', 'metrics', 0, 'resource', 'target', 'averageValue')
            expect(cpu_resource_target).to eq('100m')
          end
        end
      end
    end
  end
end
