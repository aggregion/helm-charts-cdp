require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Microsoft Graph Mailer configuration' do
  let(:charts_with_msgraph) do
    [
      'webservice',
      'sidekiq',
      'toolbox'
    ]
  end

  let(:charts_with_msgraph_init_secret_mounts) do
    {
      'test-sidekiq-all-in-1-v2' => 'init-sidekiq-secrets',
      'test-webservice-default' => 'init-webservice-secrets',
      'test-toolbox' => 'init-toolbox-secrets'
    }
  end

  let(:values) do
    HelmTemplate.with_defaults(%(
        global:
          appConfig:
            microsoft_graph_mailer:
              enabled: true
              user_id: "YOUR-USER-ID"
              tenant: "YOUR-TENANT-ID"
              client_id: "YOUR-CLIENT-ID"
              client_secret:
                secret: microsoft-graph-mailer-client-secret
                key: secret
              azure_ad_endpoint: "https://login.microsoftonline.com"
              graph_endpoint: "https://graph.microsoft.com"
    ))
  end

  let(:template) { HelmTemplate.new(values) }

  it 'populates microsoft_graph_mailer to gitlab.yml', :aggregate_failures do
    expect(template.exit_code).to eq(0)
    charts_with_msgraph.each do |chart|
      # check that gitlab.yml.erb contains production.microsoft_graph_mailer
      gitlab_yml_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb')
      expect(gitlab_yml_erb).to include(%(client_secret: <%= File.read('/etc/gitlab/microsoft_graph_mailer/client_secret').strip.to_json %>))
      microsoft_graph_mailer = YAML.safe_load(gitlab_yml_erb)['production']['microsoft_graph_mailer']
      expect(microsoft_graph_mailer['enabled']).to eq(true)
      expect(microsoft_graph_mailer['user_id']).to eq('YOUR-USER-ID')
      expect(microsoft_graph_mailer['client_id']).to eq('YOUR-CLIENT-ID')
      expect(microsoft_graph_mailer['azure_ad_endpoint']).to eq('https://login.microsoftonline.com')
      expect(microsoft_graph_mailer['graph_endpoint']).to eq('https://graph.microsoft.com')

      # check that the configure script includes `microsoft_graph_mailer`
      configure = template.dig("ConfigMap/test-#{chart}", 'data', 'configure')
      expect(configure).to match(/# optional\nfor secret in .* microsoft_graph_mailer .*; do/m)
    end
  end

  it 'populates microsoft-graph-mailer-client-secret into deployments' do
    charts_with_msgraph_init_secret_mounts.each do |deployment, mount|
      expect(template.find_projected_secret("Deployment/#{deployment}", mount, 'microsoft-graph-mailer-client-secret')).to be true
    end
  end

  describe "when toolbox backup cronjob is enabled" do
    let(:values_with_backup_cronjob) do
      YAML.safe_load(%(
        gitlab:
          toolbox:
            backups:
              cron:
                enabled: true
      )).deep_merge(values)
    end

    let(:template) { HelmTemplate.new(values_with_backup_cronjob) }

    it 'populates microsoft-graph-mailer-client-secret into cronjob'  do
      job_template_spec = template.dig('CronJob/test-toolbox-backup', 'spec', 'jobTemplate')
      job_pod_volumes = job_template_spec.dig('spec', 'template', 'spec', 'volumes')
      init_secret = job_pod_volumes.find { |s| s['name'] == 'init-toolbox-secrets' }
      secret_names = init_secret["projected"]["sources"].map do |item|
        item['secret']['name']
      end
      expect(secret_names).to include('microsoft-graph-mailer-client-secret')
    end
  end
end
