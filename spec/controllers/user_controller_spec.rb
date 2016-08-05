# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API User Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w(1)

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      context 'by an admin user' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:testgroup) { create(:group) }
        let!(:testuser) { create(:user, name: 'Test', login: 'user') }
        let!(:testadmin) { create(:admin, password: 'secret') }

        describe 'GET all' do
          it 'authorizes (policies) and returns an array of users' do
            clear_cookies

            get(
              "/api/v#{api_version}/users", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(last_response.body).to eq(
              return_json_pretty(Pundit.policy_scope(testadmin, User).to_json)
            )
          end

          it 'returns valid JSON' do
            clear_cookies

            get(
              "/api/v#{api_version}/users", nil,
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
            expect(Pundit.authorize(testadmin, testuser, :show?)).to be_truthy
          end

          it 'returns the user' do
            clear_cookies

            get(
              "/api/v#{api_version}/users/#{testuser.id}", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            @user = testadmin
            expect(last_response.body).to eq(
              return_authorized_resource(object: testuser)
            )
          end

          it 'returns valid JSON' do
            clear_cookies

            get(
              "/api/v#{api_version}/users/#{testuser.id}", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'returns an API Error' do
            clear_cookies

            inexistent = testuser.id
            testuser.destroy

            get(
              "/api/v#{api_version}/users/#{inexistent}", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(last_response.status).to eq(404)
            expect(last_response.body).to eq(
              return_json_pretty(
                api_error(ApiErrors.[](:not_found)).to_json
              )
            )
          end
        end

        describe 'POST' do
          context 'with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(Pundit.authorize(testadmin, User, :create?)).to be_truthy
            end

            it 'creates a new user' do
              clear_cookies

              count = User.all.count

              post(
                "/api/v#{api_version}/users",
                attributes_for(:user, name: 'new').to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(User.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new user' do
              clear_cookies

              post(
                "/api/v#{api_version}/users",
                attributes_for(:user, name: 'new').to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              new = User.last

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
                "/api/v#{api_version}/users",
                attributes_for(:user, name: 'new').to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new user' do
              clear_cookies

              post(
                "/api/v#{api_version}/users",
                attributes_for(:user, name: 'new').to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              new = User.last

              expect(last_response.location).to eq(
                "http://example.org/api/v#{api_version}/users/#{new.id}"
              )
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{ , name: \'foo, enabled: true }' }
              let(:invalid_json_msg) do
                '784: unexpected token at \'{ , name: \'foo, enabled: true }\''
              end

              it 'does not create a new user' do
                clear_cookies

                count = User.all.count

                post(
                  "/api/v#{api_version}/users",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(User.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/users",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(400)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    api_error(ApiErrors.[](:malformed_request)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                post(
                  "/api/v#{api_version}/users",
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
                'The attribute \'foo\' is not accessible in User'
              end

              it 'does not create a new user' do
                clear_cookies

                count = User.all.count

                post(
                  "/api/v#{api_version}/users",
                  invalid_user_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(User.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/users",
                  invalid_user_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    api_error(ApiErrors.[](:invalid_login)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                post(
                  "/api/v#{api_version}/users",
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
              let(:invalid_values) { attributes_for(:invalid_user) }
              let(:invalid_values_msg) do
                'User#save returned false, User was not saved'
              end

              it 'does not create a new user' do
                clear_cookies

                count = User.all.count

                post(
                  "/api/v#{api_version}/users",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(User.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/users",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    api_error(ApiErrors.[](:invalid_login)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                post(
                  "/api/v#{api_version}/users",
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
              let(:resource_conflict) { attributes_for(:user, login: 'user') }
              let(:resource_conflict_msg) do
                'User#save returned false, User was not saved'
              end

              it 'does not create a new user' do
                clear_cookies

                count = User.all.count

                post(
                  "/api/v#{api_version}/users",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(User.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/users",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(409)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    api_error(ApiErrors.[](:resource_conflict)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                post(
                  "/api/v#{api_version}/users",
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
            it 'authorizes the request by using the policies' do
              expect(Pundit.authorize(testadmin, User, :create?)).to be_truthy
            end

            it 'updates an existing user with new values' do
              clear_cookies

              updated_attrs = attributes_for(:user, name: 'foo')
              prev_tstamp = testuser.updated_at

              patch(
                "/api/v#{api_version}/users/#{testuser.id}",
                updated_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(User.get(testuser.id).name).to eq(updated_attrs[:name])
              expect(User.get(testuser.id).updated_at).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated user' do
              clear_cookies

              updated_attrs = attributes_for(:user, name: 'foo')

              patch(
                "/api/v#{api_version}/users/#{testuser.id}",
                updated_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              upd_user = User.get(testuser.id)

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

              updated_attrs = attributes_for(:user, name: 'foo')

              patch(
                "/api/v#{api_version}/users/#{testuser.id}",
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
              let(:invalid_json) { '{ , name: \'foo, enabled: true }' }
              let(:invalid_json_msg) do
                '784: unexpected token at \'{ , name: \'foo, enabled: true }\''
              end

              it 'does not update the user' do
                clear_cookies

                prev_tstamp = testuser.updated_at

                patch(
                  "/api/v#{api_version}/users/#{testuser.id}",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(User.get(testuser.id).name).to eq(testuser.name)
                expect(User.get(testuser.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/users/#{testuser.id}",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(400)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    api_error(ApiErrors.[](:malformed_request)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/users/#{testuser.id}",
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
                'The attribute \'foo\' is not accessible in User'
              end

              it 'does not update the user' do
                clear_cookies

                prev_tstamp = testuser.updated_at

                patch(
                  "/api/v#{api_version}/users/#{testuser.id}",
                  invalid_user_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(User.get(testuser.id).name).to eq(testuser.name)
                expect(User.get(testuser.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/users/#{testuser.id}",
                  invalid_user_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    api_error(ApiErrors.[](:invalid_request)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/users/#{testuser.id}",
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
              let(:invalid_values) { attributes_for(:invalid_user) }
              let(:invalid_values_msg) do
                'User#save returned false, User was not saved'
              end

              it 'does not update the user' do
                clear_cookies

                prev_tstamp = testuser.updated_at

                patch(
                  "/api/v#{api_version}/users/#{testuser.id}",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(User.get(testuser.id).name).to eq(testuser.name)
                expect(User.get(testuser.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/users/#{testuser.id}",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(500)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    api_error(ApiErrors.[](:failed_update)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/users/#{testuser.id}",
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
              let(:resource_conflict) do
                attributes_for(:user,
                               name: 'Conflict User UPDATED',
                               login: 'user1')
              end
              let(:resource_conflict_msg) do
                'User#save returned false, User was not saved'
              end
              before(:each) do
                create(:user, name: 'Existing User', login: 'user1')
              end
              let!(:conflict_u) do
                create(:user, name: 'Conflict User', login: 'user2')
              end

              it 'does not update the user' do
                clear_cookies

                prev_tstamp = conflict_u.updated_at

                patch(
                  "/api/v#{api_version}/users/#{conflict_u.id}",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(User.get(conflict_u.id).login).to eq(conflict_u.login)
                expect(User.get(conflict_u.id).name).to eq(conflict_u.name)
                expect(User.get(conflict_u.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/users/#{conflict_u.id}",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(409)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    api_error(ApiErrors.[](:resource_conflict)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/users/#{conflict_u.id}",
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
              invincibleuser = create(:user, name: 'invincible')
              allow(User).to receive(
                :get
              ).with(
                invincibleuser.id.to_s
              ).and_return(
                invincibleuser
              )
              allow(User).to receive(
                :get
              ).with(
                testadmin.id
              ).and_return(
                testadmin
              )
              allow(invincibleuser).to receive(:update).and_return(false)

              policy = instance_double('UserPolicy', update?: true)
              allow(policy).to receive(:update?).and_return(true)
              allow(policy).to receive(:update_with?).and_return(true)
              allow(UserPolicy).to receive(:new).and_return(policy)

              clear_cookies

              patch(
                "/api/v#{api_version}/users/#{invincibleuser.id}",
                attributes_for(:user, name: 'invincible2').to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(last_response.status).to eq(500)
              expect(last_response.body).to eq(
                return_json_pretty(
                  api_error(ApiErrors.[](:failed_update)).to_json
                )
              )
            end
          end
        end

        describe 'DELETE' do
          it 'authorizes the request by using the policies' do
            expect(Pundit.authorize(testadmin, User, :destroy?)).to be_truthy
          end

          it 'deletes the requested user' do
            clear_cookies

            id = testuser.id

            delete(
              "/api/v#{api_version}/users/#{testuser.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(User.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            clear_cookies

            delete(
              "/api/v#{api_version}/users/#{testuser.id}",
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
              invincibleuser = create(:user, name: 'invincible')
              allow(User).to receive(
                :get
              ).with(
                invincibleuser.id.to_s
              ).and_return(
                invincibleuser
              )
              allow(User).to receive(
                :get
              ).with(
                testadmin.id
              ).and_return(
                testadmin
              )
              allow(invincibleuser).to receive(:destroy).and_return(false)

              policy = instance_double('UserPolicy', destroy?: true)
              allow(policy).to receive(:destroy?).and_return(true)
              allow(UserPolicy).to receive(:new).and_return(policy)

              clear_cookies

              delete(
                "/api/v#{api_version}/users/#{invincibleuser.id}",
                nil,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(last_response.status).to eq(500)
              expect(last_response.body).to eq(
                return_json_pretty(
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
        let!(:testgroup) { create(:group) }
        let!(:testuser) { create(:user, name: 'Testuser', login: 'test') }
        let!(:user) { create(:user, name: 'herpderp') }
        let(:unauthorized_msg) { 'insufficient permissions or quota exhausted' }

        describe 'GET all' do
          it 'returns only its own user' do
            clear_cookies

            get(
              "/api/v#{api_version}/users", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            scope = Pundit.policy_scope(testuser, User)
            policy = Pundit.policy(testuser, scope)
            permitted = policy.permitted_attributes

            expect(last_response.body).to eq(
              return_json_pretty(
                User.all(id: testuser.id).to_json(only: permitted)
              )
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            get(
              "/api/v#{api_version}/users", nil,
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
              Pundit.authorize(testuser, user, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            clear_cookies

            get(
              "/api/v#{api_version}/users/#{user.id}", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            get(
              "/api/v#{api_version}/users/#{user.id}", nil,
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
              user.destroy
              Pundit.authorize(testuser, user, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            clear_cookies

            inexistent = testuser.id
            testuser.destroy

            get(
              "/api/v#{api_version}/users/#{inexistent}", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end
        end

        describe 'POST' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, User, :create?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not create a new user' do
            clear_cookies

            count = User.all.count

            post(
              "/api/v#{api_version}/users",
              attributes_for(:user, name: 'new').to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(User.all.count).to eq(count)
          end

          it 'returns an API Error' do
            clear_cookies

            post(
              "/api/v#{api_version}/users",
              attributes_for(:user, name: 'new').to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            post(
              "/api/v#{api_version}/users",
              attributes_for(:user, name: 'new').to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'PATCH' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, user, :update?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not update the user' do
            clear_cookies

            updated_attrs = attributes_for(:user, name: 'foo')
            prev_tstamp = testuser.updated_at

            patch(
              "/api/v#{api_version}/users/#{testuser.id}",
              updated_attrs.to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(testuser.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            clear_cookies

            updated_attrs = attributes_for(:user, name: 'foo')

            patch(
              "/api/v#{api_version}/users/#{user.id}",
              updated_attrs.to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            updated_attrs = attributes_for(:user, name: 'foo')

            patch(
              "/api/v#{api_version}/users/#{testuser.id}",
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
              Pundit.authorize(testuser, user, :destroy?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not delete the user' do
            clear_cookies

            delete(
              "/api/v#{api_version}/users/#{user.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(User.get(testuser.id)).not_to eq(nil)
            expect(User.get(testuser.id)).to eq(testuser)
          end

          it 'returns an API Error' do
            clear_cookies

            delete(
              "/api/v#{api_version}/users/#{user.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            delete(
              "/api/v#{api_version}/users/#{user.id}",
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
        let(:unauthorized_msg) { 'insufficient permissions or quota exhausted' }

        before(:each) do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testuser) { create(:user) }

        describe 'GET all' do
          it 'returns an an API unauthorized error' do
            get "/api/v#{api_version}/users"
            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end
        end

        describe 'GET one' do
          it 'returns an an API unauthorized error' do
            get "/api/v#{api_version}/users/#{testuser.id}"
            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end
        end

        describe 'GET inexistent record' do
          it 'returns an an API unauthorized error' do
            inexistent = testuser.id
            testuser.destroy
            get "/api/v#{api_version}/users/#{inexistent}"
            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end
        end

        describe 'POST' do
          it 'returns an an API unauthorized error' do
            post(
              "/api/v#{api_version}/users",
              'user' => attributes_for(:user)
            )
            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end
        end

        describe 'PATCH' do
          it 'returns an an API unauthorized error' do
            testuser_foo = create(:user, name: 'foo')
            patch(
              "/api/v#{api_version}/users/#{testuser_foo.id}",
              'user' => attributes_for(:user)
            )
            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end
        end

        describe 'DELETE' do
          it 'returns an an API unauthorized error' do
            delete "/api/v#{api_version}/users/#{testuser.id}"
            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              return_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end
        end
      end
    end
  end
end
