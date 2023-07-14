require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig gitlab-shell' do
  describe 'gitlabShell.proxyPolicy' do
    let(:success_values) do
      YAML.safe_load(%(
        gitlab:
          gitlab-shell:
            config:
              proxyProtocol: true
              proxyPolicy: use
      )).merge(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        gitlab:
          gitlab-shell:
            config:
              proxyProtocol: true
              proxyPolicy: reject
      )).merge(default_required_values)
    end

    let(:error_output) { 'Either disable proxyProtocol or set proxyPolicy to "use", "require", or "ignore".' }

    include_examples 'config validation',
                     success_description: 'when proxyProtocol and proxyPolicy are compatible',
                     error_description: 'when proxyProtocol and proxyPolicy are incompatible'
  end
end
