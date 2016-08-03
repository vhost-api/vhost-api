# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API MailSource Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w(1)

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      context 'by an admin' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:testmailsource) { create(:mailsource) }
        let!(:testadmin) { create(:admin, password: 'secret') }

        describe 'GET all' do
          it 'authorizes (policies) and returns an array of mailsources' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailsources", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(last_response.body).to eq(
              return_json_pretty(
                Pundit.policy_scope(testadmin, MailSource).to_json
              )
            )
          end

          it 'returns valid JSON' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailsources", nil,
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
              Pundit.authorize(testadmin, testmailsource, :show?)
            ).to be_truthy
          end

          it 'returns the mailsource' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailsources/#{testmailsource.id}", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            @user = testadmin
            expect(last_response.body).to eq(
              return_authorized_resource(object: testmailsource)
            )
          end

          it 'returns valid JSON' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailsources/#{testmailsource.id}", nil,
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

            inexistent = testmailsource.id
            testmailsource.destroy

            get(
              "/api/v#{api_version}/mailsources/#{inexistent}", nil,
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
            attributes_for(:mailsource,
                           address: address,
                           domain_id: domain.id,
                           src: [mailaccount.id])
          end

          context 'with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(
                Pundit.authorize(testadmin, MailSource, :create?)
              ).to be_truthy
            end

            it 'creates a new mailsource' do
              clear_cookies

              count = MailSource.all.count

              post(
                "/api/v#{api_version}/mailsources",
                new_attributes.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(MailSource.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new mailsource' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailsources",
                new_attributes.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              new = MailSource.last

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
                "/api/v#{api_version}/mailsources",
                new_attributes.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new mailsource' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailsources",
                new_attributes.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              new = MailSource.last

              expect(last_response.location).to eq(
                "http://example.org/api/v#{api_version}/mailsources/#{new.id}"
              )
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{ , address: \'foo, enabled:true}' }
              let(:invalid_json_msg) do
                '784: unexpected token at \'{ , address: \'foo, enabled:true}\''
              end

              it 'does not create a new mailsource' do
                clear_cookies

                count = MailSource.all.count

                post(
                  "/api/v#{api_version}/mailsources",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(MailSource.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/mailsources",
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
                  "/api/v#{api_version}/mailsources",
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
              let(:invalid_mailsource_attrs) { { foo: 'bar', disabled: 1234 } }
              let(:invalid_attrs_msg) do
                'invalid email address'
              end

              it 'does not create a new mailsource' do
                clear_cookies

                count = MailSource.all.count

                post(
                  "/api/v#{api_version}/mailsources",
                  invalid_mailsource_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(MailSource.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/mailsources",
                  invalid_mailsource_attrs.to_json,
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
                  "/api/v#{api_version}/mailsources",
                  invalid_mailsource_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_mailsource) }
              let(:invalid_values_msg) do
                'invalid email address'
              end

              it 'does not create a new mailsource' do
                clear_cookies

                count = MailSource.all.count

                post(
                  "/api/v#{api_version}/mailsources",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(MailSource.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/mailsources",
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
                  "/api/v#{api_version}/mailsources",
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
                'MailSource#save returned false, MailSource was not saved'
              end

              let(:domain) { create(:domain, name: 'mailsource.org') }
              let(:mailaccount) do
                create(:mailaccount,
                       email: 'foobar@mailsource.org',
                       domain_id: domain.id)
              end

              before(:each) do
                create(:mailsource,
                       address: 'existing@mailsource.org',
                       domain_id: domain.id)
              end
              let(:resource_conflict) do
                attributes_for(:mailsource,
                               address: 'existing@mailsource.org',
                               domain_id: domain.id,
                               src: [mailaccount.id])
              end

              it 'does not create a new mailsource' do
                clear_cookies

                count = MailSource.all.count

                post(
                  "/api/v#{api_version}/mailsources",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(MailSource.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/mailsources",
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
                  "/api/v#{api_version}/mailsources",
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
            let(:domain) { testmailsource.domain }
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
            let(:sources) do
              [mailaccount.id, mailaccount2.id, mailaccount3.id]
            end
            let(:upd_attrs) do
              attributes_for(
                :mailsource,
                address: "foo@#{domain.name}",
                src: sources
              )
            end

            it 'updates an existing mailsource with new values' do
              clear_cookies

              prev_tstamp = testmailsource.updated_at

              patch(
                "/api/v#{api_version}/mailsources/#{testmailsource.id}",
                upd_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(
                MailSource.get(testmailsource.id).address
              ).to eq(upd_attrs[:address])
              expect(
                MailSource.get(testmailsource.id).updated_at
              ).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated mailsource' do
              clear_cookies

              patch(
                "/api/v#{api_version}/mailsources/#{testmailsource.id}",
                upd_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              upd_source = MailSource.get(testmailsource.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                return_json_pretty(
                  ApiResponseSuccess.new(status_code: 200,
                                         data: { object: upd_source }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              clear_cookies

              patch(
                "/api/v#{api_version}/mailsources/#{testmailsource.id}",
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

              it 'does not update the mailsource' do
                clear_cookies

                prev_tstamp = testmailsource.updated_at

                patch(
                  "/api/v#{api_version}/mailsources/#{testmailsource.id}",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(
                  MailSource.get(testmailsource.id).address
                ).to eq(testmailsource.address)
                expect(
                  MailSource.get(testmailsource.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/mailsources/#{testmailsource.id}",
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
                  "/api/v#{api_version}/mailsources/#{testmailsource.id}",
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
                'The attribute \'foo\' is not accessible in MailSource'
              end

              it 'does not update the mailsource' do
                clear_cookies

                prev_tstamp = testmailsource.updated_at

                patch(
                  "/api/v#{api_version}/mailsources/#{testmailsource.id}",
                  invalid_user_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(
                  MailSource.get(testmailsource.id).address
                ).to eq(testmailsource.address)
                expect(
                  MailSource.get(testmailsource.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/mailsources/#{testmailsource.id}",
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
                  "/api/v#{api_version}/mailsources/#{testmailsource.id}",
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
              let(:invalid_values) { attributes_for(:invalid_mailsource) }
              let(:invalid_values_msg) do
                'invalid email address'
              end

              it 'does not update the mailsource' do
                clear_cookies

                prev_tstamp = testmailsource.updated_at

                patch(
                  "/api/v#{api_version}/mailsources/#{testmailsource.id}",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(
                  MailSource.get(testmailsource.id).address
                ).to eq(testmailsource.address)
                expect(
                  MailSource.get(testmailsource.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/mailsources/#{testmailsource.id}",
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
                  "/api/v#{api_version}/mailsources/#{testmailsource.id}",
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
              let(:domain) { create(:domain, name: 'mailsource.org') }
              let(:resource_conflict) do
                attributes_for(:mailsource,
                               address: 'existing@mailsource.org',
                               domain_id: domain.id)
              end
              let(:resource_conflict_msg) do
                'MailSource#save returned false, MailSource was not saved'
              end
              before(:each) do
                create(:mailsource,
                       address: 'existing@mailsource.org',
                       domain_id: domain.id)
              end
              let(:conflict) do
                create(:mailsource,
                       address: 'conflict@mailsource.org',
                       domain_id: domain.id)
              end

              it 'does not update the mailsource' do
                clear_cookies

                prev_tstamp = conflict.updated_at

                patch(
                  "/api/v#{api_version}/mailsources/#{conflict.id}",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(MailSource.get(conflict.id).address).to eq(
                  conflict.address
                )
                expect(MailSource.get(conflict.id).updated_at).to eq(
                  prev_tstamp
                )
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/mailsources/#{conflict.id}",
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
                  "/api/v#{api_version}/mailsources/#{conflict.id}",
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
              invincible = create(:mailsource,
                                  address: 'foo@invincible.de',
                                  domain_id: domain.id)
              allow(MailSource).to receive(
                :get
              ).with(
                invincible.id.to_s
              ).and_return(
                invincible
              )
              allow(invincible).to receive(:update).and_return(false)
              policy = instance_double('MailSourcePolicy', update?: true)
              allow(policy).to receive(:update?).and_return(true)
              allow(policy).to receive(:update_with?).and_return(true)
              allow(MailSourcePolicy).to receive(:new).and_return(policy)

              clear_cookies

              patch(
                "/api/v#{api_version}/mailsources/#{invincible.id}",
                attributes_for(:mailsource, address: 'f@invincible.de').to_json,
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
              Pundit.authorize(testadmin, MailSource, :destroy?)
            ).to be_truthy
          end

          it 'deletes the requested mailsource' do
            clear_cookies

            id = testmailsource.id

            delete(
              "/api/v#{api_version}/mailsources/#{testmailsource.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(MailSource.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            clear_cookies

            delete(
              "/api/v#{api_version}/mailsources/#{testmailsource.id}",
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
              invincible = create(:mailsource,
                                  address: 'foo@invincible.org')
              allow(MailSource).to receive(
                :get
              ).with(
                invincible.id.to_s
              ).and_return(
                invincible
              )
              allow(invincible).to receive(:destroy).and_return(false)
              policy = instance_double('MailSourcePolicy', destroy?: true)
              allow(policy).to receive(:destroy?).and_return(true)
              allow(MailSourcePolicy).to receive(:new).and_return(policy)

              clear_cookies

              delete(
                "/api/v#{api_version}/mailsources/#{invincible.id}",
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
        let!(:testuser) { create(:user_with_mailsources) }
        let!(:owner) { create(:user_with_mailsources) }
        let!(:testmailsource) do
          MailSource.first(domain_id: owner.domains.first.id)
        end
        let(:unauthorized_msg) { 'insufficient permissions or quota exhausted' }

        describe 'GET all' do
          it 'returns only its own mailsources' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailsources", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.body).to eq(
              return_json_pretty(
                Pundit.policy_scope(testuser, MailSource).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailsources", nil,
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
              Pundit.authorize(testuser, testmailsource, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            clear_cookies

            get(
              "/api/v#{api_version}/mailsources/#{testmailsource.id}", nil,
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
              "/api/v#{api_version}/mailsources/#{testmailsource.id}", nil,
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
              testmailsource.destroy
              Pundit.authorize(testuser, testmailsource, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            clear_cookies

            inexistent = testmailsource.id
            testmailsource.destroy

            get(
              "/api/v#{api_version}/mailsources/#{inexistent}", nil,
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
            let(:testuser) { create(:user_with_exhausted_mailsource_quota) }
            it 'does not authorize the request' do
              expect do
                Pundit.authorize(testuser, MailSource, :create?)
              end.to raise_exception(Pundit::NotAuthorizedError)
            end

            it 'does not create a new mailsource' do
              clear_cookies

              count = MailSource.all.count

              post(
                "/api/v#{api_version}/mailsources",
                attributes_for(:mailsource, mail: 'new@new.org').to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect(MailSource.all.count).to eq(count)
            end

            it 'returns an API Error' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailsources",
                attributes_for(:mailsource, address: 'new@new.org').to_json,
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
                "/api/v#{api_version}/mailsources",
                attributes_for(:mailsource, address: 'new@new.org').to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with available quota' do
            let(:testuser) { create(:user_with_mailsources) }
            let(:domain) { testuser.domains.first }
            let(:mailaccount) { domain.mail_accounts.first }
            let(:new) do
              attributes_for(:mailsource,
                             address: "new@#{domain.name}",
                             domain_id: domain.id,
                             src: [mailaccount.id])
            end

            it 'authorizes the request' do
              expect(
                Pundit.authorize(testuser, MailSource, :create?)
              ).to be_truthy
              expect(
                Pundit.policy(testuser, MailSource).create_with?(new)
              ).to be_truthy
            end

            it 'does create a new mailsource' do
              clear_cookies

              count = MailSource.all.count

              post(
                "/api/v#{api_version}/mailsources",
                new.to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect(MailSource.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new mailsource' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailsources",
                new.to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              new = MailSource.last

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
                "/api/v#{api_version}/mailsources",
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
            let(:testuser) { create(:user_with_mailsources) }
            let(:anotheruser) { create(:user_with_mailaccounts) }
            let(:domain) { anotheruser.domains.first }
            let(:mailaccount) { domain.mail_accounts.first }
            let(:new_attrs) do
              attributes_for(
                :mailsource,
                address: "new@#{domain.name}",
                domain_id: domain.id,
                src: [mailaccount.id]
              )
            end

            it 'does not create a new mailsource' do
              clear_cookies

              count = MailSource.all.count

              post(
                "/api/v#{api_version}/mailsources",
                new_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect(MailSource.all.count).to eq(count)
            end

            it 'returns an API Error' do
              clear_cookies

              post(
                "/api/v#{api_version}/mailsources",
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
                "/api/v#{api_version}/mailsources",
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
              Pundit.authorize(testuser, testmailsource, :update?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not update the mailsource' do
            clear_cookies

            upd_attrs = attributes_for(:mailsource, address: 'foo@foo.org')
            prev_tstamp = testmailsource.updated_at

            patch(
              "/api/v#{api_version}/mailsources/#{testmailsource.id}",
              upd_attrs.to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(testmailsource.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            clear_cookies

            upd_attrs = attributes_for(:mailsource, address: 'foo@foo.org')

            patch(
              "/api/v#{api_version}/mailsources/#{testmailsource.id}",
              upd_attrs.to_json,
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

            upd_attrs = attributes_for(:mailsource, address: 'foo@foo.org')

            patch(
              "/api/v#{api_version}/mailsources/#{testmailsource.id}",
              upd_attrs.to_json,
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
              Pundit.authorize(testuser, testmailsource, :destroy?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not delete the mailsource' do
            clear_cookies

            delete(
              "/api/v#{api_version}/mailsources/#{testmailsource.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(MailSource.get(testmailsource.id)).not_to eq(nil)
            expect(MailSource.get(testmailsource.id)).to eq(testmailsource)
          end

          it 'returns an API Error' do
            clear_cookies

            delete(
              "/api/v#{api_version}/mailsources/#{testmailsource.id}",
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
              "/api/v#{api_version}/mailsources/#{testmailsource.id}",
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
        let!(:testmailsource) { create(:mailsource) }
        let(:unauthorized_msg) { 'insufficient permissions or quota exhausted' }

        before(:each) do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testuser) { create(:user) }

        describe 'GET all' do
          it 'returns an an API unauthorized error' do
            get "/api/v#{api_version}/mailsources"
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
            get "/api/v#{api_version}/mailsources/#{testmailsource.id}"
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
            inexistent = testmailsource.id
            testmailsource.destroy
            get "/api/v#{api_version}/mailsources/#{inexistent}"
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
              "/api/v#{api_version}/mailsources",
              'mailsource' => attributes_for(:mailsource)
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
            testmailsource_foo = create(:mailsource, address: 'foo@foo.org')
            patch(
              "/api/v#{api_version}/mailsources/#{testmailsource_foo.id}",
              'mailsource' => attributes_for(:mailsource)
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
            delete "/api/v#{api_version}/mailsources/#{testmailsource.id}"
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