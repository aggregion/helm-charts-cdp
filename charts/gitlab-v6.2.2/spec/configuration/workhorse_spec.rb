require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Workhorse configuration' do
  let(:default_values) do
    YAML.safe_load(%(
      certmanager-issuer:
        email: test@example.com
    ))
  end
  let(:template) { HelmTemplate.new(default_values) }

  it 'renders a TOML configuration file' do
    raw_toml = template.dig('ConfigMap/test-workhorse-default', 'data', 'workhorse-config.toml.tpl')

    expect(raw_toml).to match /^shutdown_timeout = "61s"/
    expect(raw_toml).not_to include('trusted_cidrs_for_propagation')
    expect(raw_toml).not_to include('trusted_cidrs_for_x_forwarded_for')
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

  context 'with custom values' do
    let(:custom_values) do
      YAML.safe_load(%(
        gitlab:
          webservice:
            workhorse:
              shutdownTimeout: "30s"
              trustedCIDRsForPropagation: ["127.0.0.1/32", "192.168.0.1/32"]
              trustedCIDRsForXForwardedFor: ["1.2.3.4/32", "5.6.7.8/32"]
        certmanager-issuer:
          email: test@example.com
     ))
    end

    let(:template) { HelmTemplate.new(custom_values) }

    it 'renders a TOML configuration file' do
      raw_toml = template.dig('ConfigMap/test-workhorse-default', 'data', 'workhorse-config.toml.tpl')

      expect(raw_toml).to match /^shutdown_timeout = "30s"/
      expect(raw_toml).to include(%(trusted_cidrs_for_propagation = ["127.0.0.1/32","192.168.0.1/32"]\n))
      expect(raw_toml).to include(%(trusted_cidrs_for_x_forwarded_for = ["1.2.3.4/32","5.6.7.8/32"]\n))
    end
  end

  context 'TLS support' do
    let(:tls_values) do
      YAML.safe_load(%(
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
        certmanager-issuer:
          email: test@example.com
      ))
    end

    context 'when TLS is disabled' do
      let(:tls_enabled) {}
      let(:tls_verify) {}
      let(:tls_secret_name) {}
      let(:tls_ca_secret_name) {}
      let(:tls_custom_ca) {}
      let(:monitoring_enabled) { true }
      let(:monitoring_tls_enabled) {}

      let(:template) { HelmTemplate.new(tls_values) }

      it 'renders a TOML configuration file' do
        raw_toml = template.dig('ConfigMap/test-workhorse-default', 'data', 'workhorse-config.toml.tpl')

        expect(raw_toml).to include %([[listeners]]\n)
        expect(raw_toml).to include %(addr = "0.0.0.0:8181"\n)
        expect(raw_toml).not_to include %([listeners.tls]\n)
        expect(raw_toml).to include %([metrics_listener]\n)
        expect(raw_toml).to include %(addr = "0.0.0.0:9229"\n)
        expect(raw_toml).not_to include %([metrics_listener.tls]\n)
      end
    end

    context 'when TLS is enabled but custom CA and TLS Secrets are not specified' do
      let(:tls_enabled) { true }
      let(:tls_verify) {}
      let(:tls_secret_name) {}
      let(:tls_ca_secret_name) {}
      let(:tls_custom_ca) {}
      let(:monitoring_enabled) {}
      let(:monitoring_tls_enabled) {}

      let(:template) { HelmTemplate.new(tls_values) }

      it 'fails when checking the configuration' do
        expect(template.exit_code).not_to eq(0)
        expect(template.stderr).to include('global.certificates.customCAs')
      end
    end

    context 'when TLS is enabled and verified' do
      let(:tls_enabled) { true }
      let(:tls_verify) { true }
      let(:tls_secret_name) { 'webservice-tls-secret' }
      let(:tls_ca_secret_name) { 'custom-ca-secret' }
      let(:tls_custom_ca) { 'secret: custom-ca-secret' }
      let(:monitoring_enabled) { true }
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
        raw_toml = template.dig('ConfigMap/test-workhorse-default', 'data', 'workhorse-config.toml.tpl')

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
      let(:monitoring_enabled) {}
      let(:monitoring_tls_enabled) {}

      let(:template) { HelmTemplate.new(tls_values) }

      it 'renders a TOML configuration file' do
        raw_toml = template.dig('ConfigMap/test-workhorse-default', 'data', 'workhorse-config.toml.tpl')

        expect(raw_toml).to include %([[listeners]]\n)
        expect(raw_toml).to include %(addr = "0.0.0.0:8181"\n)
        expect(raw_toml).to include %([listeners.tls]\n)
        expect(raw_toml).not_to include %([metrics_listener]\n)
        expect(raw_toml).not_to include %(addr = "0.0.0.0:9229"\n)
        expect(raw_toml).not_to include %([metrics_listener.tls]\n)
      end

      it 'annotates Ingress for TLS backend' do
        ingress_annotations = template.dig('Ingress/test-webservice-default', 'metadata', 'annotations')

        expect(ingress_annotations).to include('nginx.ingress.kubernetes.io/backend-protocol' => 'https')
        expect(ingress_annotations).not_to include('nginx.ingress.kubernetes.io/proxy-ssl-verify')
      end
    end
  end
end
