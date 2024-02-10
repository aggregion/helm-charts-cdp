require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'gitlab-shell configuration' do
  let(:t) { HelmTemplate.new(values) }
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global: {}
      gitlab:
        gitlab-shell:
          networkpolicy:
            enabled: true
          serviceAccount:
            enabled: true
            create: true
    ))
  end

  def expect_successful_exit_code
    expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
  end

  context 'when gitlab-sshd is enabled' do
    using RSpec::Parameterized::TableSyntax

    let(:proxy_protocol) { true }
    let(:proxy_policy) { "require" }
    let(:proxy_header_timeout) { "1s" }
    let(:grace_period) { 30 }
    let(:client_alive_interval) { 15 }
    let(:login_grace_time) { 60 }

    let(:values) do
      YAML.safe_load(%(
        gitlab:
          gitlab-shell:
            sshDaemon: "gitlab-sshd"
            deployment:
              terminationGracePeriodSeconds: #{grace_period}
            config:
              clientAliveInterval: #{client_alive_interval}
              proxyProtocol: #{proxy_protocol}
              proxyPolicy: #{proxy_policy}
              proxyHeaderTimeout: #{proxy_header_timeout}
              loginGraceTime: #{login_grace_time}
      )).deep_merge(default_values)
    end

    let(:config) { t.dig('ConfigMap/test-gitlab-shell', 'data', 'config.yml.tpl') }

    it 'renders gitlab-sshd config' do
      expect_successful_exit_code
      expect(config).to match(/^sshd:$/)
      expect(config).to include("proxy_protocol: #{proxy_protocol}")
      expect(config).to include("proxy_policy: #{proxy_policy}")
      expect(config).to include("client_alive_interval: #{client_alive_interval}")
      expect(config).to include("proxy_header_timeout: #{proxy_header_timeout}")
      expect(config).to match(/ciphers:\n    - aes128-gcm@openssh.com/m)
      expect(config).to match(/kex_algorithms:\n    - curve25519-sha256/m)
      expect(config).to match(/macs:\n    - hmac-sha2-256-etm@openssh.com/m)
      expect(config).to include("login_grace_time: #{login_grace_time}")
    end

    it 'sets 5 seconds smaller grace period' do
      expect(config).to include("grace_period: #{grace_period - 5}")
    end
  end

  context 'when PROXY protocol is set' do
    using RSpec::Parameterized::TableSyntax

    where(:ssh_daemon, :in_proxy_protocol, :out_proxy_protocol, :proxy_policy, :expected_suffix) do
      "openssh"     | false | false | "use"     | "::"
      "openssh"     | true  | false | "use"     | ":PROXY:"
      "openssh"     | true  | true  | "use"     | ":PROXY:PROXY"
      "openssh"     | false | true  | "use"     | "::PROXY"

      "gitlab-sshd" | false | false | "use"     | "::PROXY"
      "gitlab-sshd" | true  | false | "use"     | ":PROXY:PROXY"
      "gitlab-sshd" | true  | true  | "use"     | ":PROXY:PROXY"
      "gitlab-sshd" | false | true  | "use"     | "::PROXY"

      "gitlab-sshd" | true  | true  | "require" | ":PROXY:PROXY"
      "gitlab-sshd" | true  | false | "require" | ":PROXY:PROXY"

      "gitlab-sshd" | true  | true  | "ignore"  | ":PROXY:PROXY"
      "gitlab-sshd" | true  | false | "ignore"  | ":PROXY:PROXY"

      "gitlab-sshd" | true  | false | "reject"  | ":PROXY:"
      # out_proxy_protocol = false and "reject" case handled by checkConfig
    end

    with_them do
      let(:values) do
        YAML.safe_load(%(
          global:
            shell:
              tcp:
                proxyProtocol: #{in_proxy_protocol}
          gitlab:
            gitlab-shell:
              sshDaemon: "#{ssh_daemon}"
              config:
                proxyProtocol: #{out_proxy_protocol}
                proxyPolicy: #{proxy_policy}
        )).deep_merge(default_values)
      end

      it 'should render NGINX ingress TCP data correctly' do
        expect_successful_exit_code

        data = t.dig('ConfigMap/test-nginx-ingress-tcp', 'data')

        expect(data.keys).to eq(['22'])
        expect(data['22']).to eq("default/test-gitlab-shell:22#{expected_suffix}")
      end
    end
  end

  context 'When customer provides additional labels' do
    let(:values) do
      YAML.safe_load(%(
        global:
          common:
            labels:
              global: global
              foo: global
          pod:
            labels:
              global_pod: true
          service:
            labels:
              global_service: true
        gitlab:
          gitlab-shell:
            common:
              labels:
                global: shell
                shell: shell
            podLabels:
              pod: true
              global: pod
            serviceLabels:
              service: true
              global: service
      )).deep_merge(default_values)
    end

    it 'Populates the additional labels in the expected manner' do
      expect_successful_exit_code

      expect(t.dig('ConfigMap/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('Deployment/test-gitlab-shell', 'metadata', 'labels')).to include('foo' => 'global')
      expect(t.dig('Deployment/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('Deployment/test-gitlab-shell', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
      expect(t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
      expect(t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
      expect(t.dig('HorizontalPodAutoscaler/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('NetworkPolicy/test-gitlab-shell-v1', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('PodDisruptionBudget/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('Service/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'service')
      expect(t.dig('Service/test-gitlab-shell', 'metadata', 'labels')).to include('global_service' => 'true')
      expect(t.dig('Service/test-gitlab-shell', 'metadata', 'labels')).to include('service' => 'true')
      expect(t.dig('Service/test-gitlab-shell', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('ServiceAccount/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
    end
  end
end
