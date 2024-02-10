require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'security context' do
  describe 'pod security context configuration' do
    let(:template) do
      values = HelmTemplate.with_defaults(%(
        global:
          psql:
            host: geo-1.db.example.com
            password:
              secret: sekrit
              key: pa55word
          geo:
            enabled: true
            role: secondary
            psql:
              host: geo-2.db.example.com
              port: 5431
              password:
                secret: geo
                key: postgresql-password
          appConfig:
            incomingEmail:
              enabled: true
              password:
                secret: foobar
          pages:
            enabled: true
          kas:
            enabled: true
          praefect:
            enabled: true
          spamcheck:
            enabled: true
        minio:
          securityContext:
            fsGroupChangePolicy: "OnRootMismatch"
        registry:
          securityContext:
            fsGroupChangePolicy: "OnRootMismatch"
        gitlab:
          gitaly:
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
          gitlab-exporter:
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
          geo-logcursor:
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
          gitlab-pages:
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
          gitlab-shell:
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
          kas:
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
          mailroom:
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
          migrations:
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
          praefect:
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
          sidekiq:
            enabled: true
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
          spamcheck:
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
          webservice:
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
          toolbox:
            backups:
              cron:
                enabled: true
            securityContext:
              fsGroupChangePolicy: "OnRootMismatch"
      ))
      HelmTemplate.new(values)
    end

    it 'renders successfully' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
    end

    it 'applied fsGroupChangePolicy to the toolbox cronjob' do
      policy = template.dig('CronJob/test-toolbox-backup', 'spec', 'jobTemplate', 'spec', 'template', 'spec', 'securityContext', 'fsGroupChangePolicy')
      expect(policy).to eq("OnRootMismatch"), "Unexpected fsGroupChangePolicy #{policy}"
    end

    it 'applied fsGroupChangePolicy to the migrations job' do
      policy = template.dig("Job/test-migrations-1", 'spec', 'template', 'spec', 'securityContext', 'fsGroupChangePolicy')
      expect(policy).to eq("OnRootMismatch"), "Unexpected fsGroupChangePolicy #{policy}"
    end

    it "applied fsGroupChangePolicy to statefulsets and deployments" do
      [
        'Deployment/test-minio',
        'Deployment/test-registry',
        'Deployment/test-gitlab-exporter',
        'Deployment/test-geo-logcursor',
        'Deployment/test-gitlab-pages',
        'Deployment/test-gitlab-shell',
        'Deployment/test-kas',
        'Deployment/test-mailroom',
        'Deployment/test-sidekiq-all-in-1-v2',
        'Deployment/test-spamcheck',
        'Deployment/test-webservice-default',
        'StatefulSet/test-gitaly-default',
        'StatefulSet/test-praefect'
      ].each do |r|
        policy = template.dig(r, 'spec', 'template', 'spec', 'securityContext', 'fsGroupChangePolicy')
        expect(policy).to eq("OnRootMismatch"), "Unexpected fsGroupChangePolicy `#{policy}` for #{r}"
      end
    end
  end
end
