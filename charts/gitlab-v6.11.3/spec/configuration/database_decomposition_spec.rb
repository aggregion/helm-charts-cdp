require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Database configuration' do
  def database_yml(template, chart_name)
    template.dig("ConfigMap/test-#{chart_name}", 'data', 'database.yml.erb')
  end

  def database_config(template, chart_name)
    db_config = database_yml(template, chart_name)
    YAML.safe_load(db_config)
  end

  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global:
        psql:
          host: ''
          serviceName: ''
          username: ''
          database: ''
          applicationName: nil
          preparedStatements: ''
          password:
            secret: ''
            key: ''
          connectTimeout: nil
          keepalives: nil
          keepalivesIdle: nil
          keepalivesInterval: nil
          keepalivesCount: nil
          tcpUserTimeout: nil
      postgresql:
        install: true
    ))
  end

  describe 'No decomposition' do
    context 'With default configuration' do
      it '`database.yml` Provides only `main` stanza and uses in-chart postgresql service' do
        t = HelmTemplate.new(default_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        db_config = database_config(t, 'webservice')
        expect(db_config['production'].keys).to contain_exactly('main')
        expect(db_config['production'].dig('main', 'host')).to eq('test-postgresql.default.svc')
        expect(db_config['production'].dig('main', 'database_tasks')).to eq(true)
      end
    end

    context 'When `main` is provided' do
      it 'inherits settings from x.psql where not provided, uses own' do
        t = HelmTemplate.new(default_values.deep_merge(YAML.safe_load(%(
          global:
            psql:
              databaseTasks: true
              password:
                secret: sekrit
                key: pa55word
              main:
                host: server
                port: 9999
        ))))

        db_config = database_config(t, 'webservice')
        expect(db_config['production'].dig('main', 'host')).to eq('server')
        expect(db_config['production'].dig('main', 'port')).to eq(9999)
        expect(db_config['production'].dig('main', 'database_tasks')).to eq(true)

        webservice_secret_mounts = t.projected_volume_sources('Deployment/test-webservice-default', 'init-webservice-secrets').select do |item|
          item['secret']['name'] == 'sekrit' && item['secret']['items'][0]['key'] == 'pa55word'
        end
        expect(webservice_secret_mounts.length).to eq(1)
      end
    end
  end

  describe 'Invalid decomposition (x.psql.bogus)' do
    let(:decompose_bogus) do
      default_values.deep_merge(YAML.safe_load(%(
        global:
          psql:
            bogus:
              host: bogus
      )))
    end

    context 'database.yml' do
      it 'Does not contain `bogus` stanza' do
        t = HelmTemplate.new(decompose_bogus)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        db_config = database_config(t, 'webservice')
        expect(db_config['production'].keys).not_to include('bogus')
      end
    end

    context 'volumes' do
      it 'Does not template password files for `bogus` stanza' do
        t = HelmTemplate.new(decompose_bogus)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        webservice_secret_mounts = t.projected_volume_sources('Deployment/test-webservice-default', 'init-webservice-secrets').select do |item|
          item['secret']['items'][0]['key'] == 'postgresql-password' && item['secret']['items'][0]['path'] == 'postgres/psql-password-bogus'
        end
        expect(webservice_secret_mounts.length).to eq(0)
      end
    end
  end

  describe 'Stanzas inherit from `main` when present, `psql` when not in `main`' do
    let(:decompose_inherit) do
      default_values.deep_merge(YAML.safe_load(%(
        global:
          psql:
            username: global-user
            applicationName: global-application
            main:
              host: main-server
              port: 9999
            ci:
              username: ci-user
      )))
    end

    let(:sidekiq_override) do
      decompose_inherit.deep_merge(YAML.safe_load(%(
        gitlab:
          sidekiq:
            psql:
              main:
                load_balancing:
                  hosts:
                    - a.sidekiq.global
                    - b.sidekiq.global
        postgresql: # must disable for load_balancing
          install: false
      )))
    end

    context 'database.yml' do
      it 'Settings inherited per expectation: host from main, user from global' do
        t = HelmTemplate.new(decompose_inherit)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        db_config = database_config(t, 'webservice')
        expect(db_config['production'].keys).to contain_exactly('main', 'ci')

        # check `main` stanza
        main_config = db_config['production']['main']
        expect(main_config['host']).to eq('main-server')
        expect(main_config['port']).to eq(9999)
        expect(main_config['username']).to eq('global-user')
        expect(main_config['application_name']).to eq('global-application')
        expect(main_config['database_tasks']).to eq(true)

        # check `ci` stanza
        ci_config = db_config['production']['ci']
        expect(ci_config['host']).to eq('main-server')
        expect(ci_config['port']).to eq(9999)
        expect(ci_config['username']).to eq('ci-user')
        expect(ci_config['application_name']).to eq('global-application')
        expect(ci_config['database_tasks']).to eq(false)
      end
    end

    describe 'Sidekiq overrides psql.main.load_balancing' do
      it 'Uses local settings for load_balancing' do
        t = HelmTemplate.new(sidekiq_override)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        sidekiq_config = database_config(t, 'sidekiq')
        sidekiq_config = sidekiq_config['production']['main']
        expect(sidekiq_config).to include('load_balancing')

        webservice_config = database_config(t, 'webservice')
        webservice_config = webservice_config['production']['main']
        expect(webservice_config).not_to include('load_balancing')
      end
    end
  end

  describe 'CI is decomposed (x.psql.ci)' do
    let(:decompose_ci) do
      default_values.deep_merge(YAML.safe_load(%(
        global:
          psql:
            ci:
              foo: bar
      )))
    end

    it 'can be disabled' do
      decompose_ci_with_enabled_false = decompose_ci.deep_merge(YAML.safe_load(%(
        global:
          psql:
            ci:
              enabled: false
      )))

      t = HelmTemplate.new(decompose_ci_with_enabled_false)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      db_config = database_config(t, 'webservice')
      expect(db_config['production'].keys).to contain_exactly('main')
    end

    context 'With minimal configuration' do
      it 'Provides `main` and `ci` stanzas' do
        t = HelmTemplate.new(decompose_ci)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        db_config = database_config(t, 'webservice')
        expect(db_config['production'].keys).to contain_exactly('main', 'ci')
        expect(db_config['production'].dig('main', 'host')).to eq('test-postgresql.default.svc')
        expect(db_config['production'].dig('main', 'database_tasks')).to eq(true)
        expect(db_config['production'].dig('ci', 'host')).to eq('test-postgresql.default.svc')
        expect(db_config['production'].dig('ci', 'database_tasks')).to eq(false), "since CI shared db/host/port with main:"
      end

      it 'Places `main` stanza first' do
        t = HelmTemplate.new(decompose_ci)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        database_yml = database_yml(t, 'webservice')
        expect(database_yml).to match("production:\n  main:\n")
      end

      it 'Templates different password files for each stanza' do
        t = HelmTemplate.new(decompose_ci)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        database_yml = database_yml(t, 'webservice')
        expect(database_yml).to include('/etc/gitlab/postgres/psql-password-main', '/etc/gitlab/postgres/psql-password-ci')
      end
    end

    context 'With complex configuration' do
      # This test shows using different user/password/application, inheriting load_balancing.
      let(:complex_ci) do
        decompose_ci.deep_merge(YAML.safe_load(%(
          global:
            psql:
              host: global-server
              password:
                secret: global-psql
              load_balancing:
                hosts:
                - a.secondary.global
                - b.secondary.global
              main:
                username: main-user
                password:
                  secret: main-password
                applicationName: main
                preparedStatements: true
              ci:
                username: ci-user
                password:
                  secret: ci-password
                applicationName: ci
                preparedStatements: false
                databaseTasks: false
          postgresql:
            install: false
        )))
      end

      it 'Templates each group according to overrides' do
        t = HelmTemplate.new(complex_ci)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        db_config = database_config(t, 'webservice')
        expect(db_config['production'].keys).to contain_exactly('main', 'ci')

        # check `main` stanza
        main_config = db_config['production']['main']
        expect(main_config['host']).to eq('global-server')
        expect(main_config['port']).to eq(5432)
        expect(main_config['username']).to eq('main-user')
        expect(main_config['application_name']).to eq('main')
        expect(main_config['load_balancing']).to eq({ 'hosts' => ['a.secondary.global', 'b.secondary.global'] })
        expect(main_config['prepared_statements']).to eq(true)
        expect(main_config['database_tasks']).to eq(true)

        # check `ci` stanza
        ci_config = db_config['production']['ci']
        expect(ci_config['host']).to eq('global-server')
        expect(ci_config['port']).to eq(5432)
        expect(ci_config['username']).to eq('ci-user')
        expect(ci_config['application_name']).to eq('ci')
        expect(ci_config['load_balancing']).to eq({ 'hosts' => ['a.secondary.global', 'b.secondary.global'] })
        expect(ci_config['prepared_statements']).to eq(false)
        expect(ci_config['database_tasks']).to eq(false)

        # Check the secret mounts
        webservice_secret_mounts = t.projected_volume_sources('Deployment/test-webservice-default', 'init-webservice-secrets').select do |item|
          item['secret']['items'][0]['key'] == 'postgresql-password'
        end
        psql_secret_mounts = webservice_secret_mounts.map { |x| x['secret']['name'] }
        expect(psql_secret_mounts).to contain_exactly('main-password', 'ci-password')
      end
    end

    context 'when handling defaults for the databaseTasks:' do
      where do
        {
          "when no databaseTasks: is defined, and main/ci: do share database, the default for ci is false" => {
            psql_config: {},
            expected: {
              main: {
                database_tasks: true
              },
              ci: {
                database_tasks: false
              }
            }
          },
          "when no databaseTasks: is defined, and main/ci: do share database, and load_balancing is defined, the default for ci is false and items are properly inherited" => {
            psql_config: {
              main: {
                load_balancing: {
                  hosts: %w[postgres postgres2]
                }
              }
            },
            expected: {
              main: {
                database_tasks: true,
                load_balancing: {
                  hosts: %w[postgres postgres2]
                }
              },
              ci: {
                database_tasks: false,
                load_balancing: {
                  hosts: %w[postgres postgres2]
                }
              }
            }
          },
          "when databaseTasks=true, and main/ci: do share database, uses user provided value" => {
            psql_config: {
              ci: {
                databaseTasks: true
              }
            },
            expected: {
              main: {
                database_tasks: true
              },
              ci: {
                database_tasks: true
              }
            }
          },
          "when databaseTasks=true, and main/ci: do share database, and load_balancing is defined, uses user provided value, and properly inherited" => {
            psql_config: {
              main: {
                load_balancing: {
                  hosts: %w[postgres postgres2]
                }
              },
              ci: {
                databaseTasks: true
              }
            },
            expected: {
              main: {
                database_tasks: true,
                load_balancing: {
                  hosts: %w[postgres postgres2]
                }
              },
              ci: {
                database_tasks: true,
                load_balancing: {
                  hosts: %w[postgres postgres2]
                }
              }
            }
          },
          "when databaseTasks=true is defined globally, and main/ci: do share database, uses user provided value" => {
            psql_config: {
              databaseTasks: true
            },
            expected: {
              main: {
                database_tasks: true
              },
              ci: {
                database_tasks: true
              }
            }
          },
          "when databaseTasks=true is defined in main:, and main/ci: do share database, does inherit from main to use user provided value" => {
            psql_config: {
              main: {
                databaseTasks: true
              }
            },
            expected: {
              main: {
                database_tasks: true
              },
              ci: {
                database_tasks: true
              }
            }
          },
          "when no databaseTasks: is defined, and ci: uses different host, the default for ci is true" => {
            psql_config: {
              ci: {
                host: 'another-host'
              }
            },
            expected: {
              main: {
                database_tasks: true
              },
              ci: {
                host: 'another-host',
                database_tasks: true
              }
            }
          },
          "when no databaseTasks: is defined, and ci: uses different port, the default for ci is true" => {
            psql_config: {
              ci: {
                port: 11111
              }
            },
            expected: {
              main: {
                port: 5432,
                database_tasks: true
              },
              ci: {
                port: 11111,
                database_tasks: true
              }
            }
          },
          "when no databaseTasks: is defined, and ci: uses different database, the default for ci is true" => {
            psql_config: {
              ci: {
                database: 'gitlab_ci'
              }
            },
            expected: {
              main: {
                database_tasks: true
              },
              ci: {
                database: 'gitlab_ci',
                database_tasks: true
              }
            }
          },
          "when databaseTasks=false, and ci: uses different host, uses user provided value" => {
            psql_config: {
              ci: {
                host: 'patroni-ci',
                databaseTasks: false
              }
            },
            expected: {
              main: {
                database_tasks: true
              },
              ci: {
                host: 'patroni-ci',
                database_tasks: false
              }
            }
          }
        }
      end

      with_them do
        it 'does output expected configuration' do
          config = { global: { psql: psql_config } }
          config = JSON.parse(config.to_json) # deep_stringify_keys
          config = decompose_ci.deep_merge(config)
          t = HelmTemplate.new(config)
          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

          db_config = database_config(t, 'webservice')
          expect(db_config['production'].keys).to contain_exactly(*expected.keys.map(&:to_s))

          expected.each do |database, expected_config|
            expected_config = JSON.parse(expected_config.to_json) # deep_stringify_keys
            expect(db_config['production'][database.to_s]).to include(expected_config)
          end
        end
      end
    end
  end

  describe 'Geo primary role' do
    let(:geo_values) do
      default_values.deep_merge(YAML.safe_load(%(
        global:
          psql:
            host: db.example.com
            password:
              secret: sekrit
              key: pa55word
          geo:
            enabled: true
            role: primary
      )))
    end

    context 'With default configuration' do
      context 'With Geo primary enabled' do
        it 'Provides only `main` stanza' do
          t = HelmTemplate.new(geo_values)
          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          db_config = database_config(t, 'webservice')
          expect(db_config['production'].keys).to contain_exactly('main')
          expect(db_config['production'].dig('main', 'host')).to eq('db.example.com')
          expect(db_config['production'].dig('main', 'database_tasks')).to eq(true)
        end
      end

      context 'With Geo primary disabled' do
        it 'Provides only `main` stanza' do
          t = HelmTemplate.new(default_values.deep_merge(YAML.safe_load(%(
            global:
              geo:
                enabled: false
          ))))

          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          db_config = database_config(t, 'webservice')
          expect(db_config['production'].keys).to contain_exactly('main')
          expect(db_config['production'].dig('main', 'host')).to eq('test-postgresql.default.svc')
          expect(db_config['production'].dig('main', 'database_tasks')).to eq(true)
        end
      end
    end

    context 'When `main` is provided' do
      context 'With Geo primary enabled' do
        it 'Provides only `main` stanza' do
          t = HelmTemplate.new(geo_values.deep_merge(YAML.safe_load(%(
            global:
              psql:
                main:
                  host: server
                  port: 9999
          ))))

          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          db_config = database_config(t, 'webservice')
          expect(db_config['production'].keys).to contain_exactly('main')
          expect(db_config['production'].dig('main', 'host')).to eq('server')
          expect(db_config['production'].dig('main', 'database_tasks')).to eq(true)
        end
      end

      context 'With Geo primary disabled' do
        it 'Provides only `main` stanza' do
          t = HelmTemplate.new(geo_values.deep_merge(YAML.safe_load(%(
            global:
              psql:
                main:
                  host: server
                  port: 9999
              geo:
                enabled: false
          ))))

          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          db_config = database_config(t, 'webservice')
          expect(db_config['production'].keys).to contain_exactly('main')
          expect(db_config['production'].dig('main', 'host')).to eq('server')
          expect(db_config['production'].dig('main', 'database_tasks')).to eq(true)
        end
      end
    end
  end

  describe 'Geo secondary role' do
    let(:geo_values) do
      default_values.deep_merge(YAML.safe_load(%(
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
      )))
    end

    context 'With default configuration' do
      context 'With Geo secondary enabled' do
        it 'Provides `main` and `geo` stanzas' do
          t = HelmTemplate.new(geo_values)
          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          db_config = database_config(t, 'webservice')
          expect(db_config['production'].keys).to contain_exactly('main', 'geo')
          expect(db_config['production'].dig('main', 'host')).to eq('geo-1.db.example.com')
          expect(db_config['production'].dig('main', 'database_tasks')).to eq(true)
          expect(db_config['production'].dig('geo', 'host')).to eq('geo-2.db.example.com')
          expect(db_config['production'].dig('geo', 'database_tasks')).to eq(true)
        end

        it 'Places `main` stanza first' do
          t = HelmTemplate.new(geo_values)
          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          database_yml = database_yml(t, 'webservice')
          expect(database_yml).to match("production:\n  main:\n")
        end
      end

      context 'With Geo secondary disabled' do
        it 'Provides only `main` stanza' do
          t = HelmTemplate.new(default_values.deep_merge(YAML.safe_load(%(
            global:
              geo:
                enabled: false
          ))))

          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          db_config = database_config(t, 'webservice')
          expect(db_config['production'].keys).to contain_exactly('main')
          expect(db_config['production'].dig('main', 'host')).to eq('test-postgresql.default.svc')
          expect(db_config['production'].dig('main', 'database_tasks')).to eq(true)
        end
      end
    end

    context 'When `main` is provided' do
      context 'With Geo secondary enabled' do
        it 'Provides `main` and `geo` stanzas' do
          t = HelmTemplate.new(geo_values.deep_merge(YAML.safe_load(%(
            global:
              psql:
                main:
                  host: server
                  port: 9999
          ))))

          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          db_config = database_config(t, 'webservice')
          expect(db_config['production'].keys).to contain_exactly('main', 'geo')
          expect(db_config['production'].dig('main', 'host')).to eq('server')
          expect(db_config['production'].dig('main', 'database_tasks')).to eq(true)
          expect(db_config['production'].dig('geo', 'host')).to eq('geo-2.db.example.com')
          expect(db_config['production'].dig('geo', 'database_tasks')).to eq(true)
        end

        it 'Places `main` stanza first' do
          t = HelmTemplate.new(geo_values.deep_merge(YAML.safe_load(%(
            global:
              psql:
                main:
                  port: 9999
          ))))

          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          database_yml = database_yml(t, 'webservice')
          expect(database_yml).to match("production:\n  main:\n")
        end
      end

      context 'With Geo secondary disabled' do
        it 'Provides only `main` stanza' do
          t = HelmTemplate.new(geo_values.deep_merge(YAML.safe_load(%(
            global:
              psql:
                main:
                  host: server
                  port: 9999
              geo:
                enabled: false
          ))))

          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
          db_config = database_config(t, 'webservice')
          expect(db_config['production'].keys).to contain_exactly('main')
          expect(db_config['production'].dig('main', 'host')).to eq('server')
          expect(db_config['production'].dig('main', 'database_tasks')).to eq(true)
        end
      end
    end
  end
end
