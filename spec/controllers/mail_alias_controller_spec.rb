# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API MailAlias Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w(1)

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      context 'by an admin' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:testmailalias) { create(:mailalias) }
        let!(:testadmin) { create(:admin, password: 'secret') }

        describe 'GET all' do
          it 'authorizes (policies) and returns an array of mailaliases' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailaliases", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(last_response.body).to eq(
              return_json_pretty(
                Pundit.policy_scope(testadmin, MailAlias).to_json
              )
            )
          end

          it 'returns valid JSON' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailaliases", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
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
            clear_cookies

            get(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            @user = testadmin
            expect(last_response.body).to eq(
              return_authorized_resource(object: testmailalias)
            )
          end

          it 'returns valid JSON' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          let(:error_msg) { 'requested resource does not exist' }
          it 'returns an API Error' do
            clear_cookies

            inexistent = testmailalias.id
            testmailalias.destroy

            get(
              "/api/v#{api_version}/mailaliases/#{inexistent}", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(last_response.status).to eq(404)
            expect(last_response.body).to eq(
              return_json_pretty(
                ApiResponseError.new(status_code: 404,
                                     error_id: 'not found',
                                     message: error_msg).to_json
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

          context 'with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(
                Pundit.authorize(testadmin, MailAlias, :create?)
              ).to be_truthy
            end

            it 'creates a new mailalias' do
              clear_cookies

              count = MailAlias.all.count

              post(
                "/api/v#{api_version}/mailaliases",
                new_attributes.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(MailAlias.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new mailalias' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailaliases",
                new_attributes.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              new = MailAlias.last

              expect(last_response.status).to eq(201)
              expect(last_response.body).to eq(
                return_json_pretty(
                  ApiResponseSuccess.new(status_code: 201,
                                         data: { object: new }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailaliases",
                new_attributes.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new mailalias' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailaliases",
                new_attributes.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              new = MailAlias.last

              expect(last_response.location).to eq(
                "http://example.org/api/v#{api_version}/mailaliases/#{new.id}"
              )
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{ , address: \'foo, enabled:true}' }
              let(:invalid_json_msg) do
                '784: unexpected token at \'{ , address: \'foo, enabled:true}\''
              end

              it 'does not create a new mailalias' do
                clear_cookies

                count = MailAlias.all.count

                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(MailAlias.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(400)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    ApiResponseError.new(
                      status_code: 400,
                      error_id: 'malformed request data',
                      message: invalid_json_msg,
                      data: nil
                    ).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_mailalias_attrs) { { foo: 'bar', disabled: 1234 } }
              let(:invalid_attrs_msg) do
                'invalid email address'
              end

              it 'does not create a new mailalias' do
                clear_cookies

                count = MailAlias.all.count

                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_mailalias_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(MailAlias.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_mailalias_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    ApiResponseError.new(
                      status_code: 422,
                      error_id: 'invalid request data',
                      message: invalid_attrs_msg,
                      data: nil
                    ).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_mailalias_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_mailalias) }
              let(:invalid_values_msg) do
                'invalid email address'
              end

              it 'does not create a new mailalias' do
                clear_cookies

                count = MailAlias.all.count

                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(MailAlias.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    ApiResponseError.new(
                      status_code: 422,
                      error_id: 'invalid request data',
                      message: invalid_values_msg,
                      data: nil
                    ).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                post(
                  "/api/v#{api_version}/mailaliases",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with a resource conflict' do
              let(:resource_conflict_msg) do
                'MailAlias#save returned false, MailAlias was not saved'
              end

              let(:domain) { create(:domain, name: 'mailalias.org') }
              let(:mailaccount) do
                create(:mailaccount,
                       email: 'foobar@mailalias.org',
                       domain_id: domain.id)
              end

              before(:each) do
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
                clear_cookies

                count = MailAlias.all.count

                post(
                  "/api/v#{api_version}/mailaliases",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(MailAlias.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/mailaliases",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(409)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    ApiResponseError.new(
                      status_code: 409,
                      error_id: 'resource conflict',
                      message: resource_conflict_msg,
                      data: nil
                    ).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                post(
                  "/api/v#{api_version}/mailaliases",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end
        end

        describe 'PATCH' do
          context 'with valid attributes' do
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
              clear_cookies

              prev_tstamp = testmailalias.updated_at

              patch(
                "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                upd_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(
                MailAlias.get(testmailalias.id).address
              ).to eq(upd_attrs[:address])
              expect(
                MailAlias.get(testmailalias.id).updated_at
              ).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated mailalias' do
              clear_cookies

              patch(
                "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                upd_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              upd_alias = MailAlias.get(testmailalias.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                return_json_pretty(
                  ApiResponseSuccess.new(status_code: 200,
                                         data: { object: upd_alias }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              clear_cookies

              patch(
                "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                upd_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{ , address: \'foo, enabled:true}' }
              let(:invalid_json_msg) do
                '784: unexpected token at \'{ , address: \'foo, enabled:true}\''
              end

              it 'does not update the mailalias' do
                clear_cookies

                prev_tstamp = testmailalias.updated_at

                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(
                  MailAlias.get(testmailalias.id).address
                ).to eq(testmailalias.address)
                expect(
                  MailAlias.get(testmailalias.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(400)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    ApiResponseError.new(
                      status_code: 400,
                      error_id: 'malformed request data',
                      message: invalid_json_msg,
                      data: nil
                    ).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_user_attrs) { { foo: 'bar', disabled: 1234 } }
              let(:invalid_attrs_msg) do
                'The attribute \'foo\' is not accessible in MailAlias'
              end

              it 'does not update the mailalias' do
                clear_cookies

                prev_tstamp = testmailalias.updated_at

                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_user_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(
                  MailAlias.get(testmailalias.id).address
                ).to eq(testmailalias.address)
                expect(
                  MailAlias.get(testmailalias.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_user_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    ApiResponseError.new(
                      status_code: 422,
                      error_id: 'invalid request data',
                      message: invalid_attrs_msg,
                      data: nil
                    ).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_user_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_mailalias) }
              let(:invalid_values_msg) do
                'invalid email address'
              end

              it 'does not update the mailalias' do
                clear_cookies

                prev_tstamp = testmailalias.updated_at

                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(
                  MailAlias.get(testmailalias.id).address
                ).to eq(testmailalias.address)
                expect(
                  MailAlias.get(testmailalias.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    ApiResponseError.new(
                      status_code: 422,
                      error_id: 'invalid request data',
                      message: invalid_values_msg,
                      data: nil
                    ).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with a resource conflict' do
              let(:domain) { create(:domain, name: 'mailalias.org') }
              let(:resource_conflict) do
                attributes_for(:mailalias,
                               address: 'existing@mailalias.org',
                               domain_id: domain.id)
              end
              let(:resource_conflict_msg) do
                'MailAlias#save returned false, MailAlias was not saved'
              end
              before(:each) do
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
                clear_cookies

                prev_tstamp = conflict.updated_at

                patch(
                  "/api/v#{api_version}/mailaliases/#{conflict.id}",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(MailAlias.get(conflict.id).address).to eq(
                  conflict.address
                )
                expect(MailAlias.get(conflict.id).updated_at).to eq(
                  prev_tstamp
                )
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/mailaliases/#{conflict.id}",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(409)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    ApiResponseError.new(
                      status_code: 409,
                      error_id: 'resource conflict',
                      message: resource_conflict_msg,
                      data: nil
                    ).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/mailaliases/#{conflict.id}",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end

          context 'operation failed' do
            let(:patch_error_msg) { '' }
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

              clear_cookies

              patch(
                "/api/v#{api_version}/mailaliases/#{invincible.id}",
                attributes_for(:mailalias, address: 'f2@invincible.de').to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(last_response.status).to eq(500)
              expect(last_response.body).to eq(
                return_json_pretty(
                  ApiResponseError.new(
                    status_code: 500,
                    error_id: 'could not update',
                    message: patch_error_msg,
                    data: nil
                  ).to_json
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
            clear_cookies

            id = testmailalias.id

            delete(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(MailAlias.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            clear_cookies

            delete(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'operation failed' do
            let(:delete_error_msg) { '' }

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

              clear_cookies

              delete(
                "/api/v#{api_version}/mailaliases/#{invincible.id}",
                nil,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(last_response.status).to eq(500)
              expect(last_response.body).to eq(
                return_json_pretty(
                  ApiResponseError.new(
                    status_code: 500,
                    error_id: 'could not delete',
                    message: delete_error_msg,
                    data: nil
                  ).to_json
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
        let!(:testuser) { create(:user_with_mailaliases) }
        let!(:owner) { create(:user_with_mailaliases) }
        let!(:testmailalias) do
          MailAlias.first(domain_id: owner.domains.first.id)
        end
        let(:unauthorized_msg) { 'insufficient permissions or quota exhausted' }

        describe 'GET all' do
          it 'returns only its own mailaliases' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailaliases", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.body).to eq(
              return_json_pretty(
                Pundit.policy_scope(testuser, MailAlias).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailaliases", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
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
            clear_cookies

            get(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                ApiResponseError.new(status_code: 403,
                                     error_id: 'unauthorized',
                                     message: unauthorized_msg).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          let(:error_msg) { 'requested resource does not exist' }

          it 'does not authorize the request' do
            expect do
              testmailalias.destroy
              Pundit.authorize(testuser, testmailalias, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            clear_cookies

            inexistent = testmailalias.id
            testmailalias.destroy

            get(
              "/api/v#{api_version}/mailaliases/#{inexistent}", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.status).to eq(404)
            expect(last_response.body).to eq(
              return_json_pretty(
                ApiResponseError.new(status_code: 404,
                                     error_id: 'not found',
                                     message: error_msg).to_json
              )
            )
          end
        end

        describe 'POST' do
          context 'with exhausted quota' do
            let(:testuser) { create(:user_with_exhausted_mailalias_quota) }
            it 'does not authorize the request' do
              expect do
                Pundit.authorize(testuser, MailAlias, :create?)
              end.to raise_exception(Pundit::NotAuthorizedError)
            end

            it 'does not create a new mailalias' do
              clear_cookies

              count = MailAlias.all.count

              post(
                "/api/v#{api_version}/mailaliases",
                attributes_for(:mailalias, mail: 'new@new.org').to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect(MailAlias.all.count).to eq(count)
            end

            it 'returns an API Error' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailaliases",
                attributes_for(:mailalias, address: 'new@new.org').to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect(last_response.status).to eq(403)
              expect(last_response.body).to eq(
                return_json_pretty(
                  ApiResponseError.new(status_code: 403,
                                       error_id: 'unauthorized',
                                       message: unauthorized_msg).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailaliases",
                attributes_for(:mailalias, address: 'new@new.org').to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with available quota' do
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
              clear_cookies

              count = MailAlias.all.count

              post(
                "/api/v#{api_version}/mailaliases",
                new.to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect(MailAlias.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new mailalias' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailaliases",
                new.to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              new = MailAlias.last

              expect(last_response.status).to eq(201)
              expect(last_response.body).to eq(
                return_json_pretty(
                  ApiResponseSuccess.new(status_code: 201,
                                         data: { object: new }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailaliases",
                new.to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with using different user_id in attributes' do
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
              clear_cookies

              count = MailAlias.all.count

              post(
                "/api/v#{api_version}/mailaliases",
                new_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect(MailAlias.all.count).to eq(count)
            end

            it 'returns an API Error' do
              clear_cookies
              post(
                "/api/v#{api_version}/mailaliases",
                new_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect(last_response.status).to eq(403)
              expect(last_response.body).to eq(
                return_json_pretty(
                  ApiResponseError.new(status_code: 403,
                                       error_id: 'unauthorized',
                                       message: unauthorized_msg).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailaliases",
                new_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
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
            clear_cookies

            updated_attrs = attributes_for(:mailalias, address: 'foo@foo.org')
            prev_tstamp = testmailalias.updated_at

            patch(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              updated_attrs.to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(testmailalias.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            clear_cookies

            updated_attrs = attributes_for(:mailalias, address: 'foo@foo.org')

            patch(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              updated_attrs.to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                ApiResponseError.new(status_code: 403,
                                     error_id: 'unauthorized',
                                     message: unauthorized_msg).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            updated_attrs = attributes_for(:mailalias, address: 'foo@foo.org')

            patch(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              updated_attrs.to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
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
            clear_cookies

            delete(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(MailAlias.get(testmailalias.id)).not_to eq(nil)
            expect(MailAlias.get(testmailalias.id)).to eq(testmailalias)
          end

          it 'returns an API Error' do
            clear_cookies

            delete(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                ApiResponseError.new(status_code: 403,
                                     error_id: 'unauthorized',
                                     message: unauthorized_msg).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            delete(
              "/api/v#{api_version}/mailaliases/#{testmailalias.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end
      end

      context 'by an unauthenticated (thus unauthorized) user' do
        let!(:testmailalias) { create(:mailalias) }
        let(:unauthorized_msg) { 'insufficient permissions or quota exhausted' }

        before(:each) do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testuser) { create(:user) }

        describe 'GET all' do
          it 'returns an an API unauthorized error' do
            get "/api/v#{api_version}/mailaliases"
            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                ApiResponseError.new(status_code: 403,
                                     error_id: 'unauthorized',
                                     message: unauthorized_msg).to_json
              )
            )
          end
        end

        describe 'GET one' do
          it 'returns an an API unauthorized error' do
            get "/api/v#{api_version}/mailaliases/#{testmailalias.id}"
            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                ApiResponseError.new(status_code: 403,
                                     error_id: 'unauthorized',
                                     message: unauthorized_msg).to_json
              )
            )
          end
        end

        describe 'GET inexistent record' do
          it 'returns an an API unauthorized error' do
            inexistent = testmailalias.id
            testmailalias.destroy
            get "/api/v#{api_version}/mailaliases/#{inexistent}"
            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                ApiResponseError.new(status_code: 403,
                                     error_id: 'unauthorized',
                                     message: unauthorized_msg).to_json
              )
            )
          end
        end

        describe 'POST' do
          it 'returns an an API unauthorized error' do
            post(
              "/api/v#{api_version}/mailaliases",
              'mailalias' => attributes_for(:mailalias)
            )
            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                ApiResponseError.new(status_code: 403,
                                     error_id: 'unauthorized',
                                     message: unauthorized_msg).to_json
              )
            )
          end
        end

        describe 'PATCH' do
          it 'returns an an API unauthorized error' do
            testmailalias_foo = create(:mailalias, address: 'foo@foo.org')
            patch(
              "/api/v#{api_version}/mailaliases/#{testmailalias_foo.id}",
              'mailalias' => attributes_for(:mailalias)
            )
            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                ApiResponseError.new(status_code: 403,
                                     error_id: 'unauthorized',
                                     message: unauthorized_msg).to_json
              )
            )
          end
        end

        describe 'DELETE' do
          it 'returns an an API unauthorized error' do
            delete "/api/v#{api_version}/mailaliases/#{testmailalias.id}"
            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                ApiResponseError.new(status_code: 403,
                                     error_id: 'unauthorized',
                                     message: unauthorized_msg).to_json
              )
            )
          end
        end
      end
    end
  end
end
