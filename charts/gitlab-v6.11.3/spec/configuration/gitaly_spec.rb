require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Gitaly configuration' do
  let(:default_values) do
    HelmTemplate.defaults
  end

  context 'When disabled and provided external instances' do
    let(:values) do
      YAML.safe_load(%(
        global:
          gitaly:
            enabled: false
            external:
            - name: default
              hostname: git.example.com
      )).deep_merge(default_values)
    end

    it 'populates external instances to gitlab.yml' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0)
      # check that gitlab.yml.erb contains production.repositories.storages
      gitlab_yml = t.dig('ConfigMap/test-webservice','data','gitlab.yml.erb')
      storages = YAML.load(gitlab_yml)['production']['repositories']['storages']
      expect(storages).to have_key('default')
      expect(storages['default']['gitaly_address']).to eq('tcp://git.example.com:8075')
    end

    context 'when external is configured with tlsEnabled' do
      let(:values) do
        YAML.safe_load(%(
          global:
            gitaly:
              enabled: false
              external:
              - name: default
                hostname: git.example.com
                tlsEnabled: true
        )).deep_merge(default_values)
      end

      it 'populates a tls uri' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        # check that gitlab.yml.erb contains production.repositories.storages
        gitlab_yml = t.dig('ConfigMap/test-webservice','data','gitlab.yml.erb')
        storages = YAML.load(gitlab_yml)['production']['repositories']['storages']
        expect(storages).to have_key('default')
        expect(storages['default']['gitaly_address']).to eq('tls://git.example.com:8076')
      end
    end

    context 'when tls is enabled' do
      let(:values) do
        YAML.safe_load(%(
          global:
            gitaly:
              enabled: false
              external:
              - name: default
                hostname: git.example.com
              tls:
                enabled: true
        )).deep_merge(default_values)
      end

      it 'populates a tls uri' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        # check that gitlab.yml.erb contains production.repositories.storages
        gitlab_yml = t.dig('ConfigMap/test-webservice','data','gitlab.yml.erb')
        storages = YAML.load(gitlab_yml)['production']['repositories']['storages']
        expect(storages).to have_key('default')
        expect(storages['default']['gitaly_address']).to eq('tls://git.example.com:8076')
      end
    end

    context 'when tls is enabled, and instance disables tls' do
      let(:values) do
        YAML.safe_load(%(
          global:
            gitaly:
              enabled: false
              external:
              - name: default
                hostname: git.example.com
                tlsEnabled: false
              tls:
                enabled: true
        )).deep_merge(default_values)
      end

      it 'populates a tcp uri' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        # check that gitlab.yml.erb contains production.repositories.storages
        gitlab_yml = t.dig('ConfigMap/test-webservice','data','gitlab.yml.erb')
        storages = YAML.load(gitlab_yml)['production']['repositories']['storages']
        expect(storages).to have_key('default')
        expect(storages['default']['gitaly_address']).to eq('tcp://git.example.com:8075')
      end
    end
  end

  context 'when rendering gitaly securityContexts' do
    context 'when the administrator changes or deletes values' do
      using RSpec::Parameterized::TableSyntax
      where(:fsGroup, :runAsUser, :fsGroupChangePolicy, :expectedContext) do
        nil | nil | "OnRootMismatch" | { 'fsGroup' => 1000, 'runAsUser' => 1000, 'fsGroupChangePolicy' => "OnRootMismatch" }
        nil | ""  | nil              | { 'fsGroup' => 1000 }
        nil | 24  | ""               | { 'fsGroup' => 1000, 'runAsUser' => 24 }
        42  | nil | "OnRootMismatch" | { 'fsGroup' => 42, 'runAsUser' => 1000, 'fsGroupChangePolicy' => "OnRootMismatch" }
        42  | ""  | nil              | { 'fsGroup' => 42 }
        42  | 24  | ""               | { 'fsGroup' => 42, 'runAsUser' => 24 }
        ""  | nil | "OnRootMismatch" | { 'runAsUser' => 1000 }
        ""  | ""  | nil              | nil
        ""  | 24  | ""               | { 'runAsUser' => 24 }
      end

      with_them do
        let(:values) do
          YAML.safe_load(%(
            gitlab:
              gitaly:
                securityContext:
                  #{"fsGroup: #{fsGroup}" unless fsGroup.nil?}
                  #{"fsGroupChangePolicy: #{fsGroupChangePolicy}" unless fsGroupChangePolicy.nil?}
                  #{"runAsUser: #{runAsUser}" unless runAsUser.nil?}
          )).deep_merge(default_values)
        end

        let(:gitaly_stateful_set) { 'StatefulSet/test-gitaly' }

        it 'should render securityContext correctly' do
          t = HelmTemplate.new(values)
          gitaly_set = t.resources_by_kind('StatefulSet').select { |key| key == gitaly_stateful_set }
          security_context = gitaly_set[gitaly_stateful_set]['spec']['template']['spec']['securityContext']

          # Helm 3.2+ renders the full security context. So we check given
          # the expected context from the table above and then check the
          # additional attributes that are not specified in the table above.
          full_context = { "runAsUser" => 1000, "fsGroup" => 1000 }
          expectedContext&.each_key do |expected_key|
            expect(security_context[expected_key]).to eq(expectedContext[expected_key])
            full_context.delete(expected_key)
          end

          full_context.each_key do |unexpected_key|
            expect(security_context[unexpected_key]).to eq(full_context[unexpected_key])
          end
        end
      end
    end
  end

  context 'With additional gitconfig' do
    let(:values) do
      YAML.safe_load(%(
        gitlab:
          gitaly:
            git:
              config:
              - {key: "pack.threads", value: "4"}
              - {key: "fetch.fsckObjects", value: "false"}
      )).deep_merge(default_values)
    end

    it 'populates [[git.config]] sections' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0)

      config = t.dig('ConfigMap/test-gitaly', 'data', 'config.toml.erb')
      expect(config).to include(
        <<~CONFIG
        [[git.config]]
        key = "pack.threads"
        value = "4"

        [[git.config]]
        key = "fetch.fsckObjects"
        value = "false"
        CONFIG
      )
    end
  end

  context 'When customer provides additional labels' do
    let(:labeled_values) do
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
          gitaly:
            common:
              labels:
                global: gitaly
                gitaly: gitaly
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

    context 'with only gitaly' do
      it 'Populates the additional labels in the expected manner' do
        t = HelmTemplate.new(labeled_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        expect(t.dig('ConfigMap/test-gitaly', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('StatefulSet/test-gitaly', 'metadata', 'labels')).to include('foo' => 'global')
        expect(t.dig('StatefulSet/test-gitaly', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('StatefulSet/test-gitaly', 'metadata', 'labels')).not_to include('global' => 'global')
        expect(t.dig('StatefulSet/test-gitaly', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
        expect(t.dig('StatefulSet/test-gitaly', 'spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
        expect(t.dig('StatefulSet/test-gitaly', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
        expect(t.dig('StatefulSet/test-gitaly', 'spec', 'volumeClaimTemplates', 0, 'metadata', 'labels')).not_to include('global' => 'gitaly')
        expect(t.dig('PodDisruptionBudget/test-gitaly', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('Service/test-gitaly', 'metadata', 'labels')).to include('global' => 'service')
        expect(t.dig('Service/test-gitaly', 'metadata', 'labels')).to include('gitaly' => 'gitaly')
        expect(t.dig('Service/test-gitaly', 'metadata', 'labels')).to include('global_service' => 'true')
        expect(t.dig('Service/test-gitaly', 'metadata', 'labels')).to include('service' => 'true')
        expect(t.dig('Service/test-gitaly', 'metadata', 'labels')).not_to include('global' => 'global')
        expect(t.dig('ServiceAccount/test-gitaly', 'metadata', 'labels')).to include('global' => 'gitaly')
      end
    end

    context 'with praefect enabled' do
      let(:praefect_labeled_values) do
        YAML.safe_load(%(
          global:
            praefect:
              enabled: true
              virtualStorages:
              - name: default
        )).deep_merge(default_values).deep_merge(labeled_values)
      end

      it 'Populates the additional labels in the expected manner' do
        t = HelmTemplate.new(praefect_labeled_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        expect(t.dig('ConfigMap/test-gitaly-praefect', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('StatefulSet/test-gitaly-default', 'metadata', 'labels')).to include('foo' => 'global')
        expect(t.dig('StatefulSet/test-gitaly-default', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('StatefulSet/test-gitaly-default', 'metadata', 'labels')).not_to include('global' => 'global')
        expect(t.dig('StatefulSet/test-gitaly-default', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
        expect(t.dig('StatefulSet/test-gitaly-default', 'spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
        expect(t.dig('StatefulSet/test-gitaly-default', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
        expect(t.dig('StatefulSet/test-gitaly-default', 'spec', 'volumeClaimTemplates', 0, 'metadata', 'labels')).to include('storage' => 'default')
        expect(t.dig('StatefulSet/test-gitaly-default', 'spec', 'volumeClaimTemplates', 0, 'metadata', 'labels')).not_to include('global' => 'gitaly')
        expect(t.dig('PodDisruptionBudget/test-gitaly-default', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('Service/test-gitaly-default', 'metadata', 'labels')).to include('gitaly' => 'gitaly')
        expect(t.dig('Service/test-gitaly-default', 'metadata', 'labels')).to include('global' => 'service')
        expect(t.dig('Service/test-gitaly-default', 'metadata', 'labels')).to include('global_service' => 'true')
        expect(t.dig('Service/test-gitaly-default', 'metadata', 'labels')).to include('service' => 'true')
        expect(t.dig('Service/test-gitaly-default', 'metadata', 'labels')).not_to include('global' => 'global')
        expect(t.dig('ServiceAccount/test-gitaly', 'metadata', 'labels')).to include('global' => 'gitaly')
      end
    end
  end

  context 'packObjectsCache' do
    let(:values) do
      YAML.safe_load(%(
        gitlab:
          gitaly:
            packObjectsCache:
              enabled: #{pack_objects_cache_enabled}
              dir: #{pack_objects_cache_dir}
              max_age: #{pack_objects_cache_max_age}
      )).merge(default_values)
    end

    context 'when enabled' do
      let(:pack_objects_cache_enabled) { 'true' }
      let(:pack_objects_cache_dir) { '/pack-objects-cache' }
      let(:pack_objects_cache_max_age) { '10m' }

      let(:template) { HelmTemplate.new(values) }

      it 'populates a pack_objects_cache section in config.toml.erb' do
        config_toml = template.dig('ConfigMap/test-gitaly','data','config.toml.erb')

        pack_objects_cache_section = "[pack_objects_cache]\n" \
                                     "enabled = #{pack_objects_cache_enabled}\n" \
                                     "dir = \"#{pack_objects_cache_dir}\"\n" \
                                     "max_age = #{pack_objects_cache_max_age}"

        expect(config_toml).to include(pack_objects_cache_section)
      end
    end

    context 'when not enabled' do
      let(:pack_objects_cache_enabled) { 'false' }
      let(:pack_objects_cache_dir) { '/pack-objects-cache' }
      let(:pack_objects_cache_max_age) { '10m' }

      let(:template) { HelmTemplate.new(values) }

      it 'does not populate a pack_objects_cache section in config.toml.erb' do
        config_toml = template.dig('ConfigMap/test-gitaly','data','config.toml.erb')

        expect(config_toml).not_to match /^\[pack_objects_cache\]/
      end
    end
  end

  context 'gpg signing' do
    let(:values) do
      HelmTemplate.with_defaults %(
        gitlab:
          gitaly:
            gpgSigning:
              enabled: #{gpg_signing_enabled}
              secret: #{gpg_secret_name}
              key: #{gpg_secret_key}
      )
    end

    context 'when enabled' do
      let(:gpg_signing_enabled) { true }
      let(:gpg_secret_name) { 'gpgSecret' }
      let(:gpg_secret_key) { 'gpgisfun' }

      let(:template) { HelmTemplate.new(values) }

      it 'populates a signing_key field in config.toml.erb' do
        config_toml = template.dig('ConfigMap/test-gitaly','data','config.toml.erb')

        expect(config_toml).to include "signing_key = '/etc/gitlab-secrets/gitaly/signing_key.gpg'"
      end
    end

    context 'when disabled' do
      let(:gpg_signing_enabled) { false }
      let(:gpg_secret_name) { 'dont use me' }
      let(:gpg_secret_key) { 'gpgisunfun' }

      let(:template) { HelmTemplate.new(values) }

      it 'does not populate a signing_key field in config.toml.erb' do
        config_toml = template.dig('ConfigMap/test-gitaly','data','config.toml.erb')

        expect(config_toml).not_to match /^signing_key = /
      end
    end
  end

  context 'with extraVolumes' do
    let(:values) do
      YAML.safe_load(%(
        gitlab:
          gitaly:
            extraVolumes: |-
             - name: #{volume_name}
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    shared_examples 'a deprecated gitconfig volume' do
      it 'fails due to gitconfig deprecation' do
        expect(template.exit_code).not_to eq(0)
        expect(template.stderr).to include("Gitaly have stopped reading `gitconfig`")
      end
    end

    context 'with gitconfig volume' do
      let(:volume_name) { "gitconfig" }

      it_behaves_like 'a deprecated gitconfig volume'
    end

    context 'with git-config volume' do
      let(:volume_name) { "git-config" }

      it_behaves_like 'a deprecated gitconfig volume'
    end

    context 'with gitaly-gitconfig volume' do
      let(:volume_name) { "gitaly-gitconfig" }

      it_behaves_like 'a deprecated gitconfig volume'
    end

    context 'with gitaly-config volume' do
      let(:volume_name) { "gitaly-config" }

      it 'successfully renders the template' do
        expect(template.exit_code).to eq(0)
        expect(template.stderr).not_to include("Gitaly have stopped reading `gitconfig`")
      end
    end
  end
end
