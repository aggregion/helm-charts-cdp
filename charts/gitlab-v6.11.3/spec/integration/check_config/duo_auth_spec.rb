require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig duo' do
  describe 'gitlab.duoAuth.checkConfig (hostname)' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            duoAuth:
              enabled: true
              hostname: test.api.hostname
              integrationKey: dummy_integration_key
              secretKey:
                secret: SecretName
                key: KeyName
      )).merge(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            duoAuth:
              enabled: true
      )).merge(default_required_values)
    end

    let(:error_output) { 'Enabling Duo Auth requires hostname to be present' }

    include_examples 'config validation',
                     success_description: 'when duo auth is enabled and hostname is defined',
                     error_description: 'when duo auth is enabled but hostname is not undefined'
  end

  describe 'gitlab.duoAuth.checkConfig (integration_key)' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            duoAuth:
              enabled: true
              hostname: test.api.hostname
              integrationKey: dummy_integration_key
              secretKey:
                secret: SecretName
                key: KeyName
      )).merge(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            duoAuth:
              enabled: true
              hostname: test.api.hostname
      )).merge(default_required_values)
    end

    let(:error_output) { 'Enabling Duo Auth requires integrationKey to be present' }

    include_examples 'config validation',
                     success_description: 'when duo auth is enabled and integrationKey is defined',
                     error_description: 'when duo auth is enabled but integrationKey is not undefined'
  end

  describe 'gitlab.duoAuth.checkConfig (secret_key)' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            duoAuth:
              enabled: true
              hostname: test.api.hostname
              integrationKey: dummy_integration_key
              secretKey:
                secret: SecretName
                key: KeyName
      )).merge(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            duoAuth:
              enabled: true
              hostname: test.api.hostname
              integrationKey: dummy_integration_key
      )).merge(default_required_values)
    end

    let(:error_output) { 'Enabling Duo Auth requires secretKey.secret to be present' }

    include_examples 'config validation',
                     success_description: 'when duo auth is enabled and secretKey is defined',
                     error_description: 'when duo auth is enabled but secretKey is not undefined'
  end
end
