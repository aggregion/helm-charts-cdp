require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Certificates configuration' do
  # we're skipping anything not using this feature
  let(:skip_items) do
    [
      'minio', 'nginx', 'postgresql', 'redis',
      'gitlab-runner',
      'test-kas',
      # cert-manager Pods (2)
      'cainjector',
      'cert-manager', 'certmanager',
      'prometheus'
    ]
  end

  let(:default_values) do
    HelmTemplate.defaults
  end

  context 'Custom CA certificates' do
    context 'When present' do
      let(:single_ca) do
        default_values.deep_merge(YAML.safe_load(%(
          global:
            certificates:
              customCAs:
              - secret: rspec-custom-ca-secret-1
              - secret: rspec-custom-ca-secret-2
                keys:
                  - custom-ca-1.crt
                  - custom-ca-2.crt
              - configMap: rspec-custom-ca-configmap-1
              - configMap: rspec-custom-ca-configmap-2
                keys:
                  - custom-ca-3.crt
                  - custom-ca-4.crt
        )))
      end

      subject(:present) { HelmTemplate.new(single_ca) }

      it 'templates successfully' do
        expect(present.exit_code).to eq(0)
      end

      it 'populates volumes with extra Secret'  do
        present.resources_by_kind('Deployment').each do |resource|
          next if skip_items.any? { |i| resource[0].include? i }
          sources = present.projected_volume_sources(resource[0],'custom-ca-certificates')
          expect(sources).to be_truthy, "unable to locate 'custom-ca-certificates' volume for #{resource[0]}"
          expect(sources[0]['secret']['name']).to eq('rspec-custom-ca-secret-1')
          expect(sources[0]['secret']).not_to have_key('items')
          expect(sources[1]['secret']['name']).to eq('rspec-custom-ca-secret-2')
          expect(sources[1]['secret']['items'][0]['key']).to eq('custom-ca-1.crt')
          expect(sources[1]['secret']['items'][0]['path']).to eq('custom-ca-1.crt')
          expect(sources[1]['secret']['items'][1]['key']).to eq('custom-ca-2.crt')
          expect(sources[1]['secret']['items'][1]['path']).to eq('custom-ca-2.crt')
        end

        present.resources_by_kind('StatefulSet').each do |resource|
          next if skip_items.any? { |i| resource[0].include? i }
          sources = present.projected_volume_sources(resource[0],'custom-ca-certificates')
          expect(sources).to be_truthy, "unable to locate 'custom-ca-certificates' volume for #{resource[0]}"
          expect(sources[0]['secret']['name']).to eq('rspec-custom-ca-secret-1')
          expect(sources[0]['secret']).not_to have_key('items')
          expect(sources[1]['secret']['name']).to eq('rspec-custom-ca-secret-2')
          expect(sources[1]['secret']['items'][0]['key']).to eq('custom-ca-1.crt')
          expect(sources[1]['secret']['items'][0]['path']).to eq('custom-ca-1.crt')
          expect(sources[1]['secret']['items'][1]['key']).to eq('custom-ca-2.crt')
          expect(sources[1]['secret']['items'][1]['path']).to eq('custom-ca-2.crt')
        end
      end

      it 'populates volumes with extra ConfigMap'  do
        present.resources_by_kind('Deployment').each do |resource|
          next if skip_items.any? { |i| resource[0].include? i }
          sources = present.projected_volume_sources(resource[0],'custom-ca-certificates')
          expect(sources).to be_truthy, "unable to locate 'custom-ca-certificates' volume for #{resource[0]}"
          expect(sources[2]['configMap']['name']).to eq('rspec-custom-ca-configmap-1')
          expect(sources[2]['configMap']).not_to have_key('items')
          expect(sources[3]['configMap']['name']).to eq('rspec-custom-ca-configmap-2')
          expect(sources[3]['configMap']['items'][0]['key']).to eq('custom-ca-3.crt')
          expect(sources[3]['configMap']['items'][0]['path']).to eq('custom-ca-3.crt')
          expect(sources[3]['configMap']['items'][1]['key']).to eq('custom-ca-4.crt')
          expect(sources[3]['configMap']['items'][1]['path']).to eq('custom-ca-4.crt')
        end

        present.resources_by_kind('StatefulSet').each do |resource|
          next if skip_items.any? { |i| resource[0].include? i }
          sources = present.projected_volume_sources(resource[0],'custom-ca-certificates')
          expect(sources).to be_truthy, "unable to locate 'custom-ca-certificates' volume for #{resource[0]}"
          expect(sources[2]['configMap']['name']).to eq('rspec-custom-ca-configmap-1')
          expect(sources[2]['configMap']).not_to have_key('items')
          expect(sources[3]['configMap']['name']).to eq('rspec-custom-ca-configmap-2')
          expect(sources[3]['configMap']['items'][0]['key']).to eq('custom-ca-3.crt')
          expect(sources[3]['configMap']['items'][0]['path']).to eq('custom-ca-3.crt')
          expect(sources[3]['configMap']['items'][1]['key']).to eq('custom-ca-4.crt')
          expect(sources[3]['configMap']['items'][1]['path']).to eq('custom-ca-4.crt')
        end
      end

      it 'populates volumeMounts with extra volume'  do
        present.resources_by_kind('Deployment').each do |resource|
          next if skip_items.any? { |i| resource[0].include? i }
          volume_mount = present.find_volume_mount(resource[0],'certificates', 'custom-ca-certificates', true)
          expect(volume_mount).to be_truthy, "unable to locate 'custom-ca-certificates' mount in 'certificates' container of #{resource[0]}"
        end

        present.resources_by_kind('StatefulSet').each do |resource|
          next if skip_items.any? { |i| resource[0].include? i }
          volume_mount = present.find_volume_mount(resource[0],'certificates', 'custom-ca-certificates', true)
          expect(volume_mount).to be_truthy, "unable to locate 'custom-ca-certificates' mount in 'certificates' container of #{resource[0]}"
        end
      end
    end
  end
end
