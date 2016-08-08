# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API MailAccount Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w(1)

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      context 'by an admin user' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:testmailaccount) { create(:mailaccount) }
        let!(:testadmin) { create(:admin, password: 'secret') }

        describe 'GET all' do
          it 'authorizes (policies) and returns an array of mailaccounts' do
            get(
              "/api/v#{api_version}/mailaccounts", nil,
              auth_headers_apikey(testadmin.id)
            )

            scope = Pundit.policy_scope(testadmin, MailAccount)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testadmin.id
              )
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/mailaccounts", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'authorizes the request by using the policies' do
            expect(
              Pundit.authorize(testadmin, testmailaccount, :show?)
            ).to be_truthy
          end

          it 'returns the mailaccount' do
            get(
              "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}", nil,
              auth_headers_apikey(testadmin.id)
            )

            @user = testadmin
            expect(last_response.body).to eq(
              spec_authorized_resource(object: testmailaccount, user: testadmin)
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'returns an API Error' do
            inexistent = testmailaccount.id
            testmailaccount.destroy

            get(
              "/api/v#{api_version}/mailaccounts/#{inexistent}", nil,
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
          let(:domain) do
            create(:domain, name: 'new.org', user_id: testadmin.id)
          end
          let(:email) { 'new@new.org' }
          let(:new_attributes) do
            attributes_for(:mailaccount,
                           email: email,
                           domain_id: domain.id)
          end

          context 'with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(
                Pundit.authorize(testadmin, MailAccount, :create?)
              ).to be_truthy
            end

            it 'creates a new mailaccount' do
              count = MailAccount.all.count

              post(
                "/api/v#{api_version}/mailaccounts",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(MailAccount.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new mailaccount' do
              post(
                "/api/v#{api_version}/mailaccounts",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = MailAccount.last

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
                "/api/v#{api_version}/mailaccounts",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new mailaccount' do
              post(
                "/api/v#{api_version}/mailaccounts",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = MailAccount.last

              expect(last_response.location).to eq(
                "http://example.org/api/v#{api_version}/mailaccounts/#{new.id}"
              )
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{ , email: \'foo, enabled: true }' }

              it 'does not create a new mailaccount' do
                count = MailAccount.all.count

                post(
                  "/api/v#{api_version}/mailaccounts",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailAccount.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/mailaccounts",
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
                  "/api/v#{api_version}/mailaccounts",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_mailaccount_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not create a new mailaccount' do
                count = MailAccount.all.count

                post(
                  "/api/v#{api_version}/mailaccounts",
                  invalid_mailaccount_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailAccount.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/mailaccounts",
                  invalid_mailaccount_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:invalid_email)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                post(
                  "/api/v#{api_version}/mailaccounts",
                  invalid_mailaccount_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_mailaccount) }

              it 'does not create a new mailaccount' do
                count = MailAccount.all.count

                post(
                  "/api/v#{api_version}/mailaccounts",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailAccount.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/mailaccounts",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:invalid_email)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                post(
                  "/api/v#{api_version}/mailaccounts",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with a resource conflict' do
              let(:domain) { create(:domain, name: 'mailaccount.org') }

              before(:each) do
                create(:mailaccount,
                       email: 'existing@mailaccount.org',
                       domain_id: domain.id)
              end
              let(:resource_conflict) do
                attributes_for(
                  :mailaccount,
                  email: 'existing@mailaccount.org',
                  password: 'foobar',
                  domain_id: domain.id
                )
              end

              it 'does not create a new mailaccount' do
                count = MailAccount.all.count

                post(
                  "/api/v#{api_version}/mailaccounts",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailAccount.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/mailaccounts",
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
                post(
                  "/api/v#{api_version}/mailaccounts",
                  resource_conflict.to_json,
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
              expect(
                Pundit.authorize(testadmin, MailAccount, :create?)
              ).to be_truthy
            end

            it 'updates an existing mailaccount with new values' do
              updated_attrs = attributes_for(
                :mailaccount,
                email: "foo@#{testmailaccount.domain.name}"
              )
              prev_tstamp = testmailaccount.updated_at

              patch(
                "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(
                MailAccount.get(testmailaccount.id).email
              ).to eq(updated_attrs[:email])
              expect(
                MailAccount.get(testmailaccount.id).updated_at
              ).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated mailaccount' do
              updated_attrs = attributes_for(
                :mailaccount,
                email: "foo@#{testmailaccount.domain.name}"
              )

              patch(
                "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              upd_acc = MailAccount.get(testmailaccount.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  ApiResponseSuccess.new(status_code: 200,
                                         data: { object: upd_acc }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              updated_attrs = attributes_for(:mailaccount, email: 'foo@foo.org')

              patch(
                "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{ , email: \'foo, enabled: true }' }

              it 'does not update the mailaccount' do
                prev_tstamp = testmailaccount.updated_at

                patch(
                  "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  MailAccount.get(testmailaccount.id).email
                ).to eq(testmailaccount.email)
                expect(
                  MailAccount.get(testmailaccount.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
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
                  "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_user_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not update the mailaccount' do
                prev_tstamp = testmailaccount.updated_at

                patch(
                  "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
                  invalid_user_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  MailAccount.get(testmailaccount.id).email
                ).to eq(testmailaccount.email)
                expect(
                  MailAccount.get(testmailaccount.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
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
                  "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
                  invalid_user_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_mailaccount) }

              it 'does not update the mailaccount' do
                prev_tstamp = testmailaccount.updated_at

                patch(
                  "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  MailAccount.get(testmailaccount.id).email
                ).to eq(testmailaccount.email)
                expect(
                  MailAccount.get(testmailaccount.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:invalid_email)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                patch(
                  "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with a resource conflict' do
              let(:domain) { create(:domain, name: 'mailaccount.org') }
              let(:resource_conflict) do
                attributes_for(:mailaccount,
                               email: 'existing@mailaccount.org',
                               domain_id: domain.id)
              end
              before(:each) do
                create(:mailaccount,
                       email: 'existing@mailaccount.org',
                       domain_id: domain.id)
              end
              let(:conflict) do
                create(:mailaccount,
                       email: 'conflict@mailaccount.org',
                       domain_id: domain.id)
              end

              it 'does not update the mailaccount' do
                prev_tstamp = conflict.updated_at

                patch(
                  "/api/v#{api_version}/mailaccounts/#{conflict.id}",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailAccount.get(conflict.id).email).to eq(
                  conflict.email
                )
                expect(MailAccount.get(conflict.id).updated_at).to eq(
                  prev_tstamp
                )
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/mailaccounts/#{conflict.id}",
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
                  "/api/v#{api_version}/mailaccounts/#{conflict.id}",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end

          context 'operation failed' do
            let(:domain) { create(:domain, name: 'invincible.de') }

            it 'returns an API Error' do
              invincible = create(:mailaccount,
                                  email: 'foo@invincible.de',
                                  domain_id: domain.id)
              allow(MailAccount).to receive(
                :get
              ).with(
                invincible.id.to_s
              ).and_return(
                invincible
              )
              allow(invincible).to receive(:update).and_return(false)
              policy = instance_double('MailAccountPolicy', update?: true)
              allow(policy).to receive(:update?).and_return(true)
              allow(policy).to receive(:update_with?).and_return(true)
              allow(MailAccountPolicy).to receive(:new).and_return(policy)

              patch(
                "/api/v#{api_version}/mailaccounts/#{invincible.id}",
                attributes_for(:mailaccount, email: 'f2@invincible.de').to_json,
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
            expect(
              Pundit.authorize(testadmin, MailAccount, :destroy?)
            ).to be_truthy
          end

          it 'deletes the requested mailaccount' do
            id = testmailaccount.id

            delete(
              "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect(MailAccount.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            delete(
              "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'operation failed' do
            it 'returns an API Error' do
              invincible = create(:mailaccount,
                                  email: 'foo@invincible.org')
              allow(MailAccount).to receive(
                :get
              ).with(
                invincible.id.to_s
              ).and_return(
                invincible
              )
              allow(invincible).to receive(:destroy).and_return(false)
              policy = instance_double('MailAccountPolicy', destroy?: true)
              allow(policy).to receive(:destroy?).and_return(true)
              allow(MailAccountPolicy).to receive(:new).and_return(policy)

              delete(
                "/api/v#{api_version}/mailaccounts/#{invincible.id}",
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
        let!(:testuser) { create(:user_with_mailaccounts) }
        let!(:owner) { create(:user_with_mailaccounts) }
        let!(:testmailaccount) do
          MailAccount.first(domain_id: owner.domains.first.id)
        end

        describe 'GET all' do
          it 'returns only its own mailaccounts' do
            get(
              "/api/v#{api_version}/mailaccounts", nil,
              auth_headers_apikey(testuser.id)
            )

            scope = Pundit.policy_scope(testuser, MailAccount)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testuser.id
              )
            )
          end

          it 'returns a valid JSON object' do
            get(
              "/api/v#{api_version}/mailaccounts", nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testmailaccount, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            get(
              "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}", nil,
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
              "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}", nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'does not authorize the request' do
            expect do
              testmailaccount.destroy
              Pundit.authorize(testuser, testmailaccount, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            inexistent = testmailaccount.id
            testmailaccount.destroy

            get(
              "/api/v#{api_version}/mailaccounts/#{inexistent}", nil,
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
            let(:testuser) { create(:user_with_exhausted_mailaccount_quota) }
            it 'does not authorize the request' do
              expect do
                Pundit.authorize(testuser, MailAccount, :create?)
              end.to raise_exception(Pundit::NotAuthorizedError)
            end

            it 'does not create a new mailaccount' do
              count = MailAccount.all.count

              post(
                "/api/v#{api_version}/mailaccounts",
                attributes_for(:mailaccount, mail: 'new@new.org').to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(MailAccount.all.count).to eq(count)
            end

            it 'returns an API Error' do
              post(
                "/api/v#{api_version}/mailaccounts",
                attributes_for(:mailaccount, email: 'new@new.org').to_json,
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
                "/api/v#{api_version}/mailaccounts",
                attributes_for(:mailaccount, email: 'new@new.org').to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with available quota' do
            let(:testuser) { create(:user_with_mailaccounts) }
            let(:domain) { testuser.domains.first }
            let(:new) do
              attributes_for(:mailaccount,
                             email: "new@#{domain.name}",
                             domain_id: domain.id)
            end

            it 'authorizes the request' do
              expect(
                Pundit.authorize(testuser, MailAccount, :create?)
              ).to be_truthy
              expect(
                Pundit.policy(testuser, MailAccount).create_with?(new)
              ).to be_truthy
            end

            it 'does create a new mailaccount' do
              count = MailAccount.all.count

              post(
                "/api/v#{api_version}/mailaccounts",
                new.to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(MailAccount.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new mailaccount' do
              post(
                "/api/v#{api_version}/mailaccounts",
                new.to_json,
                auth_headers_apikey(testuser.id)
              )

              new = MailAccount.last

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
                "/api/v#{api_version}/mailaccounts",
                new.to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with using different user_id in attributes' do
            let(:testuser) { create(:user_with_mailaccounts) }
            let(:anotheruser) { create(:user_with_domains) }

            it 'does not create a new mailaccount' do
              count = MailAccount.all.count

              post(
                "/api/v#{api_version}/mailaccounts",
                attributes_for(:mailaccount,
                               name: 'new@new.org',
                               domain_id: anotheruser.domains.first.id).to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(MailAccount.all.count).to eq(count)
            end

            it 'returns an API Error' do
              post(
                "/api/v#{api_version}/mailaccounts",
                attributes_for(:mailaccount,
                               name: 'new@new.org',
                               domain_id: anotheruser.domains.first.id).to_json,
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
                "/api/v#{api_version}/mailaccounts",
                attributes_for(:mailaccount,
                               name: 'new@new.org',
                               domain_id: anotheruser.domains.first.id).to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end
        end

        describe 'PATCH' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testmailaccount, :update?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not update the mailaccount' do
            updated_attrs = attributes_for(:mailaccount, email: 'foo@foo.org')
            prev_tstamp = testmailaccount.updated_at

            patch(
              "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect(testmailaccount.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            updated_attrs = attributes_for(:mailaccount, email: 'foo@foo.org')

            patch(
              "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
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
            updated_attrs = attributes_for(:mailaccount, email: 'foo@foo.org')

            patch(
              "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'DELETE' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testmailaccount, :destroy?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not delete the mailaccount' do
            delete(
              "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect(MailAccount.get(testmailaccount.id)).not_to eq(nil)
            expect(MailAccount.get(testmailaccount.id)).to eq(testmailaccount)
          end

          it 'returns an API Error' do
            delete(
              "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
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
              "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end
      end

      context 'by an unauthenticated user' do
        let!(:testmailaccount) { create(:mailaccount) }

        before(:each) do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testuser) { create(:user) }

        describe 'GET all' do
          it 'returns an an API authentication error' do
            get "/api/v#{api_version}/mailaccounts"
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
            get "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}"
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
            inexistent = testmailaccount.id
            testmailaccount.destroy
            get "/api/v#{api_version}/mailaccounts/#{inexistent}"
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
              "/api/v#{api_version}/mailaccounts",
              'mailaccount' => attributes_for(:mailaccount)
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
            testmailaccount_foo = create(:mailaccount, email: 'foo@foo.org')
            patch(
              "/api/v#{api_version}/mailaccounts/#{testmailaccount_foo.id}",
              'mailaccount' => attributes_for(:mailaccount)
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
            delete "/api/v#{api_version}/mailaccounts/#{testmailaccount.id}"
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
