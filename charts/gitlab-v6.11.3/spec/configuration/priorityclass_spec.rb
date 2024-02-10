# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'global priorityClass configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global:
        priorityClassName: system-cluster-critical
      gitlab:
        kas:
          enabled: true  # DELETE THIS WHEN KAS BECOMES ENABLED BY DEFAULT
        spamcheck:
          enabled: true  # DELETE THIS WHEN SPAMCHECK BECOMES ENABLED BY DEFAULT
      gitlab-runner:
        priorityClassName: system-cluster-critical
      prometheus:
        server:
          priorityClassName: system-cluster-critical
    ))
  end

  context 'When setting global priorityClassName' do
    it 'Populates priorityClassName for all deployments and jobs' do
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0)

      deployments = t.resources_by_kind('Deployment')

      deployments.each do |key, _|
        expect(t.dig(key, 'spec', 'template', 'spec', 'priorityClassName')).to eq('system-cluster-critical')
      end

      jobs = t.resources_by_kind('Job')

      jobs.each do |key, _|
        expect(t.dig(key, 'spec', 'template', 'spec', 'priorityClassName')).to eq('system-cluster-critical')
      end
    end
  end
end

describe 'local priorityClass configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global:
        priorityClassName: system-cluster-critical
      certmanager:
        global:
          priorityClassName: system-cluster-noncritical
      certmanager-issuer:
        priorityClassName: system-cluster-noncritical
      gitlab:
        geo-logcursor:
          priorityClassName: system-cluster-noncritical
        gitaly:
          priorityClassName: system-cluster-noncritical
        gitlab-exporter:
          priorityClassName: system-cluster-noncritical
        gitlab-pages:
          priorityClassName: system-cluster-noncritical
        gitlab-shell:
          priorityClassName: system-cluster-noncritical
        kas:
          enabled: true  # DELETE THIS WHEN KAS BECOMES ENABLED BY DEFAULT
          priorityClassName: system-cluster-noncritical
        mailroom:
          priorityClassName: system-cluster-noncritical
        migrations:
          priorityClassName: system-cluster-noncritical
        praefect:
          priorityClassName: system-cluster-noncritical
        sidekiq:
          priorityClassName: system-cluster-noncritical
        spamcheck:
          enabled: true  # DELETE THIS WHEN SPAMCHECK BECOMES ENABLED BY DEFAULT
          priorityClassName: system-cluster-noncritical
        toolbox:
          priorityClassName: system-cluster-noncritical
        webservice:
          priorityClassName: system-cluster-noncritical
      gitlab-runner:
        priorityClassName: system-cluster-noncritical
      minio:
        priorityClassName: system-cluster-noncritical
      nginx-ingress:
        controller:
          priorityClassName: system-cluster-noncritical
      prometheus:
        server:
          priorityClassName: system-cluster-noncritical
      registry:
        priorityClassName: system-cluster-noncritical
      shared-secrets:
        priorityClassName: system-cluster-noncritical
      upgradeCheck:
        priorityClassName: system-cluster-noncritical
    ))
  end

  let(:ignored_deployments) do
    [
      'Deployment/test-certmanager',
      'Deployment/test-certmanager-cainjector',
      'Deployment/test-certmanager-webhook'
    ]
  end

  let(:ignored_jobs) do
    [
      'Job/test-certmanager-startupapicheck'
    ]
  end

  context 'When setting local priorityClassName' do
    it 'Populates priorityClassName for all deployments and jobs' do
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0)

      deployments = t.resources_by_kind('Deployment').reject { |key, _| ignored_deployments.include? key }

      deployments.each do |key, _|
        expect(t.dig(key, 'spec', 'template', 'spec', 'priorityClassName')).to eq('system-cluster-noncritical')
      end

      jobs = t.resources_by_kind('Job').reject { |key, _| ignored_jobs.include? key }

      jobs.each do |key, _|
        expect(t.dig(key, 'spec', 'template', 'spec', 'priorityClassName')).to eq('system-cluster-noncritical')
      end
    end
  end
end
