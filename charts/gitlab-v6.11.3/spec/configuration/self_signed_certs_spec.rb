require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Self-Signed Certificates configuration' do
  context 'when CertManager is disabled' do
    let(:values_all_enabled) do
      YAML.safe_load(%(
        global:
          kas:
            enabled: true
          appConfig:
            smartcard:
              enabled: true
          pages:
            enabled: true
      ))
    end

    let(:values_certmanager_disabled) do
      YAML.safe_load(%(
        certmanager:
          install: false
        global:
          ingress:
            configureCertmanager: false
      )).deep_merge(values_all_enabled)
    end

    context 'when no Ingress Secrets are specified' do
      it 'includes the Self-Signed Certificates Job' do
        t = HelmTemplate.new(values_certmanager_disabled)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        expect(includes_selfsigned_job(t)).to be_truthy
      end
    end

    context 'when one Secret is specified' do
      let(:values) do
        YAML.safe_load(%(
          gitlab:
            webservice:
              ingress:
                tls:
                  secretName: foo
        )).deep_merge(values_certmanager_disabled)
      end

      it 'includes the Self-Signed Certificates Job' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        expect(includes_selfsigned_job(t)).to be_truthy
      end
    end

    context 'when all Secrets are specified globally' do
      let(:values) do
        YAML.safe_load(%(
          global:
            ingress:
              tls:
                secretName: global-tls
        )).deep_merge(values_certmanager_disabled)
      end

      it 'does not include the Self-Signed Certificates Job' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        expect(includes_selfsigned_job(t)).to be_falsy
      end
    end

    context 'when all Secrets are specified individually' do
      let(:values) do
        YAML.safe_load(%(
          gitlab:
            webservice:
              ingress:
                tls:
                  secretName: webservice-tls
                  smartcardSecretName: smartcard-tls
            kas:
              ingress:
                tls:
                  secretName: kas-tls
            gitlab-pages:
              ingress:
                tls:
                  secretName: pages-tls
          registry:
            ingress:
              tls:
                secretName: registry-tls
          minio:
            ingress:
              tls:
                secretName: minio-tls
        )).deep_merge(values_certmanager_disabled)
      end

      it 'does not include the Self-Signed Certificates Job' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        expect(includes_selfsigned_job(t)).to be_falsy
      end
    end
  end
end

def includes_selfsigned_job(template)
  includes = false
  template.resources_by_kind('Job').each do |resource, _|
    includes = true if resource.end_with?('selfsign')
    break if includes
  end

  includes
end
