require 'spec_helper'
require 'fileutils'
require 'helm_template_helper'
require 'tomlrb'
require 'yaml'
require 'hash_deep_merge'

describe 'Workhorse configuration' do
  let(:default_values) do
    HelmTemplate.defaults
  end
  let(:template) { HelmTemplate.new(default_values) }
  let(:raw_toml) { template.dig('ConfigMap/test-workhorse-default', 'data', 'workhorse-config.toml.tpl') }

  def render_toml(raw_template, object_store_config = nil)
    Dir.mktmpdir do |tmpdir|
      raw_template.gsub!(%r{/etc/gitlab}, tmpdir)
      input_file = File.join(tmpdir, 'input.tpl')
      File.write(input_file, raw_template)

      directories = %w[redis objectstorage]
      directories.each { |dir| FileUtils.mkdir(File.join(tmpdir, dir)) }
      # Write bogus redis password
      File.write(File.join(tmpdir, "redis", "redis-password"), SecureRandom.hex)
      File.write(File.join(tmpdir, "objectstorage", "object_store"), object_store_config) if object_store_config

      cmd = "gomplate --left-delim '{%' --right-delim '%}' --file #{input_file}"
      result = Open3.capture3(cmd)
      stdout, stderr, exit_code = result

      raise "Unable to call gomplate: #{stderr}" if exit_code != 0

      Tomlrb.parse(stdout)
    end
  end

  it 'renders a TOML configuration file' do
    toml = render_toml(raw_toml)

    expect(toml.keys).to match_array(%w[shutdown_timeout listeners image_resizer redis])
    expect(toml['shutdown_timeout']).to eq('61s')
  end

  it 'disabled archive cache' do
    expect(template.exit_code).to eq(0)
    # check the deployment of webservice for the WORKHORSE_ARCHVE_CACHE_DISABLED
    # env var. This is set on webserver and workhorse retrives the setting
    # from internal API. Also note that the value is irrevelent as the rails
    # code only checks for the existance of the variable not the value.
    containers = template.dig('Deployment/test-webservice-default', 'spec', 'template', 'spec', 'containers')
    found = false
    containers.each do |c|
      if c['name'] == 'webservice'
        vars = c['env'].map {|entry| entry['name']}
        if vars.include? 'WORKHORSE_ARCHIVE_CACHE_DISABLED'
          found = true
        end
      end
    end
    expect(found).to eq(true)
  end

  context 'with trusted CIDRs' do
    let(:custom_values) do
      HelmTemplate.with_defaults(%(
        gitlab:
          webservice:
            workhorse:
              shutdownTimeout: "30s"
              trustedCIDRsForPropagation: ["127.0.0.1/32", "192.168.0.1/32"]
              trustedCIDRsForXForwardedFor: ["1.2.3.4/32", "5.6.7.8/32"]
     ))
    end

    let(:template) { HelmTemplate.new(custom_values) }

    it 'renders a TOML configuration file' do
      toml = render_toml(raw_toml)

      expect(toml.keys).to match_array(%w[shutdown_timeout listeners image_resizer redis trusted_cidrs_for_propagation trusted_cidrs_for_x_forwarded_for])
      expect(toml['shutdown_timeout']).to eq('30s')
      expect(toml['trusted_cidrs_for_propagation']).to eq(["127.0.0.1/32", "192.168.0.1/32"])
      expect(toml['trusted_cidrs_for_x_forwarded_for']).to eq(["1.2.3.4/32", "5.6.7.8/32"])
    end
  end

  describe 'object storage configuration' do
    context 'with S3 configured' do
      let(:s3_config) { File.read('examples/objectstorage/rails.s3.yaml') }

      it 'renders a TOML configuration file' do
        toml = render_toml(raw_toml, s3_config)

        expect(toml.keys).to match_array(%w[shutdown_timeout listeners object_storage image_resizer redis])

        object_storage = toml['object_storage']
        expect(object_storage.keys).to match_array(%w[provider s3])
        expect(object_storage['s3'].keys).to match_array(%w[aws_access_key_id aws_secret_access_key])
        expect(object_storage['s3']['aws_access_key_id']).to eq('BOGUS_ACCESS_KEY')
        expect(object_storage['s3']['aws_secret_access_key']).to eq('BOGUS_SECRET_KEY')
      end
    end

    context 'with AzureRM configured' do
      let(:s3_config) { File.read('examples/objectstorage/rails.azurerm.yaml') }

      it 'renders a TOML configuration file' do
        toml = render_toml(raw_toml, s3_config)

        expect(toml.keys).to match_array(%w[shutdown_timeout listeners object_storage image_resizer redis])

        object_storage = toml['object_storage']
        expect(object_storage.keys).to match_array(%w[provider azurerm])
        expect(object_storage['azurerm'].keys).to match_array(%w[azure_storage_account_name azure_storage_access_key])
        expect(object_storage['azurerm']['azure_storage_account_name']).to eq('YOUR_AZURE_STORAGE_ACCOUNT_NAME')
        expect(object_storage['azurerm']['azure_storage_access_key']).to eq('YOUR_AZURE_STORAGE_ACCOUNT_KEY')
      end
    end

    context 'with GCS configured' do
      let(:s3_config) { File.read('examples/objectstorage/rails.gcs.yaml') }

      it 'renders a TOML configuration file' do
        toml = render_toml(raw_toml, s3_config)
        yaml = YAML.safe_load(s3_config)

        expect(toml.keys).to match_array(%w[shutdown_timeout listeners object_storage image_resizer redis])

        object_storage = toml['object_storage']
        expect(object_storage.keys).to match_array(%w[provider google])
        expect(object_storage['google'].keys).to match_array(%w[google_project google_json_key_string])
        expect(object_storage['google']['google_project']).to eq(yaml['google_project'])
        # here, we `rstrip` the YAML string, because it has an extra `\n` on the end as opposed to the rendered TOML
        expect(object_storage['google']['google_json_key_string']).to eq(yaml['google_json_key_string'].rstrip)
      end
    end
  end

  context 'TLS support' do
    let(:tls_enabled) { false }
    let(:tls_verify) {}
    let(:monitoring_enabled) { true }
    let(:monitoring_tls_enabled) { false }
    let(:tls_secret_name) {}
    let(:tls_ca_secret_name) {}
    let(:tls_custom_ca) {}

    let(:tls_values) do
      HelmTemplate.with_defaults(%(
        global:
          certificates:
            customCAs: [#{tls_custom_ca}]
          workhorse:
            tls:
              enabled: #{tls_enabled}
        gitlab:
          webservice:
            workhorse:
              monitoring:
                exporter:
                  enabled: #{monitoring_enabled}
                  tls:
                    enabled: #{monitoring_tls_enabled}
              tls:
                verify: #{tls_verify}
                secretName: #{tls_secret_name}
                caSecretName: #{tls_ca_secret_name}
      ))
    end

    context 'when TLS is disabled' do
      let(:template) { HelmTemplate.new(tls_values) }

      it 'renders a TOML configuration file' do
        expect(raw_toml).to include %([[listeners]]\n)
        expect(raw_toml).to include %(addr = "0.0.0.0:8181"\n)
        expect(raw_toml).not_to include %([listeners.tls]\n)
        expect(raw_toml).to include %([metrics_listener]\n)
        expect(raw_toml).to include %(addr = "0.0.0.0:9229"\n)
        expect(raw_toml).not_to include %([metrics_listener.tls]\n)
      end
    end

    context 'when TLS is enabled and verified' do
      let(:tls_enabled) { true }
      let(:tls_verify) { true }
      let(:tls_secret_name) { 'webservice-tls-secret' }
      let(:tls_ca_secret_name) { 'custom-ca-secret' }
      let(:tls_custom_ca) { 'secret: custom-ca-secret' }
      let(:monitoring_tls_enabled) { true }

      let(:template) { HelmTemplate.new(tls_values) }

      it 'uses specified secret in the volumes' do
        webservice_secret_volumes = template
          .dig('Deployment/test-webservice-default', 'spec', 'template', 'spec', 'volumes')
          .collect { |v| v.dig('projected', 'sources')&.collect { |p| p.dig('secret', 'name') } }.compact.flatten

        expect(webservice_secret_volumes).to include('webservice-tls-secret')
        expect(webservice_secret_volumes).to include('custom-ca-secret')
      end

      it 'renders a TOML configuration file' do
        expect(raw_toml).to include %([[listeners]]\n)
        expect(raw_toml).to include %(addr = "0.0.0.0:8181"\n)
        expect(raw_toml).to include %([listeners.tls]\n)
        expect(raw_toml).to include %([metrics_listener]\n)
        expect(raw_toml).to include %(addr = "0.0.0.0:9229"\n)
        expect(raw_toml).to include %([metrics_listener.tls]\n)
      end

      it 'annotates Ingress for TLS backend' do
        ingress_annotations = template.dig('Ingress/test-webservice-default', 'metadata', 'annotations')

        expect(ingress_annotations).to include('nginx.ingress.kubernetes.io/backend-protocol' => 'https')
        expect(ingress_annotations).to include('nginx.ingress.kubernetes.io/proxy-ssl-verify' => 'on')
        expect(ingress_annotations).to include('nginx.ingress.kubernetes.io/proxy-ssl-secret' => 'default/custom-ca-secret')
      end
    end

    context 'when TLS is enabled but not verified' do
      let(:tls_enabled) { true }
      let(:tls_verify) { false }
      let(:tls_secret_name) { 'webservice-tls-secret' }
      let(:tls_ca_secret_name) { 'custom-ca-secret' }
      let(:tls_custom_ca) { 'secret: custom-ca-secret' }
      let(:monitoring_enabled) { false }

      let(:template) { HelmTemplate.new(tls_values) }

      it 'renders a TOML configuration file' do
        toml = render_toml(raw_toml)

        expect(toml.keys).to match_array(%w[shutdown_timeout listeners image_resizer redis])

        listeners = toml['listeners']
        expect(listeners.count).to eq(1)
        expect(listeners.first.keys).to match_array(%w[network addr tls])
        expect(listeners.first['addr']).to eq('0.0.0.0:8181')
      end

      it 'annotates Ingress for TLS backend' do
        ingress_annotations = template.dig('Ingress/test-webservice-default', 'metadata', 'annotations')

        expect(ingress_annotations).to include('nginx.ingress.kubernetes.io/backend-protocol' => 'https')
        expect(ingress_annotations).not_to include('nginx.ingress.kubernetes.io/proxy-ssl-verify')
      end
    end
  end
end
