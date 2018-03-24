# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

# rubocop:disable Metrics/BlockLength, RSpec/NestedGroups, RSpec/LetSetup
# rubocop:disable RSpec/MultipleExpectations, Security/YAMLLoad
# rubocop:disable RSpec/PredicateMatcher, RSpec/ScatteredLet
describe 'VHost-API MailAlias Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w[1]

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      context 'when by an admin' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:testmailalias) { create(:mailalias) }
        let!(:testadmin) { create(:admin, password: 'secret') }

        describe 'GET all' do
          it 'authorizes (policies) and returns an array of mailaliases' do
            get(
              "/api/v#{api_version}/mailaliases", nil,
              auth_headers_apikey(testadmin.id)
            )

            scope = Pundit.policy_scope(testadmin, MailAlias)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testadmin.id
              )
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/mailaliases", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'authorizes the request by using the policies' do
            expect(
              Pundit.authorize(testadmin, testmailalias, :show?)
            ).to be_truthy
          end

          it 'returns the mailalias' do
            get(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}", nil,
              auth_headers_apikey(testadmin.id)
            )

            @user = testadmin
            expect(last_response.body).to eq(
              spec_authorized_resource(object: testmailalias, user: testadmin)
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'returns an API Error' do
            inexistent = testmailalias.id
            testmailalias.destroy

            get(
              "/api/v#{api_version}/mailaliases/#{inexistent}", nil,
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
            attributes_for(:mailalias,
                           address: address,
                           domain_id: domain.id,
                           dest: [mailaccount.id])
          end

          context 'when with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(
                Pundit.authorize(testadmin, MailAlias, :create?)
              ).to be_truthy
            end

            it 'creates a new mailalias' do
              count = MailAlias.all.count

              post(
                "/api/v#{api_version}/mailaliases",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(MailAlias.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new mailalias' do
              post(
                "/api/v#{api_version}/mailaliases",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = MailAlias.last

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
                "/api/v#{api_version}/mailaliases",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new mailalias' do
              post(
                "/api/v#{api_version}/mailaliases",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = MailAlias.last

              expect(last_response.location).to eq(
                "http://example.org/api/v#{api_version}/mailaliases/#{new.id}"
              )
            end
          end

          context 'when with malformed request data' do
            context 'when invalid json' do
              let(:invalid_json) { '{ , address: \'foo, enabled:true}' }

              it 'does not create a new mailalias' do
                count = MailAlias.all.count

                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailAlias.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/mailaliases",
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
                error_msg = '784: unexpected token at '
                error_msg += '\'{ , address: \'foo, enabled:true}\''
                post(
                  "/api/v#{api_version}/mailaliases?verbose",
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
                  "/api/v#{api_version}/mailaliases",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when invalid attributes' do
              let(:invalid_mailalias_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not create a new mailalias' do
                count = MailAlias.all.count

                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_mailalias_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailAlias.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_mailalias_attrs.to_json,
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
                error_msg += 'MailAlias'
                post(
                  "/api/v#{api_version}/mailaliases?verbose",
                  invalid_mailalias_attrs.to_json,
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
                  "/api/v#{api_version}/mailaliases",
                  invalid_mailalias_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_mailalias) }

              it 'does not create a new mailalias' do
                count = MailAlias.all.count

                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailAlias.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/mailaliases",
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
                               'Address has an invalid format'] }
                  ]
                }

                post(
                  "/api/v#{api_version}/mailaliases?validate",
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
                  "/api/v#{api_version}/mailaliases",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when with a resource conflict' do
              let(:domain) { create(:domain, name: 'mailalias.org') }
              let(:mailaccount) do
                create(:mailaccount,
                       email: 'foobar@mailalias.org',
                       domain_id: domain.id)
              end

              before do
                create(:mailalias,
                       address: 'existing@mailalias.org',
                       domain_id: domain.id)
              end
              let(:resource_conflict) do
                attributes_for(:mailalias,
                               address: 'existing@mailalias.org',
                               domain_id: domain.id,
                               dest: [mailaccount.id])
              end

              it 'does not create a new mailalias' do
                count = MailAlias.all.count

                post(
                  "/api/v#{api_version}/mailaliases",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailAlias.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/mailaliases",
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
                  "/api/v#{api_version}/mailaliases",
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
            let(:domain) { testmailalias.domain }
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
                :mailalias,
                address: "foo@#{domain.name}",
                dest: destinations
              )
            end

            it 'updates an existing mailalias with new values' do
              prev_tstamp = testmailalias.updated_at

              patch(
                "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(
                MailAlias.get(testmailalias.id).address
              ).to eq(upd_attrs[:address])
              expect(
                MailAlias.get(testmailalias.id).updated_at
              ).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated mailalias' do
              patch(
                "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              upd_alias = MailAlias.get(testmailalias.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  ApiResponseSuccess.new(status_code: 200,
                                         data: { object: upd_alias }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              patch(
                "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'when with malformed request data' do
            context 'when invalid json' do
              let(:invalid_json) { '{ , address: \'foo, enabled:true}' }

              it 'does not update the mailalias' do
                prev_tstamp = testmailalias.updated_at

                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  MailAlias.get(testmailalias.id).address
                ).to eq(testmailalias.address)
                expect(
                  MailAlias.get(testmailalias.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
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
                error_msg = '784: unexpected token at '
                error_msg += '\'{ , address: \'foo, enabled:true}\''
                baseurl = "/api/v#{api_version}/mailaliases"
                patch(
                  "#{baseurl}/#{testmailalias.id}?verbose",
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
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when invalid attributes' do
              let(:invalid_mailalias_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not update the mailalias' do
                prev_tstamp = testmailalias.updated_at

                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_mailalias_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  MailAlias.get(testmailalias.id).address
                ).to eq(testmailalias.address)
                expect(
                  MailAlias.get(testmailalias.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_mailalias_attrs.to_json,
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
                error_msg += 'MailAlias'
                baseurl = "/api/v#{api_version}/mailaliases"
                patch(
                  "#{baseurl}/#{testmailalias.id}?verbose",
                  invalid_mailalias_attrs.to_json,
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
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_mailalias_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_mailalias) }

              it 'does not update the mailalias' do
                prev_tstamp = testmailalias.updated_at

                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  MailAlias.get(testmailalias.id).address
                ).to eq(testmailalias.address)
                expect(
                  MailAlias.get(testmailalias.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
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
                               'Address has an invalid format'] }
                  ]
                }

                baseurl = "/api/v#{api_version}/mailaliases"
                patch(
                  "#{baseurl}/#{testmailalias.id}?validate",
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
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when with a resource conflict' do
              let(:domain) { create(:domain, name: 'mailalias.org') }
              let(:resource_conflict) do
                attributes_for(:mailalias,
                               address: 'existing@mailalias.org',
                               domain_id: domain.id)
              end
              before do
                create(:mailalias,
                       address: 'existing@mailalias.org',
                       domain_id: domain.id)
              end
              let(:conflict) do
                create(:mailalias,
                       address: 'conflict@mailalias.org',
                       domain_id: domain.id)
              end

              it 'does not update the mailalias' do
                prev_tstamp = conflict.updated_at

                patch(
                  "/api/v#{api_version}/mailaliases/#{conflict.id}",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(MailAlias.get(conflict.id).address).to eq(
                  conflict.address
                )
                expect(MailAlias.get(conflict.id).updated_at).to eq(
                  prev_tstamp
                )
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/mailaliases/#{conflict.id}",
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
                  "/api/v#{api_version}/mailaliases/#{conflict.id}",
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
              invincible = create(:mailalias,
                                  address: 'foo@invincible.de',
                                  domain_id: domain.id)
              allow(MailAlias).to receive(
                :get
              ).with(
                invincible.id.to_s
              ).and_return(
                invincible
              )
              allow(invincible).to receive(:update).and_return(false)
              policy = instance_double('MailAliasPolicy', update?: true)
              allow(policy).to receive(:update?).and_return(true)
              allow(policy).to receive(:update_with?).and_return(true)
              allow(MailAliasPolicy).to receive(:new).and_return(policy)

              patch(
                "/api/v#{api_version}/mailaliases/#{invincible.id}",
                attributes_for(:mailalias, address: 'f2@invincible.de').to_json,
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
              Pundit.authorize(testadmin, MailAlias, :destroy?)
            ).to be_truthy
          end

          it 'deletes the requested mailalias' do
            id = testmailalias.id

            delete(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect(MailAlias.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            delete(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'when operation failed' do
            it 'returns an API Error' do
              invincible = create(:mailalias,
                                  address: 'foo@invincible.org')
              allow(MailAlias).to receive(
                :get
              ).with(
                invincible.id.to_s
              ).and_return(
                invincible
              )
              allow(invincible).to receive(:destroy).and_return(false)
              policy = instance_double('MailAliasPolicy', destroy?: true)
              allow(policy).to receive(:destroy?).and_return(true)
              allow(MailAliasPolicy).to receive(:new).and_return(policy)

              delete(
                "/api/v#{api_version}/mailaliases/#{invincible.id}",
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
        let!(:testuser) { create(:user_with_mailaliases) }
        let!(:owner) { create(:user_with_mailaliases) }
        let!(:testmailalias) do
          MailAlias.first(domain_id: owner.domains.first.id)
        end

        describe 'GET all' do
          it 'returns only its own mailaliases' do
            get(
              "/api/v#{api_version}/mailaliases", nil,
              auth_headers_apikey(testuser.id)
            )

            scope = Pundit.policy_scope(testuser, MailAlias)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testuser.id
              )
            )
          end

          it 'returns a valid JSON object' do
            get(
              "/api/v#{api_version}/mailaliases", nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testmailalias, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            get(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}", nil,
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
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}", nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'does not authorize the request' do
            expect do
              testmailalias.destroy
              Pundit.authorize(testuser, testmailalias, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            inexistent = testmailalias.id
            testmailalias.destroy

            get(
              "/api/v#{api_version}/mailaliases/#{inexistent}", nil,
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
            let(:testuser) { create(:user_with_exhausted_mailalias_quota) }

            it 'does not authorize the request' do
              expect do
                Pundit.authorize(testuser, MailAlias, :create?)
              end.to raise_exception(Pundit::NotAuthorizedError)
            end

            it 'does not create a new mailalias' do
              count = MailAlias.all.count

              post(
                "/api/v#{api_version}/mailaliases",
                attributes_for(:mailalias, mail: 'new@new.org').to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(MailAlias.all.count).to eq(count)
            end

            it 'returns an API Error' do
              post(
                "/api/v#{api_version}/mailaliases",
                attributes_for(:mailalias, address: 'new@new.org').to_json,
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
                "/api/v#{api_version}/mailaliases",
                attributes_for(:mailalias, address: 'new@new.org').to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'when with available quota' do
            let(:testuser) { create(:user_with_mailaliases) }
            let(:domain) { testuser.domains.first }
            let(:mailaccount) { domain.mail_accounts.first }
            let(:new) do
              attributes_for(:mailalias,
                             address: "new@#{domain.name}",
                             domain_id: domain.id,
                             dest: [mailaccount.id])
            end

            it 'authorizes the request' do
              expect(
                Pundit.authorize(testuser, MailAlias, :create?)
              ).to be_truthy
              expect(
                Pundit.policy(testuser, MailAlias).create_with?(new)
              ).to be_truthy
            end

            it 'does create a new mailalias' do
              count = MailAlias.all.count

              post(
                "/api/v#{api_version}/mailaliases",
                new.to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(MailAlias.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new mailalias' do
              post(
                "/api/v#{api_version}/mailaliases",
                new.to_json,
                auth_headers_apikey(testuser.id)
              )

              new = MailAlias.last

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
                "/api/v#{api_version}/mailaliases",
                new.to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'when with using different user_id in attributes' do
            let(:testuser) { create(:user_with_mailaliases) }
            let(:anotheruser) { create(:user_with_mailaccounts) }
            let(:new_attrs) do
              attributes_for(
                :mailalias,
                name: "foo@#{anotheruser.domains.first.name}",
                domain_id: anotheruser.domains.first.id,
                dest: [anotheruser.domains.first.mail_accounts.first.id]
              )
            end

            it 'does not create a new mailalias' do
              count = MailAlias.all.count

              post(
                "/api/v#{api_version}/mailaliases",
                new_attrs.to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(MailAlias.all.count).to eq(count)
            end

            it 'returns an API Error' do
              clear_cookies
              post(
                "/api/v#{api_version}/mailaliases",
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
                "/api/v#{api_version}/mailaliases",
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
              Pundit.authorize(testuser, testmailalias, :update?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not update the mailalias' do
            updated_attrs = attributes_for(:mailalias, address: 'foo@foo.org')
            prev_tstamp = testmailalias.updated_at

            patch(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect(testmailalias.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            updated_attrs = attributes_for(:mailalias, address: 'foo@foo.org')

            patch(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
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
            updated_attrs = attributes_for(:mailalias, address: 'foo@foo.org')

            patch(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'DELETE' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testmailalias, :destroy?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not delete the mailalias' do
            delete(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect(MailAlias.get(testmailalias.id)).not_to eq(nil)
            expect(MailAlias.get(testmailalias.id)).to eq(testmailalias)
          end

          it 'returns an API Error' do
            delete(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
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
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end
      end

      context 'when by an unauthenticated user' do
        let!(:testmailalias) { create(:mailalias) }

        before do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testuser) { create(:user) }

        describe 'GET all' do
          it 'returns an an API authentication error' do
            get "/api/v#{api_version}/mailaliases"
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
            get "/api/v#{api_version}/mailaliases/#{testmailalias.id}"
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
            inexistent = testmailalias.id
            testmailalias.destroy
            get "/api/v#{api_version}/mailaliases/#{inexistent}"
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
              "/api/v#{api_version}/mailaliases",
              'mailalias' => attributes_for(:mailalias)
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
            testmailalias_foo = create(:mailalias, address: 'foo@foo.org')
            patch(
              "/api/v#{api_version}/mailaliases/#{testmailalias_foo.id}",
              'mailalias' => attributes_for(:mailalias)
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
            delete "/api/v#{api_version}/mailaliases/#{testmailalias.id}"
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
# rubocop:enable RSpec/PredicateMatcher, RSpec/ScatteredLet
