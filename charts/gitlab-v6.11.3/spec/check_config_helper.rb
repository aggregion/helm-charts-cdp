# frozen_string_literal: true
# frozen_string_literal: true

require 'helm_template_helper'

RSpec.shared_context "check config setup", shared_context: :metadata do
  let(:check) do
    Open3.capture3(HelmTemplate.helm_template_call(release_name: 'gitlab-checkconfig-test'),
                   chdir: File.join(__dir__, '..'),
                   stdin_data: YAML.dump(values))
  end

  let(:stdout) { check[0] }
  let(:stderr) { check[1] }
  let(:exit_code) { check[2].to_i }

  let(:default_required_values) do
    HelmTemplate.defaults
  end
end

RSpec.shared_examples 'config validation' do |success_description: '', error_description: ''|
  include_context 'check config setup'

  if success_description != '' && !success_description.nil?
    context success_description do
      let(:values) { success_values }

      it 'succeeds', :aggregate_failures do
        expect(exit_code).to eq(0)
        expect(stdout).to include('name: gitlab-checkconfig-test')
        expect(stderr).to be_empty
      end
    end
  end

  if error_description != '' && !error_description.nil?
    context error_description do
      let(:values) { error_values }

      it 'returns an error', :aggregate_failures do
        expect(exit_code).to be > 0
        expect(stdout).to be_empty
        expect(stderr).to include(error_output)
      end
    end
  end
end
