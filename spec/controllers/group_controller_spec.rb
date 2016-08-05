# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Group Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w(1)

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      context 'by an authenticated and authorized user' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:testgroup) { create(:group) }
        let!(:testadmin) { create(:admin, password: 'secret') }

        describe 'GET all' do
          it 'authorizes (policies) and returns an array of groups' do
            clear_cookies

            get(
              "/api/v#{api_version}/groups", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(last_response.body).to eq(
              return_json_pretty(Pundit.policy_scope(testadmin, Group).to_json)
            )
          end

          it 'returns valid JSON' do
            clear_cookies

            get(
              "/api/v#{api_version}/groups", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'authorizes (policies) and returns the group' do
            clear_cookies

            get(
              "/api/v#{api_version}/groups/#{testgroup.id}", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            @user = testadmin
            expect(last_response.body).to eq(
              return_authorized_resource(object: testgroup)
            )
          end

          it 'returns valid JSON' do
            clear_cookies

            get(
              "/api/v#{api_version}/groups/#{testgroup.id}", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          let(:error_msg) { ApiErrors.[](:not_found)[:message] }
          it 'returns an API Error' do
            clear_cookies

            inexistent = testgroup.id
            testgroup.destroy

            get(
              "/api/v#{api_version}/groups/#{inexistent}", nil,
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
              expect(Pundit.authorize(testadmin, Group, :create?)).to be_truthy
            end

            it 'creates a new group' do
              clear_cookies

              count = Group.all.count

              post(
                "/api/v#{api_version}/groups",
                attributes_for(:group, name: 'new').to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(Group.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new group' do
              clear_cookies

              post(
                "/api/v#{api_version}/groups",
                attributes_for(:group, name: 'new').to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              new = Group.last

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
                "/api/v#{api_version}/groups",
                attributes_for(:group, name: 'new').to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new group' do
              clear_cookies

              post(
                "/api/v#{api_version}/groups",
                attributes_for(:group, name: 'new').to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              new = Group.last

              expect(last_response.location).to eq(
                "http://example.org/api/v#{api_version}/groups/#{new.id}"
              )
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{ , name: \'foo, enabled: true }' }
              let(:invalid_json_msg) do
                '784: unexpected token at \'{ , name: \'foo, enabled: true }\''
              end

              it 'does not create a new group' do
                clear_cookies

                count = Group.all.count

                post(
                  "/api/v#{api_version}/groups",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Group.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/groups",
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
                  "/api/v#{api_version}/groups",
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
              let(:invalid_group_attrs) { { foo: 'bar', disabled: 1234 } }
              let(:invalid_attrs_msg) do
                ApiErrors.[](:invalid_group)[:message]
              end

              it 'does not create a new group' do
                clear_cookies

                count = Group.all.count

                post(
                  "/api/v#{api_version}/groups",
                  invalid_group_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Group.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/groups",
                  invalid_group_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    api_error(ApiErrors.[](:invalid_group)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                post(
                  "/api/v#{api_version}/groups",
                  invalid_group_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_group) }
              let(:invalid_values_msg) do
                ApiErrors.[](:invalid_group)[:message]
              end

              it 'does not create a new group' do
                clear_cookies

                count = Group.all.count

                post(
                  "/api/v#{api_version}/groups",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Group.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/groups",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    api_error(ApiErrors.[](:invalid_group)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                post(
                  "/api/v#{api_version}/groups",
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
              let(:resource_conflict) { attributes_for(:group) }
              let(:resource_conflict_msg) do
                ApiErrors.[](:resource_conflict)[:message]
              end

              it 'does not create a new group' do
                clear_cookies

                count = Group.all.count

                post(
                  "/api/v#{api_version}/groups",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Group.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/groups",
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
                  "/api/v#{api_version}/groups",
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
              expect(Pundit.authorize(testadmin, Group, :create?)).to be_truthy
            end

            it 'updates an existing group with new values' do
              clear_cookies

              updated_attrs = attributes_for(:group, name: 'foo')
              prev_tstamp = testgroup.updated_at

              patch(
                "/api/v#{api_version}/groups/#{testgroup.id}",
                updated_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(Group.get(testgroup.id).name).to eq(updated_attrs[:name])
              expect(Group.get(testgroup.id).updated_at).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated group' do
              clear_cookies

              updated_attrs = attributes_for(:group, name: 'foo')

              patch(
                "/api/v#{api_version}/groups/#{testgroup.id}",
                updated_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              upd_grp = Group.get(testgroup.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                return_json_pretty(
                  ApiResponseSuccess.new(status_code: 200,
                                         data: { object: upd_grp }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              clear_cookies

              updated_attrs = attributes_for(:group, name: 'foo')

              patch(
                "/api/v#{api_version}/groups/#{testgroup.id}",
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

              it 'does not update the group' do
                clear_cookies

                prev_tstamp = testgroup.updated_at

                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Group.get(testgroup.id).name).to eq(testgroup.name)
                expect(Group.get(testgroup.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
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
                  "/api/v#{api_version}/groups/#{testgroup.id}",
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
              let(:invalid_group_attrs) { { foo: 'bar', disabled: 1234 } }
              let(:invalid_attrs_msg) do
                'The attribute \'foo\' is not accessible in Group'
              end

              it 'does not update the group' do
                clear_cookies

                prev_tstamp = testgroup.updated_at

                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_group_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Group.get(testgroup.id).name).to eq(testgroup.name)
                expect(Group.get(testgroup.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_group_attrs.to_json,
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
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_group_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_group) }
              let(:invalid_values_msg) do
                ApiErrors.[](:invalid_group)[:message]
              end

              it 'does not update the group' do
                clear_cookies

                prev_tstamp = testgroup.updated_at

                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Group.get(testgroup.id).name).to eq(testgroup.name)
                expect(Group.get(testgroup.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  return_json_pretty(
                    api_error(ApiErrors.[](:invalid_group)).to_json
                  )
                )
              end

              it 'returns a valid JSON object' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
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
              let(:resource_conflict) { attributes_for(:group, name: 'admin') }
              let(:resource_conflict_msg) do
                ApiErrors.[](:invalid_group)[:resource_conflict]
              end

              it 'does not update the group' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  resource_conflict.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                prev_tstamp = testgroup.updated_at
                expect(Group.get(testgroup.id).name).to eq(testgroup.name)
                expect(Group.get(testgroup.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
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
                  "/api/v#{api_version}/groups/#{testgroup.id}",
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
            let(:patch_error_msg) do
              ApiErrors.[](:failed_update)[:message]
            end

            it 'returns an API Error' do
              invinciblegroup = create(:group, name: 'invincible')
              allow(Group).to receive(
                :get
              ).with(
                invinciblegroup.id.to_s
              ).and_return(
                invinciblegroup
              )
              allow(Group).to receive(
                :get
              ).with(
                admingroup.id
              ).and_return(
                admingroup
              )
              allow(invinciblegroup).to receive(:update).and_return(false)

              policy = instance_double('GroupPolicy', update?: true)
              allow(policy).to receive(:update?).and_return(true)
              allow(GroupPolicy).to receive(:new).and_return(policy)

              clear_cookies

              patch(
                "/api/v#{api_version}/groups/#{invinciblegroup.id}",
                attributes_for(:group, name: 'invincible2').to_json,
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
            expect(Pundit.authorize(testadmin, Group, :destroy?)).to be_truthy
          end

          it 'deletes the requested group' do
            clear_cookies

            id = testgroup.id

            delete(
              "/api/v#{api_version}/groups/#{testgroup.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(Group.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            clear_cookies

            delete(
              "/api/v#{api_version}/groups/#{testgroup.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'operation failed' do
            let(:delete_error_msg) do
              ApiErrors.[](:failed_delete)[:message]
            end

            it 'returns an API Error' do
              invinciblegroup = create(:group, name: 'invincible')
              allow(Group).to receive(
                :get
              ).with(
                invinciblegroup.id.to_s
              ).and_return(
                invinciblegroup
              )
              allow(Group).to receive(
                :get
              ).with(
                admingroup.id
              ).and_return(
                admingroup
              )
              allow(invinciblegroup).to receive(:destroy).and_return(false)

              policy = instance_double('GroupPolicy', destroy?: true)
              allow(policy).to receive(:destroy?).and_return(true)
              allow(GroupPolicy).to receive(:new).and_return(policy)

              clear_cookies

              delete(
                "/api/v#{api_version}/groups/#{invinciblegroup.id}",
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
        let!(:testuser) { create(:user, name: 'herpderp') }
        let(:unauthorized_msg) do
          ApiErrors.[](:unauthorized)[:message]
        end

        describe 'GET all' do
          it 'returns no records' do
            clear_cookies

            get(
              "/api/v#{api_version}/groups", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.body).to eq(
              return_json_pretty({}.to_json)
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            get(
              "/api/v#{api_version}/groups", nil,
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
              Pundit.authorize(testuser, testgroup, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            clear_cookies

            get(
              "/api/v#{api_version}/groups/#{testgroup.id}", nil,
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
              "/api/v#{api_version}/groups/#{testgroup.id}", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          let(:error_msg) do
            ApiErrors.[](:not_found)[:message]
          end

          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testgroup, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            clear_cookies

            inexistent = testgroup.id
            testgroup.destroy

            get(
              "/api/v#{api_version}/groups/#{inexistent}", nil,
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
              Pundit.authorize(testuser, Group, :create?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not create a new group' do
            clear_cookies

            count = Group.all.count

            post(
              "/api/v#{api_version}/groups",
              attributes_for(:group, name: 'new').to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(Group.all.count).to eq(count)
          end

          it 'returns an API Error' do
            clear_cookies

            post(
              "/api/v#{api_version}/groups",
              attributes_for(:group, name: 'new').to_json,
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
              "/api/v#{api_version}/groups",
              attributes_for(:group, name: 'new').to_json,
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
              Pundit.authorize(testuser, testgroup, :update?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not update the group' do
            clear_cookies

            updated_attrs = attributes_for(:group, name: 'foo')
            prev_tstamp = testgroup.updated_at

            patch(
              "/api/v#{api_version}/groups/#{testgroup.id}",
              updated_attrs.to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(testgroup.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            clear_cookies

            updated_attrs = attributes_for(:group, name: 'foo')

            patch(
              "/api/v#{api_version}/groups/#{testgroup.id}",
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

            updated_attrs = attributes_for(:group, name: 'foo')

            patch(
              "/api/v#{api_version}/groups/#{testgroup.id}",
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
              Pundit.authorize(testuser, testgroup, :destroy?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not delete the group' do
            clear_cookies

            delete(
              "/api/v#{api_version}/groups/#{testgroup.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(Group.get(testgroup.id)).not_to eq(nil)
            expect(Group.get(testgroup.id)).to eq(testgroup)
          end

          it 'returns an API Error' do
            clear_cookies

            delete(
              "/api/v#{api_version}/groups/#{testgroup.id}",
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
              "/api/v#{api_version}/groups/#{testgroup.id}",
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
        let(:unauthorized_msg) do
          ApiErrors.[](:unauthorized)[:message]
        end

        before(:each) do
          create(:group, name: 'admin')
          create(:group, name: 'reseller')
        end

        let(:testgroup) { create(:group) }

        describe 'GET all' do
          it 'returns an an API unauthorized error' do
            get "/api/v#{api_version}/groups"
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
            get "/api/v#{api_version}/groups/#{testgroup.id}"
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
            inexistent = testgroup.id
            testgroup.destroy
            get "/api/v#{api_version}/groups/#{inexistent}"
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
              "/api/v#{api_version}/groups",
              'group' => attributes_for(:group)
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
            testgroup_foo = create(:group, name: 'foo')
            patch(
              "/api/v#{api_version}/groups/#{testgroup_foo.id}",
              'group' => attributes_for(:group)
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
            delete "/api/v#{api_version}/groups/#{testgroup.id}"
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
