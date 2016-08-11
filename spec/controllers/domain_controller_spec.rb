# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Domain Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w(1)

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      context 'by an admin user' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:testdomain) { create(:domain) }
        let!(:testadmin) { create(:admin, password: 'secret') }

        describe 'GET all' do
          it 'authorizes (policies) and returns an array of domains' do
            get(
              "/api/v#{api_version}/domains", nil,
              auth_headers_apikey(testadmin.id)
            )

            scope = Pundit.policy_scope(testadmin, Domain)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testadmin.id
              )
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/domains", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'authorizes the request by using the policies' do
            expect(Pundit.authorize(testadmin, testdomain, :show?)).to be_truthy
          end

          it 'returns the domain' do
            get(
              "/api/v#{api_version}/domains/#{testdomain.id}", nil,
              auth_headers_apikey(testadmin.id)
            )

            @user = testadmin
            expect(last_response.body).to eq(
              spec_authorized_resource(object: testdomain, user: testadmin)
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/domains/#{testdomain.id}", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'returns an API Error' do
            inexistent = testdomain.id
            testdomain.destroy

            get(
              "/api/v#{api_version}/domains/#{inexistent}", nil,
              auth_headers_apikey(testadmin.id)
            )

            expect(last_response.status).to eq(404)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:not_found)).to_json
              )
            )
          end
        end

        describe 'POST' do
          context 'with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(Pundit.authorize(testadmin, Domain, :create?)).to be_truthy
            end

            it 'creates a new domain' do
              count = Domain.all.count

              post(
                "/api/v#{api_version}/domains",
                attributes_for(:domain, name: 'new.org').to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(Domain.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new domain' do
              post(
                "/api/v#{api_version}/domains",
                attributes_for(:domain, name: 'new.org').to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = Domain.last

              expect(last_response.status).to eq(201)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  ApiResponseSuccess.new(status_code: 201,
                                         data: { object: new }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              post(
                "/api/v#{api_version}/domains",
                attributes_for(:domain, name: 'new.org').to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new domain' do
              post(
                "/api/v#{api_version}/domains",
                attributes_for(:domain, name: 'new.org').to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = Domain.last

              expect(last_response.location).to eq(
                "http://example.org/api/v#{api_version}/domains/#{new.id}"
              )
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{ , name: \'foo, enabled: true }' }

              it 'does not create a new domain' do
                count = Domain.all.count

                post(
                  "/api/v#{api_version}/domains",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Domain.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/domains",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(400)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:malformed_request)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                post(
                  "/api/v#{api_version}/domains",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_domain_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not create a new domain' do
                count = Domain.all.count

                post(
                  "/api/v#{api_version}/domains",
                  invalid_domain_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Domain.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/domains",
                  invalid_domain_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:invalid_domain)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                post(
                  "/api/v#{api_version}/domains",
                  invalid_domain_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_domain) }

              it 'does not create a new domain' do
                count = Domain.all.count

                post(
                  "/api/v#{api_version}/domains",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Domain.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/domains",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:invalid_domain)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                post(
                  "/api/v#{api_version}/domains",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with a resource conflict' do
              before(:each) do
                create(:domain, name: 'existing.domain')
              end
              let(:resource_conflict) do
                build(:domain, name: 'existing.domain')
              end

              it 'does not create a new domain' do
                count = Domain.all.count

                post(
                  "/api/v#{api_version}/domains",
                  resource_conflict.to_json(methods: nil),
                  auth_headers_apikey(testadmin.id)
                )

                expect(Domain.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/domains",
                  resource_conflict.to_json(methods: nil),
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(409)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:resource_conflict)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                post(
                  "/api/v#{api_version}/domains",
                  resource_conflict.to_json(methods: nil),
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end
        end

        describe 'PATCH' do
          context 'with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(Pundit.authorize(testadmin, Domain, :create?)).to be_truthy
            end

            it 'updates an existing domain with new values' do
              updated_attrs = attributes_for(:domain, name: 'foo.org')
              prev_tstamp = testdomain.updated_at

              patch(
                "/api/v#{api_version}/domains/#{testdomain.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(Domain.get(testdomain.id).name).to eq(updated_attrs[:name])
              expect(Domain.get(testdomain.id).updated_at).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated domain' do
              updated_attrs = attributes_for(:domain, name: 'foo.org')

              patch(
                "/api/v#{api_version}/domains/#{testdomain.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              upd_user = Domain.get(testdomain.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  ApiResponseSuccess.new(status_code: 200,
                                         data: { object: upd_user }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              updated_attrs = attributes_for(:domain, name: 'foo.org')

              patch(
                "/api/v#{api_version}/domains/#{testdomain.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{ , name: \'foo, enabled: true }' }

              it 'does not update the domain' do
                prev_tstamp = testdomain.updated_at

                patch(
                  "/api/v#{api_version}/domains/#{testdomain.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Domain.get(testdomain.id).name).to eq(testdomain.name)
                expect(Domain.get(testdomain.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/domains/#{testdomain.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(400)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:malformed_request)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                patch(
                  "/api/v#{api_version}/domains/#{testdomain.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_user_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not update the domain' do
                prev_tstamp = testdomain.updated_at

                patch(
                  "/api/v#{api_version}/domains/#{testdomain.id}",
                  invalid_user_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Domain.get(testdomain.id).name).to eq(testdomain.name)
                expect(Domain.get(testdomain.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/domains/#{testdomain.id}",
                  invalid_user_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:invalid_request)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                patch(
                  "/api/v#{api_version}/domains/#{testdomain.id}",
                  invalid_user_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_domain) }

              it 'does not update the domain' do
                prev_tstamp = testdomain.updated_at

                patch(
                  "/api/v#{api_version}/domains/#{testdomain.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Domain.get(testdomain.id).name).to eq(testdomain.name)
                expect(Domain.get(testdomain.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/domains/#{testdomain.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:invalid_domain)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                patch(
                  "/api/v#{api_version}/domains/#{testdomain.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with a resource conflict' do
              let(:resource_conflict) do
                attributes_for(:domain,
                               name: 'existing.domain')
              end
              before(:each) do
                create(:domain, name: 'existing.domain')
              end
              let!(:conflict_domain) do
                create(:domain, name: 'conflict.domain')
              end

              it 'does not update the domain' do
                prev_tstamp = conflict_domain.updated_at

                patch(
                  "/api/v#{api_version}/domains/#{conflict_domain.id}",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Domain.get(conflict_domain.id).name).to eq(
                  conflict_domain.name
                )
                expect(Domain.get(conflict_domain.id).updated_at).to eq(
                  prev_tstamp
                )
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/domains/#{conflict_domain.id}",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(409)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:resource_conflict)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                patch(
                  "/api/v#{api_version}/domains/#{conflict_domain.id}",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end

          context 'operation failed' do
            it 'returns an API Error' do
              invincibledomain = create(:domain, name: 'invincible.org')
              allow(Domain).to receive(
                :get
              ).with(
                invincibledomain.id.to_s
              ).and_return(
                invincibledomain
              )
              allow(invincibledomain).to receive(:update).and_return(false)
              policy = instance_double('DomainPolicy', update?: true)
              allow(policy).to receive(:update?).and_return(true)
              allow(policy).to receive(:update_with?).and_return(true)
              allow(DomainPolicy).to receive(:new).and_return(policy)

              patch(
                "/api/v#{api_version}/domains/#{invincibledomain.id}",
                attributes_for(:domain, name: 'invincible2.org').to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(last_response.status).to eq(500)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  api_error(ApiErrors.[](:failed_update)).to_json
                )
              )
            end
          end
        end

        describe 'DELETE' do
          it 'authorizes the request by using the policies' do
            expect(Pundit.authorize(testadmin, Domain, :destroy?)).to be_truthy
          end

          it 'deletes the requested domain' do
            id = testdomain.id

            delete(
              "/api/v#{api_version}/domains/#{testdomain.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect(Domain.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            delete(
              "/api/v#{api_version}/domains/#{testdomain.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'operation failed' do
            it 'returns an API Error' do
              invincibledomain = create(:domain, name: 'invincible.org')
              allow(Domain).to receive(
                :get
              ).with(
                invincibledomain.id.to_s
              ).and_return(
                invincibledomain
              )
              allow(invincibledomain).to receive(:destroy).and_return(false)
              policy = instance_double('DomainPolicy', destroy?: true)
              allow(policy).to receive(:destroy?).and_return(true)
              allow(DomainPolicy).to receive(:new).and_return(policy)

              delete(
                "/api/v#{api_version}/domains/#{invincibledomain.id}",
                nil,
                auth_headers_apikey(testadmin.id)
              )

              expect(last_response.status).to eq(500)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  api_error(ApiErrors.[](:failed_delete)).to_json
                )
              )
            end
          end
        end
      end

      context 'by an authenticated but unauthorized user' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:usergroup) { create(:group) }
        let!(:testuser) { create(:user_with_domains) }
        let!(:owner) { create(:user_with_domains) }
        let!(:testdomain) { owner.domains.first }

        describe 'GET all' do
          it 'returns only its own domains' do
            get(
              "/api/v#{api_version}/domains", nil,
              auth_headers_apikey(testuser.id)
            )

            scope = Pundit.policy_scope(testuser, Domain)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testuser.id
              )
            )
          end

          it 'returns a valid JSON object' do
            get(
              "/api/v#{api_version}/domains", nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testdomain, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            get(
              "/api/v#{api_version}/domains/#{testdomain.id}", nil,
              auth_headers_apikey(testuser.id)
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            get(
              "/api/v#{api_version}/domains/#{testdomain.id}", nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'does not authorize the request' do
            expect do
              testdomain.destroy
              Pundit.authorize(testuser, testdomain, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            inexistent = testdomain.id
            testdomain.destroy

            get(
              "/api/v#{api_version}/domains/#{inexistent}", nil,
              auth_headers_apikey(testuser.id)
            )

            expect(last_response.status).to eq(404)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:not_found)).to_json
              )
            )
          end
        end

        describe 'POST' do
          context 'with exhausted quota' do
            let(:testuser) { create(:user_with_exhausted_domain_quota) }
            it 'does not authorize the request' do
              expect do
                Pundit.authorize(testuser, Domain, :create?)
              end.to raise_exception(Pundit::NotAuthorizedError)
            end

            it 'does not create a new domain' do
              count = Domain.all.count

              post(
                "/api/v#{api_version}/domains",
                attributes_for(:domain, name: 'new.org').to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(Domain.all.count).to eq(count)
            end

            it 'returns an API Error' do
              post(
                "/api/v#{api_version}/domains",
                attributes_for(:domain, name: 'new.org').to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(last_response.status).to eq(403)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  api_error(ApiErrors.[](:unauthorized)).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              post(
                "/api/v#{api_version}/domains",
                attributes_for(:domain, name: 'new.org').to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with available quota' do
            let!(:testuser) { create(:user_with_domains) }
            let!(:newdomain) do
              attributes_for(:domain, name: 'new.org', user_id: testuser.id)
            end
            it 'authorizes the request' do
              expect(
                Pundit.authorize(testuser, Domain, :create?)
              ).to be_truthy
              expect(
                Pundit.policy(testuser, Domain).create_with?(newdomain)
              ).to be_truthy
            end

            it 'does create a new domain' do
              count = Domain.all.count

              post(
                "/api/v#{api_version}/domains",
                newdomain.to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(Domain.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new domain' do
              post(
                "/api/v#{api_version}/domains",
                newdomain.to_json,
                auth_headers_apikey(testuser.id)
              )

              new = Domain.last

              expect(last_response.status).to eq(201)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  ApiResponseSuccess.new(status_code: 201,
                                         data: { object: new }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              post(
                "/api/v#{api_version}/domains",
                newdomain.to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with using different user_id in attributes' do
            let(:testuser) { create(:user_with_domains) }
            let(:anotheruser) { create(:user) }

            it 'does not create a new domain' do
              count = Domain.all.count

              post(
                "/api/v#{api_version}/domains",
                attributes_for(:domain,
                               name: 'new.org',
                               user_id: anotheruser.id).to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(Domain.all.count).to eq(count)
            end

            it 'returns an API Error' do
              post(
                "/api/v#{api_version}/domains",
                attributes_for(:domain,
                               name: 'new.org',
                               user_id: anotheruser.id).to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(last_response.status).to eq(403)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  api_error(ApiErrors.[](:unauthorized)).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              post(
                "/api/v#{api_version}/domains",
                attributes_for(:domain,
                               name: 'new.org',
                               user_id: anotheruser.id).to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end
        end

        describe 'PATCH' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testdomain, :update?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not update the domain' do
            updated_attrs = attributes_for(:domain, name: 'foo.org')
            prev_tstamp = testdomain.updated_at

            patch(
              "/api/v#{api_version}/domains/#{testdomain.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect(testdomain.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            updated_attrs = attributes_for(:domain, name: 'foo.org')

            patch(
              "/api/v#{api_version}/domains/#{testdomain.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            updated_attrs = attributes_for(:domain, name: 'foo.org')

            patch(
              "/api/v#{api_version}/domains/#{testdomain.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'DELETE' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testdomain, :destroy?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not delete the domain' do
            delete(
              "/api/v#{api_version}/domains/#{testdomain.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect(Domain.get(testdomain.id)).not_to eq(nil)
            expect(Domain.get(testdomain.id)).to eq(testdomain)
          end

          it 'returns an API Error' do
            delete(
              "/api/v#{api_version}/domains/#{testdomain.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            delete(
              "/api/v#{api_version}/domains/#{testdomain.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end
      end

      context 'by an unauthenticated user' do
        let!(:testdomain) { create(:domain) }

        before(:each) do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testuser) { create(:user) }

        describe 'GET all' do
          it 'returns an an API authentication error' do
            get "/api/v#{api_version}/domains"
            expect(last_response.status).to eq(401)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:authentication_failed)).to_json
              )
            )
          end
        end

        describe 'GET one' do
          it 'returns an an API authentication error' do
            get "/api/v#{api_version}/domains/#{testdomain.id}"
            expect(last_response.status).to eq(401)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:authentication_failed)).to_json
              )
            )
          end
        end

        describe 'GET inexistent record' do
          it 'returns an an API authentication error' do
            inexistent = testdomain.id
            testdomain.destroy
            get "/api/v#{api_version}/domains/#{inexistent}"
            expect(last_response.status).to eq(401)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:authentication_failed)).to_json
              )
            )
          end
        end

        describe 'POST' do
          it 'returns an an API authentication error' do
            post(
              "/api/v#{api_version}/domains",
              'domain' => attributes_for(:domain)
            )
            expect(last_response.status).to eq(401)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:authentication_failed)).to_json
              )
            )
          end
        end

        describe 'PATCH' do
          it 'returns an an API authentication error' do
            testdomain_foo = create(:domain, name: 'foo.org')
            patch(
              "/api/v#{api_version}/domains/#{testdomain_foo.id}",
              'domain' => attributes_for(:domain)
            )
            expect(last_response.status).to eq(401)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:authentication_failed)).to_json
              )
            )
          end
        end

        describe 'DELETE' do
          it 'returns an an API authentication error' do
            delete "/api/v#{api_version}/domains/#{testdomain.id}"
            expect(last_response.status).to eq(401)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:authentication_failed)).to_json
              )
            )
          end
        end
      end
    end
  end
end
