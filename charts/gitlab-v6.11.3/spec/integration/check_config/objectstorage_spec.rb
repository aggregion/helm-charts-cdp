require 'spec_helper'
require 'check_config_helper'
require 'hash_deep_merge'

describe 'checkConfig objectstorage' do
  describe 'global.appConfig.objectStorage.ciSecureFiles' do
    describe 'global.appConfig.objectStorage.ciSecureFiles is enabled' do
      let(:error_values) do
        YAML.safe_load(%(
          gitlab:
            toolbox:
              enabled: false
          global:
            minio:
              enabled: false
            appConfig:
              object_store:
                enabled: true
              artifacts:
                bucket: gitlab-artifacts
              lfs:
                bucket: gitlab-ci-secure-files
              packages:
                bucket: gitlab-packages
              uploads:
                bucket: gitlab-uploads
              ciSecureFiles:
                enabled: true
        )).merge(default_required_values)
      end

      let(:success_values) do
        YAML.safe_load(%(
          global:
            appConfig:
              ciSecureFiles:
                connection:
                  secret: gitlab-cisecurefiles-storage
                  key: connection
          )).deep_merge(error_values)
      end

      let(:error_output) { 'A valid object storage configuration must be set for ciSecureFiles' }

      include_examples 'config validation',
                       success_description: 'when ciSecureFiles has a valid object storage connection and bucket configured',
                       error_description: 'when ciSecureFiles does not have a valid object storage connection and bucket configured'
    end
  end
end
