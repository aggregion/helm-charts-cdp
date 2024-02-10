require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'global configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global: {}
    ))
  end

  context 'required settings' do
    it 'successfully creates a helm release' do
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
    end
  end

  context 'default settings' do
    it 'fails to create a helm release' do
      t = HelmTemplate.new({})
      expect(t.exit_code).to eq(256), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
    end
  end

  describe 'registry and geo sync enabled' do
    let(:registry_notifications) do
      YAML.safe_load(%(
        global:
          geo:
            enabled: true
            role: primary
            registry:
              replication:
                enabled: true
                primaryApiUrl: 'http://registry.foobar.com'
          postgresql:
            install: false
          psql:
            host: geo-1.db.example.com
            port: 5432
            password:
              secret: geo
              key: postgresql-password
      )).deep_merge(default_values)
    end

    it 'configures the notification endpoint' do
      t = HelmTemplate.new(registry_notifications)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      expect(t.find_projected_secret('Deployment/test-sidekiq-all-in-1-v2', 'init-sidekiq-secrets', 'test-registry-notification')).to be true
      expect(t.find_projected_secret('Deployment/test-webservice-default', 'init-webservice-secrets', 'test-registry-notification')).to be true
      expect(t.find_projected_secret('Deployment/test-toolbox', 'init-toolbox-secrets', 'test-registry-notification')).to be true
      gitlab_config = t.dig('ConfigMap/test-sidekiq', 'data', 'gitlab.yml.erb')
      expect(gitlab_config).to include('notification_secret')

      config = t.dig('ConfigMap/test-registry', 'data', 'config.yml')
      config_yaml = YAML.safe_load(config, permitted_classes: [Symbol])

      # With geo enabled && syncing of the registry enabled, we insert this notifier
      expect(config_yaml['notifications']['endpoints'].count { |item| item['name'] == 'geo_event' }).to eq(1)
    end
  end

  describe 'registry and geo sync enabled with other notifiers' do
    let(:registry_notifications) do
      YAML.safe_load(%(
        global:
          geo:
            enabled: true
            role: primary
            registry:
              replication:
                enabled: true
                primaryApiUrl: 'http://registry.foobar.com'
          postgresql:
            install: false
          psql:
            host: geo-1.db.example.com
            port: 5432
            password:
              secret: geo
              key: postgresql-password
          registry:
            notifications:
              endpoints:
                - name: FooListener
                  url: https://foolistener.com/event
                  timeout: 500ms
                  threshold: 10
                  ackoff: 1s
                  headers:
                    FooBar: ['1', '2']
                    Authorization:
                      secret: gitlab-registry-authorization-header
                    SpecificPassword:
                      secret: gitlab-registry-specific-password
                      key: password
      )).deep_merge(default_values)
    end

    it 'all notifications are included' do
      t = HelmTemplate.new(registry_notifications)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

      # The below is ugly, both code wise, as well as informing the user testing WHAT is wrong...
      config = t.dig('ConfigMap/test-registry', 'data', 'config.yml')
      config_yaml = YAML.safe_load(config, permitted_classes: [Symbol])

      # Testing that we don't accidentally blow away a customization
      expect(config_yaml['notifications']['endpoints'].count { |item| item['name'] == 'FooListener' }).to eq(1)

      # With geo enabled && syncing of the registry enabled, we insert this notifier
      expect(config_yaml['notifications']['endpoints'].count { |item| item['name'] == 'geo_event' }).to eq(1)
    end
  end

  describe 'global.shell.port: SSH is to be use on an alternate port' do
    let(:shell_values) do
      YAML.safe_load(%(
        global:
          shell:
            port: 9999
      )).deep_merge(default_values)
    end

    # We need to look for any ConfigMap that has `gitlab.yml.erb` and ensure it contains the necessary strings
    it 'configures all appropriate gitlab.yml entries' do
      t = HelmTemplate.new(shell_values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

      # We need to look at any configmap that has `gitlab.yml.erb`
      configmaps = t.resources_by_kind('ConfigMap').filter { |cm, content| content['data'].has_key? 'gitlab.yml.erb' }
      # We can ignore `migrations`, as this does not handle API responses for URLs of any kind.
      configmaps = configmaps.reject! { |cm, content| cm.eql? 'ConfigMap/test-migrations' }
      configmaps.each do |cm, content|
        expect(content['data']['gitlab.yml.erb']).to include("ssh_port: 9999"), "Expected #{cm}'s 'gitlab.yml.erb' to contain 'ssh_port: 9999'"
      end
    end
  end

  describe 'global.image.tagSuffix: add a string to the end of all image tags' do
    let(:shell_values) do
      YAML.safe_load(%(
        certmanager:
          install: false
        global:
          image:
            tagSuffix: -fips
          busybox:
            image:
              tag: fixed-version
          certificates:
            image:
              tag: fixed-version
          kubectl:
            image:
              tag: fixed-version
          praefect:
            enabled: true
          spamcheck:
            enabled: true
          pages:
            enabled: true
          ingress:
            configureCertmanager: false
        nginx-ingress:
          controller:
            kind: Both
            image:
              tag: fixed-version
      )).deep_merge(default_values)
    end

    let(:ignored_deployments) do
      [
        'Deployment/test-gitlab-runner',
        'Deployment/test-prometheus-server',
        'Deployment/test-minio'
      ]
    end

    let(:ignored_initContainers) do
      [
        'certificates',
        'configure'
      ]
    end

    let(:ignored_statefulsets) do
      [
        'StatefulSet/test-postgresql',
        'StatefulSet/test-redis-master'
      ]
    end

    let(:ignored_jobs) do
      [
        'Job/test-minio-create-buckets-1',
        'Job/test-shared-secrets-1',
        'Job/test-gitlab-upgrade-check'
      ]
    end

    it 'adds the provided suffix to all image tags' do
      t = HelmTemplate.new(shell_values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

      objects = t.resources_by_kind('Deployment').reject { |key, _| ignored_deployments.include? key }
      objects.merge! t.resources_by_kind('StatefulSet').reject { |key, _| ignored_statefulsets.include? key }
      # shared secrets jobs come out as test-shared-secrets-1-xxx, need to .match those
      objects.merge! t.resources_by_kind('Job').reject { |key, _| ignored_jobs.any? { |ij| key.match(ij) } }
      objects.merge! t.resources_by_kind('DaemonSet')

      objects.each do |o, content|
        content['spec']['template']['spec']['containers'].each do |c|
          # we are currently only using sha256 digests, but this match
          # will need to be more flexible in the future
          expect(c['image']).to match('-fips(@sha256:[a-fA-F0-9]{64})?$'), "Expected #{o}'s 'containers' image tags to have suffix '-fips'. Container is #{c}"
          expect(c['image']).not_to end_with("-fips-fips"), "Unexpected double suffix in #{o}'s 'container' images."
        end

        next unless content['spec']['template']['spec'].key?('initContainers')

        content['spec']['template']['spec']['initContainers'].each do |ic|
          next if ignored_initContainers.include? ic['name']

          # we are currently only using sha256 digests, but this match
          # will need to be more flexible in the future
          expect(ic['image']).to match('-fips\b(@sha256:[a-fA-F0-9]{64})?$'), "Expected #{o}'s 'initContainers' image tags to have suffix '-fips'. initContainer is #{ic}"
          expect(ic['image'].strip).not_to end_with("-fips-fips"), "Unexpected double suffix in #{o}'s 'initContainer' images."
        end
      end
    end
  end
end
