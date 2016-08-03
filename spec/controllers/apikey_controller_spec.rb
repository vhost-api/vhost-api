# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Apikey Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w(1)

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      context 'by an admin user' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:testapikey) { create(:apikey) }
        let!(:testadmin) { create(:admin, password: 'secret') }

        describe 'GET all' do
          it 'authorizes (policies) and returns an array of apikeys' do
            clear_cookies

            get(
              "/api/v#{api_version}/apikeys", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(last_response.body).to eq(
              return_json_pretty(Pundit.policy_scope(testadmin, Apikey).to_json)
            )
          end

          it 'returns valid JSON' do
            clear_cookies

            get(
              "/api/v#{api_version}/apikeys", nil,
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
            expect(Pundit.authorize(testadmin, testapikey, :show?)).to be_truthy
          end

          it 'returns the apikey' do
            clear_cookies

            get(
              "/api/v#{api_version}/apikeys/#{testapikey.id}", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            @user = testadmin
            expect(last_response.body).to eq(
              return_authorized_resource(object: testapikey)
            )
          end

          it 'returns valid JSON' do
            clear_cookies

            get(
              "/api/v#{api_version}/apikeys/#{testapikey.id}", nil,
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

            inexistent = testapikey.id
            testapikey.destroy

            get(
              "/api/v#{api_version}/apikeys/#{inexistent}", nil,
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
          context 'with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(Pundit.authorize(testadmin, Apikey, :create?)).to be_truthy
            end

            it 'creates a new apikey' do
              clear_cookies

              count = Apikey.all.count

              post(
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey).to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(Apikey.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new apikey' do
              clear_cookies

              post(
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey).to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              new = Apikey.last

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
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey).to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new apikey' do
              clear_cookies

              post(
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey).to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              new = Apikey.last

              expect(last_response.location).to eq(
                "http://example.org/api/v#{api_version}/apikeys/#{new.id}"
              )
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{ , name: \'foo, enabled: true }' }
              let(:invalid_json_msg) do
                '784: unexpected token at \'{ , name: \'foo, enabled: true }\''
              end

              it 'does not create a new apikey' do
                clear_cookies

                count = Apikey.all.count

                post(
                  "/api/v#{api_version}/apikeys",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Apikey.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/apikeys",
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
                  "/api/v#{api_version}/apikeys",
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
              let(:invalid_apikey_attrs) { { foo: 'bar', disabled: 1234 } }
              let(:invalid_attrs_msg) do
                'The attribute \'foo\' is not accessible in Apikey'
              end

              it 'does not create a new apikey' do
                clear_cookies

                count = Apikey.all.count

                post(
                  "/api/v#{api_version}/apikeys",
                  invalid_apikey_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Apikey.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/apikeys",
                  invalid_apikey_attrs.to_json,
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
                  "/api/v#{api_version}/apikeys",
                  invalid_apikey_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_apikey) }
              let(:invalid_values_msg) do
                'invalid apikey, has to be 64 characters'
              end

              it 'does not create a new apikey' do
                clear_cookies

                count = Apikey.all.count

                post(
                  "/api/v#{api_version}/apikeys",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Apikey.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/apikeys",
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
                  "/api/v#{api_version}/apikeys",
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
                'Apikey#save returned false, Apikey was not saved'
              end
              let(:testkey) { SecureRandom.hex(32) }
              before(:each) do
                create(:apikey, apikey: testkey)
              end
              let(:resource_conflict) do
                build(:apikey, apikey: testkey)
              end

              it 'does not create a new apikey' do
                clear_cookies

                count = Apikey.all.count

                post(
                  "/api/v#{api_version}/apikeys",
                  resource_conflict.to_json(methods: nil),
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Apikey.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/apikeys",
                  resource_conflict.to_json(methods: nil),
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
                  "/api/v#{api_version}/apikeys",
                  resource_conflict.to_json(methods: nil),
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
            it 'authorizes the request by using the policies' do
              expect(Pundit.authorize(testadmin, Apikey, :create?)).to be_truthy
            end

            it 'updates an existing apikey with new values' do
              clear_cookies

              updated_attrs = attributes_for(:apikey, comment: 'herpderp')
              prev_tstamp = testapikey.updated_at

              patch(
                "/api/v#{api_version}/apikeys/#{testapikey.id}",
                updated_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(
                Apikey.get(testapikey.id).comment
              ).to eq(updated_attrs[:comment])
              expect(Apikey.get(testapikey.id).updated_at).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated apikey' do
              clear_cookies

              updated_attrs = attributes_for(:apikey, comment: 'herpderp')

              patch(
                "/api/v#{api_version}/apikeys/#{testapikey.id}",
                updated_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              upd_user = Apikey.get(testapikey.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                return_json_pretty(
                  ApiResponseSuccess.new(status_code: 200,
                                         data: { object: upd_user }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              clear_cookies

              updated_attrs = attributes_for(:apikey, comment: 'herpderp')

              patch(
                "/api/v#{api_version}/apikeys/#{testapikey.id}",
                updated_attrs.to_json,
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
              let(:invalid_json) { '{, comment:\'foo, enabled: true }' }
              let(:invalid_json_msg) do
                '784: unexpected token at \'{, comment:\'foo, enabled: true }\''
              end

              it 'does not update the apikey' do
                clear_cookies

                prev_tstamp = testapikey.updated_at

                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(
                  Apikey.get(testapikey.id).comment
                ).to eq(testapikey.comment)
                expect(Apikey.get(testapikey.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
                'The attribute \'foo\' is not accessible in Apikey'
              end

              it 'does not update the apikey' do
                clear_cookies

                prev_tstamp = testapikey.updated_at

                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
                  invalid_user_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(
                  Apikey.get(testapikey.id).comment
                ).to eq(testapikey.comment)
                expect(Apikey.get(testapikey.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
              let(:invalid_values) { attributes_for(:invalid_apikey) }
              let(:invalid_values_msg) do
                'invalid apikey, has to be 64 characters'
              end

              it 'does not update the apikey' do
                clear_cookies

                prev_tstamp = testapikey.updated_at

                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(
                  Apikey.get(testapikey.id).apikey
                ).to eq(testapikey.apikey)
                expect(Apikey.get(testapikey.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
                'Apikey#save returned false, Apikey was not saved'
              end
              let(:key) { SecureRandom.hex(32) }
              before(:each) do
                create(:apikey, apikey: key)
              end
              let(:resource_conflict) do
                attributes_for(:apikey, apikey: key)
              end
              let(:conflict_apikey) do
                create(:apikey, apikey: key)
              end

              it 'does not update the apikey' do
                clear_cookies

                prev_tstamp = conflict_apikey.updated_at

                patch(
                  "/api/v#{api_version}/apikeys/#{conflict_apikey.id}",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Apikey.get(conflict_apikey.id).apikey).to eq(
                  conflict_apikey.apikey
                )
                expect(Apikey.get(conflict_apikey.id).updated_at).to eq(
                  prev_tstamp
                )
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/apikeys/#{conflict_apikey.id}",
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
                  "/api/v#{api_version}/apikeys/#{conflict_apikey.id}",
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

            it 'returns an API Error' do
              invincibleapikey = create(:apikey)
              allow(Apikey).to receive(
                :get
              ).with(
                invincibleapikey.id.to_s
              ).and_return(
                invincibleapikey
              )
              allow(invincibleapikey).to receive(:update).and_return(false)
              policy = instance_double('ApikeyPolicy', update?: true)
              allow(policy).to receive(:update?).and_return(true)
              allow(policy).to receive(:update_with?).and_return(true)
              allow(ApikeyPolicy).to receive(:new).and_return(policy)

              clear_cookies

              patch(
                "/api/v#{api_version}/apikeys/#{invincibleapikey.id}",
                attributes_for(:apikey, comment: 'foobar').to_json,
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
            expect(Pundit.authorize(testadmin, Apikey, :destroy?)).to be_truthy
          end

          it 'deletes the requested apikey' do
            clear_cookies

            id = testapikey.id

            delete(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(Apikey.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            clear_cookies

            delete(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
              invincibleapikey = create(:apikey)
              allow(Apikey).to receive(
                :get
              ).with(
                invincibleapikey.id.to_s
              ).and_return(
                invincibleapikey
              )
              allow(invincibleapikey).to receive(:destroy).and_return(false)
              policy = instance_double('ApikeyPolicy', destroy?: true)
              allow(policy).to receive(:destroy?).and_return(true)
              allow(ApikeyPolicy).to receive(:new).and_return(policy)

              clear_cookies

              delete(
                "/api/v#{api_version}/apikeys/#{invincibleapikey.id}",
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
        let!(:testuser) { create(:user_with_apikeys) }
        let!(:owner) { create(:user_with_apikeys) }
        let!(:testapikey) { owner.apikeys.first }
        let(:unauthorized_msg) { 'insufficient permissions or quota exhausted' }

        describe 'GET all' do
          it 'returns only its own apikeys' do
            clear_cookies

            get(
              "/api/v#{api_version}/apikeys", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.body).to eq(
              return_json_pretty(Pundit.policy_scope(testuser, Apikey).to_json)
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            get(
              "/api/v#{api_version}/apikeys", nil,
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
              Pundit.authorize(testuser, testapikey, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            clear_cookies

            get(
              "/api/v#{api_version}/apikeys/#{testapikey.id}", nil,
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
              "/api/v#{api_version}/apikeys/#{testapikey.id}", nil,
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
              testapikey.destroy
              Pundit.authorize(testuser, testapikey, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            clear_cookies

            inexistent = testapikey.id
            testapikey.destroy

            get(
              "/api/v#{api_version}/apikeys/#{inexistent}", nil,
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
            let(:testuser) { create(:user_with_exhausted_apikey_quota) }
            it 'does not authorize the request' do
              expect do
                Pundit.authorize(testuser, Apikey, :create?)
              end.to raise_exception(Pundit::NotAuthorizedError)
            end

            it 'does not create a new apikey' do
              clear_cookies

              count = Apikey.all.count

              post(
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey).to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect(Apikey.all.count).to eq(count)
            end

            it 'returns an API Error' do
              clear_cookies

              post(
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey).to_json,
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
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey).to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with available quota' do
            let!(:testuser) { create(:user_with_apikeys) }
            let!(:newapikey) do
              attributes_for(:apikey, user_id: testuser.id)
            end
            it 'authorizes the request' do
              expect(
                Pundit.authorize(testuser, Apikey, :create?)
              ).to be_truthy
              expect(
                Pundit.policy(testuser, Apikey).create_with?(newapikey)
              ).to be_truthy
            end

            it 'does create a new apikey' do
              clear_cookies

              count = Apikey.all.count

              post(
                "/api/v#{api_version}/apikeys",
                newapikey.to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect(Apikey.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new apikey' do
              clear_cookies

              post(
                "/api/v#{api_version}/apikeys",
                newapikey.to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              new = Apikey.last

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
                "/api/v#{api_version}/apikeys",
                newapikey.to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with using different user_id in attributes' do
            let(:testuser) { create(:user_with_apikeys) }
            let(:anotheruser) { create(:user) }

            it 'does not create a new apikey' do
              clear_cookies

              count = Apikey.all.count

              post(
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey,
                               user_id: anotheruser.id).to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect(Apikey.all.count).to eq(count)
            end

            it 'returns an API Error' do
              clear_cookies

              post(
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey,
                               user_id: anotheruser.id).to_json,
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
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey,
                               user_id: anotheruser.id).to_json,
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
              Pundit.authorize(testuser, testapikey, :update?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not update the apikey' do
            clear_cookies

            updated_attrs = attributes_for(:apikey)
            prev_tstamp = testapikey.updated_at

            patch(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
              updated_attrs.to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(testapikey.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            clear_cookies

            updated_attrs = attributes_for(:apikey)

            patch(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
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

            updated_attrs = attributes_for(:apikey)

            patch(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
              Pundit.authorize(testuser, testapikey, :destroy?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not delete the apikey' do
            clear_cookies

            delete(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(Apikey.get(testapikey.id)).not_to eq(nil)
            expect(Apikey.get(testapikey.id)).to eq(testapikey)
          end

          it 'returns an API Error' do
            clear_cookies

            delete(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
        let!(:testapikey) { create(:apikey) }
        let(:unauthorized_msg) { 'insufficient permissions or quota exhausted' }

        before(:each) do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testuser) { create(:user) }

        describe 'GET all' do
          it 'returns an an API unauthorized error' do
            get "/api/v#{api_version}/apikeys"
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
            get "/api/v#{api_version}/apikeys/#{testapikey.id}"
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
            inexistent = testapikey.id
            testapikey.destroy
            get "/api/v#{api_version}/apikeys/#{inexistent}"
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
              "/api/v#{api_version}/apikeys",
              'apikey' => attributes_for(:apikey)
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
            testapikey_foo = create(:apikey)
            patch(
              "/api/v#{api_version}/apikeys/#{testapikey_foo.id}",
              'apikey' => attributes_for(:apikey)
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
            delete "/api/v#{api_version}/apikeys/#{testapikey.id}"
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
