# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

# rubocop:disable Metrics/BlockLength, RSpec/NestedGroups, RSpec/LetSetup
# rubocop:disable RSpec/MultipleExpectations, Security/YAMLLoad
# rubocop:disable RSpec/EmptyLineAfterFinalLet
# rubocop:disable RSpec/PredicateMatcher, RSpec/HookArgument, RSpec/ScatteredLet
describe 'VHost-API MailForwarding Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w[1]

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      let(:baseurl) { "/api/v#{api_version}" }
      context 'when by an admin' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:testmailforwarding) { create(:mailforwarding) }
        let!(:testadmin) { create(:admin, password: 'secret') }

        describe 'GET all' do
          it 'authorizes (policies) and returns an array of mailforwardings' do
            get(
              "#{baseurl}/mailforwardings", nil,
              auth_headers_apikey(testadmin.id)
            )

            scope = Pundit.policy_scope(testadmin, MailForwarding)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testadmin.id
              )
            )
          end

          it 'returns valid JSON' do
            get(
              "#{baseurl}/mailforwardings", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'authorizes the request by using the policies' do
            expect(
              Pundit.authorize(testadmin, testmailforwarding, :show?)
            ).to be_truthy
          end

          it 'returns the mailforwarding' do
            get(
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}", nil,
              auth_headers_apikey(testadmin.id)
            )

            @user = testadmin
            expect(last_response.body).to eq(
              spec_authorized_resource(object: testmailforwarding,
                                       user: testadmin)
            )
          end

          it 'returns valid JSON' do
            get(
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'returns an API Error' do
            inexistent = testmailforwarding.id
            testmailforwarding.destroy

            get(
              "#{baseurl}/mailforwardings/#{inexistent}", nil,
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
          let(:mailaccount) do
            create(:mailaccount,
                   email: "admin@#{domain.name}",
                   domain_id: domain.id)
          end
          let(:address) { 'new@new.org' }
          let(:new_attributes) do
            attributes_for(:mailforwarding,
                           address: address,
                           domain_id: domain.id)
          end

          context 'when with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(
                Pundit.authorize(testadmin, MailForwarding, :create?)
              ).to be_truthy
            end

            it 'creates a new mailforwarding' do
              count = MailForwarding.all.count

              post(
                "#{baseurl}/mailforwardings",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(MailForwarding.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new mailforwarding' do
              post(
                "#{baseurl}/mailforwardings",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = MailForwarding.last

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
                "#{baseurl}/mailforwardings",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new mailforwarding' do
              post(
                "#{baseurl}/mailforwardings",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = MailForwarding.last

              expect(last_response.location).to eq(
                "http://example.org#{baseurl}/mailforwardings/#{new.id}"
              )
            end
          end

          context 'when with malformed request data' do
            context 'when invalid json' do
              let(:invalid_json) { '{ , address: \'foo, enabled:true}' }

              it 'does not create a new mailforwarding' do
                count = MailForwarding.all.count

                post(
                  "#{baseurl}/mailforwardings",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailForwarding.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "#{baseurl}/mailforwardings",
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

              it 'shows a format error message when using verbose param' do
                error_msg = '859: unexpected token at '
                error_msg += '\'{ , address: \'foo, enabled:true}\''
                post(
                  "#{baseurl}/mailforwardings?verbose",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(400)
                expect(last_response.body).to eq(
                  spec_api_error(
                    ApiErrors.[](:malformed_request),
                    errors: { format: error_msg }
                  )
                )
              end

              it 'returns a valid JSON object' do
                post(
                  "#{baseurl}/mailforwardings",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when invalid attributes' do
              let(:invalid_mailforwarding_attrs) do
                { foo: 'bar', disabled: 1234 }
              end

              it 'does not create a new mailforwarding' do
                count = MailForwarding.all.count

                post(
                  "#{baseurl}/mailforwardings",
                  invalid_mailforwarding_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailForwarding.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "#{baseurl}/mailforwardings",
                  invalid_mailforwarding_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:invalid_request)).to_json
                  )
                )
              end

              it 'shows an argument error message when using verbose param' do
                error_msg = 'The attribute \'foo\' is not accessible in '
                error_msg += 'MailForwarding'
                post(
                  "#{baseurl}/mailforwardings?verbose",
                  invalid_mailforwarding_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_api_error(
                    ApiErrors.[](:invalid_request),
                    errors: { argument: error_msg }
                  )
                )
              end

              it 'returns a valid JSON object' do
                post(
                  "#{baseurl}/mailforwardings",
                  invalid_mailforwarding_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_mailforwarding) }

              it 'does not create a new mailforwarding' do
                count = MailForwarding.all.count

                post(
                  "#{baseurl}/mailforwardings",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailForwarding.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "#{baseurl}/mailforwardings",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:invalid_request)).to_json
                  )
                )
              end

              it 'shows a validate error message when using validate param' do
                errors = {
                  validation: [
                    { field: 'address',
                      errors: ['Address must not be blank',
                               'Address has an invalid format'] },
                    { field: 'destinations',
                      errors: ['Destinations must not be blank',
                               'Invalid email within destinations'] }
                  ]
                }

                post(
                  "#{baseurl}/mailforwardings?validate",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_api_error(
                    ApiErrors.[](:invalid_request),
                    errors: errors
                  )
                )
              end

              it 'returns a valid JSON object' do
                post(
                  "#{baseurl}/mailforwardings",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when with a resource conflict' do
              let(:domain) { create(:domain, name: 'mailforwarding.org') }
              let(:mailaccount) do
                create(:mailaccount,
                       email: 'foobar@mailforwarding.org',
                       domain_id: domain.id)
              end

              before(:each) do
                create(:mailforwarding,
                       address: 'existing@mailforwarding.org',
                       domain_id: domain.id)
              end
              let(:resource_conflict) do
                attributes_for(:mailforwarding,
                               address: 'existing@mailforwarding.org',
                               domain_id: domain.id)
              end

              it 'does not create a new mailforwarding' do
                count = MailForwarding.all.count

                post(
                  "#{baseurl}/mailforwardings",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailForwarding.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "#{baseurl}/mailforwardings",
                  resource_conflict.to_json,
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
                post(
                  "#{baseurl}/mailforwardings",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end
        end

        describe 'PATCH' do
          context 'when with valid attributes' do
            let(:domain) { testmailforwarding.domain }
            let(:mailaccount) do
              create(:mailaccount,
                     email: "example@#{domain.name}",
                     domain_id: domain.id)
            end
            let(:mailaccount2) do
              create(:mailaccount,
                     email: "herpderp@#{domain.name}",
                     domain_id: domain.id)
            end
            let(:mailaccount3) do
              create(:mailaccount,
                     email: "user@#{domain.name}",
                     domain_id: domain.id)
            end
            let(:destinations) do
              [mailaccount.id, mailaccount2.id, mailaccount3.id]
            end
            let(:upd_attrs) do
              attributes_for(
                :mailforwarding,
                address: "foo@#{domain.name}"
              )
            end
            it 'updates an existing mailforwarding with new values' do
              prev_tstamp = testmailforwarding.updated_at

              patch(
                "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(
                MailForwarding.get(testmailforwarding.id).address
              ).to eq(upd_attrs[:address])
              expect(
                MailForwarding.get(testmailforwarding.id).updated_at
              ).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated mailforwarding' do
              patch(
                "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              upd_forwarding = MailForwarding.get(testmailforwarding.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  ApiResponseSuccess.new(
                    status_code: 200,
                    data: { object: upd_forwarding }
                  ).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              patch(
                "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'when with malformed request data' do
            context 'when invalid json' do
              let(:invalid_json) { '{ , address: \'foo, enabled:true}' }

              it 'does not update the mailforwarding' do
                prev_tstamp = testmailforwarding.updated_at

                patch(
                  "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  MailForwarding.get(testmailforwarding.id).address
                ).to eq(testmailforwarding.address)
                expect(
                  MailForwarding.get(testmailforwarding.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
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

              it 'shows a format error message when using verbose param' do
                error_msg = '859: unexpected token at '
                error_msg += '\'{ , address: \'foo, enabled:true}\''
                patch(
                  "#{baseurl}/mailforwardings/#{testmailforwarding.id}?verbose",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(400)
                expect(last_response.body).to eq(
                  spec_api_error(
                    ApiErrors.[](:malformed_request),
                    errors: { format: error_msg }
                  )
                )
              end

              it 'returns a valid JSON object' do
                patch(
                  "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when invalid attributes' do
              let(:invalid_mailforwarding_attrs) do
                { foo: 'bar', disabled: 1234 }
              end

              it 'does not update the mailforwarding' do
                prev_tstamp = testmailforwarding.updated_at

                patch(
                  "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
                  invalid_mailforwarding_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  MailForwarding.get(testmailforwarding.id).address
                ).to eq(testmailforwarding.address)
                expect(
                  MailForwarding.get(testmailforwarding.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
                  invalid_mailforwarding_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:invalid_request)).to_json
                  )
                )
              end

              it 'shows an argument error message when using verbose param' do
                error_msg = 'The attribute \'foo\' is not accessible in '
                error_msg += 'MailForwarding'
                patch(
                  "#{baseurl}/mailforwardings/#{testmailforwarding.id}?verbose",
                  invalid_mailforwarding_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_api_error(
                    ApiErrors.[](:invalid_request),
                    errors: { argument: error_msg }
                  )
                )
              end

              it 'returns a valid JSON object' do
                patch(
                  "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
                  invalid_mailforwarding_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_mailforwarding) }

              it 'does not update the mailforwarding' do
                prev_tstamp = testmailforwarding.updated_at

                patch(
                  "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  MailForwarding.get(testmailforwarding.id).address
                ).to eq(testmailforwarding.address)
                expect(
                  MailForwarding.get(testmailforwarding.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:invalid_request)).to_json
                  )
                )
              end

              it 'shows a validate error message when using validate param' do
                errors = {
                  validation: [
                    { field: 'address',
                      errors: ['Address must not be blank',
                               'Address has an invalid format'] },
                    { field: 'destinations',
                      errors: ['Destinations must not be blank',
                               'Invalid email within destinations'] }
                  ]
                }

                ctrl_url = "#{baseurl}/mailforwardings"
                patch(
                  "#{ctrl_url}/#{testmailforwarding.id}?validate",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_api_error(
                    ApiErrors.[](:invalid_request),
                    errors: errors
                  )
                )
              end

              it 'returns a valid JSON object' do
                patch(
                  "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when with a resource conflict' do
              let(:domain) { create(:domain, name: 'mailforwarding.org') }
              let(:resource_conflict) do
                attributes_for(:mailforwarding,
                               address: 'existing@mailforwarding.org',
                               domain_id: domain.id)
              end
              before(:each) do
                create(:mailforwarding,
                       address: 'existing@mailforwarding.org',
                       domain_id: domain.id)
              end
              let(:conflict) do
                create(:mailforwarding,
                       address: 'conflict@mailforwarding.org',
                       domain_id: domain.id)
              end

              it 'does not update the mailforwarding' do
                prev_tstamp = conflict.updated_at

                patch(
                  "#{baseurl}/mailforwardings/#{conflict.id}",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailForwarding.get(conflict.id).address).to eq(
                  conflict.address
                )
                expect(MailForwarding.get(conflict.id).updated_at).to eq(
                  prev_tstamp
                )
              end

              it 'returns an API Error' do
                patch(
                  "#{baseurl}/mailforwardings/#{conflict.id}",
                  resource_conflict.to_json,
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
                  "#{baseurl}/mailforwardings/#{conflict.id}",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end

          context 'when operation failed' do
            let(:domain) { create(:domain, name: 'invincible.de') }

            it 'returns an API Error' do
              invincible = create(:mailforwarding,
                                  address: 'foo@invincible.de',
                                  domain_id: domain.id)
              allow(MailForwarding).to receive(
                :get
              ).with(
                invincible.id.to_s
              ).and_return(
                invincible
              )
              allow(invincible).to receive(:update).and_return(false)
              policy = instance_double('MailForwardingPolicy', update?: true)
              allow(policy).to receive(:update?).and_return(true)
              allow(policy).to receive(:update_with?).and_return(true)
              allow(MailForwardingPolicy).to receive(:new).and_return(policy)

              patch(
                "#{baseurl}/mailforwardings/#{invincible.id}",
                attributes_for(:mailforwarding,
                               address: 'f2@invincible.de').to_json,
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
              Pundit.authorize(testadmin, MailForwarding, :destroy?)
            ).to be_truthy
          end

          it 'deletes the requested mailforwarding' do
            id = testmailforwarding.id

            delete(
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect(MailForwarding.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            delete(
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'when operation failed' do
            it 'returns an API Error' do
              invincible = create(:mailforwarding,
                                  address: 'foo@invincible.org')
              allow(MailForwarding).to receive(
                :get
              ).with(
                invincible.id.to_s
              ).and_return(
                invincible
              )
              allow(invincible).to receive(:destroy).and_return(false)
              policy = instance_double('MailForwardingPolicy', destroy?: true)
              allow(policy).to receive(:destroy?).and_return(true)
              allow(MailForwardingPolicy).to receive(:new).and_return(policy)

              delete(
                "#{baseurl}/mailforwardings/#{invincible.id}",
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

      context 'when by an authenticated but unauthorized user' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:usergroup) { create(:group) }
        let!(:testuser) { create(:user_with_mailforwardings) }
        let!(:owner) { create(:user_with_mailforwardings) }
        let!(:testmailforwarding) do
          MailForwarding.first(domain_id: owner.domains.first.id)
        end

        describe 'GET all' do
          it 'returns only its own mailforwardings' do
            get(
              "#{baseurl}/mailforwardings", nil,
              auth_headers_apikey(testuser.id)
            )

            scope = Pundit.policy_scope(testuser, MailForwarding)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testuser.id
              )
            )
          end

          it 'returns a valid JSON object' do
            get(
              "#{baseurl}/mailforwardings", nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testmailforwarding, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            get(
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
              nil, auth_headers_apikey(testuser.id)
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
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
              nil, auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'does not authorize the request' do
            expect do
              testmailforwarding.destroy
              Pundit.authorize(testuser, testmailforwarding, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            inexistent = testmailforwarding.id
            testmailforwarding.destroy

            get(
              "#{baseurl}/mailforwardings/#{inexistent}", nil,
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
          context 'when with exhausted quota' do
            let(:testuser) { create(:user_with_exhausted_mailforwarding_quota) }
            it 'does not authorize the request' do
              expect do
                Pundit.authorize(testuser, MailForwarding, :create?)
              end.to raise_exception(Pundit::NotAuthorizedError)
            end

            it 'does not create a new mailforwarding' do
              count = MailForwarding.all.count

              post(
                "#{baseurl}/mailforwardings",
                attributes_for(:mailforwarding, mail: 'new@new.org').to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(MailForwarding.all.count).to eq(count)
            end

            it 'returns an API Error' do
              post(
                "#{baseurl}/mailforwardings",
                attributes_for(:mailforwarding, address: 'new@new.org').to_json,
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
                "#{baseurl}/mailforwardings",
                attributes_for(:mailforwarding, address: 'new@new.org').to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'when with available quota' do
            let(:testuser) { create(:user_with_mailforwardings) }
            let(:domain) { testuser.domains.first }
            let(:new) do
              attributes_for(:mailforwarding,
                             address: "new@#{domain.name}",
                             domain_id: domain.id)
            end

            it 'authorizes the request' do
              expect(
                Pundit.authorize(testuser, MailForwarding, :create?)
              ).to be_truthy
              expect(
                Pundit.policy(testuser, MailForwarding).create_with?(new)
              ).to be_truthy
            end

            it 'does create a new mailforwarding' do
              count = MailForwarding.all.count

              post(
                "#{baseurl}/mailforwardings",
                new.to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(MailForwarding.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new mailforwarding' do
              post(
                "#{baseurl}/mailforwardings",
                new.to_json,
                auth_headers_apikey(testuser.id)
              )

              new = MailForwarding.last

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
                "#{baseurl}/mailforwardings",
                new.to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'when with using different user_id in attributes' do
            let(:testuser) { create(:user_with_mailforwardings) }
            let(:anotheruser) { create(:user_with_mailaccounts) }
            let(:new_attrs) do
              attributes_for(
                :mailforwarding,
                name: "foo@#{anotheruser.domains.first.name}",
                domain_id: anotheruser.domains.first.id
              )
            end

            it 'does not create a new mailforwarding' do
              count = MailForwarding.all.count

              post(
                "#{baseurl}/mailforwardings",
                new_attrs.to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(MailForwarding.all.count).to eq(count)
            end

            it 'returns an API Error' do
              clear_cookies
              post(
                "#{baseurl}/mailforwardings",
                new_attrs.to_json,
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
                "#{baseurl}/mailforwardings",
                new_attrs.to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end
        end

        describe 'PATCH' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testmailforwarding, :update?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not update the mailforwarding' do
            updated_attrs = attributes_for(:mailforwarding,
                                           address: 'foo@foo.org')
            prev_tstamp = testmailforwarding.updated_at

            patch(
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect(testmailforwarding.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            updated_attrs = attributes_for(:mailforwarding,
                                           address: 'foo@foo.org')

            patch(
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
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
            updated_attrs = attributes_for(:mailforwarding,
                                           address: 'foo@foo.org')

            patch(
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'DELETE' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testmailforwarding, :destroy?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not delete the mailforwarding' do
            delete(
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect(MailForwarding.get(testmailforwarding.id)).not_to eq(nil)
            expect(MailForwarding.get(testmailforwarding.id)).to eq(
              testmailforwarding
            )
          end

          it 'returns an API Error' do
            delete(
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
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
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end
      end

      context 'when by an unauthenticated user' do
        let!(:testmailforwarding) { create(:mailforwarding) }

        before(:each) do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testuser) { create(:user) }

        describe 'GET all' do
          it 'returns an an API authentication error' do
            get "#{baseurl}/mailforwardings"
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
            get "#{baseurl}/mailforwardings/#{testmailforwarding.id}"
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
            inexistent = testmailforwarding.id
            testmailforwarding.destroy
            get "#{baseurl}/mailforwardings/#{inexistent}"
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
              "#{baseurl}/mailforwardings",
              'mailforwarding' => attributes_for(:mailforwarding)
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
            testmailforwarding_foo = create(:mailforwarding,
                                            address: 'foo@foo.org')
            patch(
              "#{baseurl}/mailforwardings/#{testmailforwarding_foo.id}",
              'mailforwarding' => attributes_for(:mailforwarding)
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
            delete(
              "#{baseurl}/mailforwardings/#{testmailforwarding.id}"
            )
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
# rubocop:enable Metrics/BlockLength, RSpec/NestedGroups, RSpec/LetSetup
# rubocop:enable RSpec/MultipleExpectations, Security/YAMLLoad
# rubocop:enable RSpec/EmptyLineAfterFinalLet
# rubocop:enable RSpec/PredicateMatcher, RSpec/HookArgument, RSpec/ScatteredLet
