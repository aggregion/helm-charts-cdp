require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'ObjectStorage configuration' do
  let(:services) do
    [
      'sidekiq',
      'webservice',
      'toolbox'
    ]
  end

  let(:init_secret_mounts) do
    {
      'test-sidekiq-all-in-1-v2' => 'init-sidekiq-secrets',
      'test-webservice-default' => 'init-webservice-secrets',
      'test-toolbox' => 'init-toolbox-secrets'
    }
  end

  let(:default_values) do
    HelmTemplate.defaults
  end

  let(:artifacts_cdn_file) { '/etc/gitlab/objectstorage/cdn/artifacts' }

  describe 'global.appConfig.object_store.enabled' do
    let(:object_store_config_file) { '/etc/gitlab/objectstorage/object_store' }

    let(:values_object_store_connection) do
      YAML.safe_load(%(
        global:
          appConfig:
            object_store:
              enabled: true
              connection:
                secret: gitlab-object-storage
                key: connection
            artifacts:
              bucket: artifacts-bucket
              cdn:
                secret: gitlab-cdn-storage
                key: cdn
            lfs:
              bucket: lfs-bucket
      )).deep_merge(default_values)
    end

    context 'with CDN and connection configuration provided' do
      it 'populates CDN configuration' do
        t = HelmTemplate.new(values_object_store_connection)
        expect(t.exit_code).to eq(0)

        services.each do |cm|
          raw_config = t.dig("ConfigMap/test-#{cm}", 'data', 'gitlab.yml.erb')
          config = YAML.safe_load(raw_config)
          object_store_config = config.dig('production', 'object_store')

          expect(object_store_config['enabled']).to be true

          expect(object_store_config['connection']).to include(object_store_config_file)
          expect(object_store_config.dig('objects', 'artifacts', 'bucket')).to eq('artifacts-bucket')
          expect(object_store_config.dig('objects', 'lfs', 'bucket')).to eq('lfs-bucket')
          expect(object_store_config.dig('objects', 'artifacts', 'cdn')).to include(artifacts_cdn_file)

          expect(config.dig('production', 'artifacts')).to eq({ 'enabled' => true })
          expect(config.dig('production', 'lfs')).to eq({ 'enabled' => true })
        end

        init_secret_mounts.each do |deployment, mount|
          secret_names = t.projected_volume_sources("Deployment/#{deployment}", mount).map do |item|
            item['secret']['name']
          end

          expect(secret_names).to include('gitlab-object-storage', 'gitlab-cdn-storage')
        end
      end
    end
  end

  describe 'global.appConfig.artifacts.enabled' do
    let(:artifacts_config_file) { '/etc/gitlab/objectstorage/artifacts' }

    let(:values_artifacts_enabled) do
      YAML.safe_load(%(
        global:
          appConfig:
            artifacts:
              enabled: true
      )).deep_merge(default_values)
    end

    let(:values_artifacts_connection) do
      YAML.safe_load(%(
        global:
          appConfig:
            artifacts:
              connection:
                secret: gitlab-object-storage
                key: connection
      )).deep_merge(default_values)
    end

    let(:values_artifacts_cdn) do
      YAML.safe_load(%(
        global:
          appConfig:
            artifacts:
              cdn:
                secret: gitlab-cdn-storage
                key: test-cdn
      )).deep_merge(values_artifacts_enabled)
        .deep_merge(values_artifacts_connection)
    end

    context 'when true' do
      it 'does not populate connection block' do
        t = HelmTemplate.new(values_artifacts_enabled)
        expect(t.exit_code).to eq(0)
        services.each do |cm|
          expect(t.dig("ConfigMap/test-#{cm}", 'data', 'gitlab.yml.erb')).not_to include(artifacts_config_file)
        end
      end

      context 'with connection configuration provided' do
        it 'populates connection block' do
          t = HelmTemplate.new(values_artifacts_enabled.deep_merge(values_artifacts_connection))
          expect(t.exit_code).to eq(0)
          services.each do |cm|
            expect(t.dig("ConfigMap/test-#{cm}", 'data', 'gitlab.yml.erb')).to include(artifacts_config_file)
          end
        end
      end

      context 'with CDN provided' do
        it 'populates CDN configuration' do
          t = HelmTemplate.new(values_artifacts_cdn)
          expect(t.exit_code).to eq(0)

          services.each do |cm|
            raw_config = t.dig("ConfigMap/test-#{cm}", 'data', 'gitlab.yml.erb')
            config = YAML.safe_load(raw_config)

            artifacts_config = config.dig('production', 'artifacts')

            expect(artifacts_config['enabled']).to be true
            expect(artifacts_config.dig('object_store', 'enabled')).to be true
            expect(artifacts_config.dig('object_store', 'remote_directory')).to eq('gitlab-artifacts')
            expect(artifacts_config.dig('object_store', 'connection')).to include(artifacts_config_file)
            expect(artifacts_config.dig('object_store', 'cdn')).to include(artifacts_cdn_file)
          end

          # Check the secret mounts
          init_secret_mounts.each do |deployment, mount|
            secret_names = t.projected_volume_sources("Deployment/#{deployment}", mount).map do |item|
              item['secret']['name']
            end

            expect(secret_names).to include('gitlab-object-storage', 'gitlab-cdn-storage')
          end
        end
      end
    end
  end

  describe 'global.appConfig.dependencyProxy.enabled' do
    let(:objectstorage_config_file) { '/etc/gitlab/objectstorage/dependency_proxy' }

    let(:values_dependencyProxy_connection) do
      YAML.safe_load(%(
        global:
          appConfig:
            dependencyProxy:
              connection:
                secret: gitlab-object-storage
                key: connection
      )).deep_merge(default_values)
    end

    let(:values_dependencyProxy_enabled) do
      YAML.safe_load(%(
        global:
          appConfig:
            dependencyProxy:
              enabled: true
      )).deep_merge(default_values)
    end

    context 'when true' do
      it 'does not populate connection block' do
        t = HelmTemplate.new(values_dependencyProxy_enabled)
        expect(t.exit_code).to eq(0)
        services.each do |cm|
          expect(t.dig("ConfigMap/test-#{cm}", 'data', 'gitlab.yml.erb')).not_to include(objectstorage_config_file)
        end
      end

      context 'with connection configuration provided' do
        it 'populates connection block' do
          t = HelmTemplate.new(values_dependencyProxy_enabled.deep_merge(values_dependencyProxy_connection))
          expect(t.exit_code).to eq(0)
          services.each do |cm|
            expect(t.dig("ConfigMap/test-#{cm}", 'data', 'gitlab.yml.erb')).to include(objectstorage_config_file)
          end
        end
      end
    end

    context 'when false' do
      it 'does not populate connection block' do
        t = HelmTemplate.new(default_values)
        expect(t.exit_code).to eq(0)
        services.each do |cm|
          expect(t.dig("ConfigMap/test-#{cm}", 'data', 'gitlab.yml.erb')).not_to include(objectstorage_config_file)
        end
      end

      context 'with connection configuration provided' do
        it 'does not populate connection block' do
          t = HelmTemplate.new(values_dependencyProxy_connection)
          expect(t.exit_code).to eq(0)
          services.each do |cm|
            expect(t.dig("ConfigMap/test-#{cm}", 'data', 'gitlab.yml.erb')).not_to include(objectstorage_config_file)
          end
        end
      end
    end
  end
end
