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
            get(
              "/api/v#{api_version}/groups", nil,
              auth_headers_apikey(testadmin.id)
            )

            scope = Pundit.policy_scope(testadmin, Group)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testadmin.id
              )
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/groups", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'authorizes (policies) and returns the group' do
            get(
              "/api/v#{api_version}/groups/#{testgroup.id}", nil,
              auth_headers_apikey(testadmin.id)
            )

            @user = testadmin
            expect(last_response.body).to eq(
              spec_authorized_resource(object: testgroup, user: testadmin)
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/groups/#{testgroup.id}", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          let(:testgroup) { create(:group, name: 'test') }
          it 'returns an API Error' do
            inexistent = testgroup.id
            testgroup.destroy
            get(
              "/api/v#{api_version}/groups/#{inexistent}", nil,
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
              expect(Pundit.authorize(testadmin, Group, :create?)).to be_truthy
            end

            it 'creates a new group' do
              count = Group.all.count

              post(
                "/api/v#{api_version}/groups",
                attributes_for(:group, name: 'new').to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(Group.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new group' do
              post(
                "/api/v#{api_version}/groups",
                attributes_for(:group, name: 'new').to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = Group.last

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
                "/api/v#{api_version}/groups",
                attributes_for(:group, name: 'new').to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new group' do
              post(
                "/api/v#{api_version}/groups",
                attributes_for(:group, name: 'new').to_json,
                auth_headers_apikey(testadmin.id)
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

              it 'does not create a new group' do
                count = Group.all.count

                post(
                  "/api/v#{api_version}/groups",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Group.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/groups",
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
                  "/api/v#{api_version}/groups",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_group_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not create a new group' do
                count = Group.all.count

                post(
                  "/api/v#{api_version}/groups",
                  invalid_group_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Group.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/groups",
                  invalid_group_attrs.to_json,
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
                  "/api/v#{api_version}/groups",
                  invalid_group_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_group) }

              it 'does not create a new group' do
                count = Group.all.count

                post(
                  "/api/v#{api_version}/groups",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Group.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/groups",
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

              it 'returns a valid JSON object' do
                post(
                  "/api/v#{api_version}/groups",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with a resource conflict' do
              let(:resource_conflict) { attributes_for(:group) }

              it 'does not create a new group' do
                count = Group.all.count

                post(
                  "/api/v#{api_version}/groups",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Group.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/groups",
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
                  "/api/v#{api_version}/groups",
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
              expect(Pundit.authorize(testadmin, Group, :create?)).to be_truthy
            end

            it 'updates an existing group with new values' do
              updated_attrs = attributes_for(:group, name: 'foo')
              prev_tstamp = testgroup.updated_at

              patch(
                "/api/v#{api_version}/groups/#{testgroup.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(Group.get(testgroup.id).name).to eq(updated_attrs[:name])
              expect(Group.get(testgroup.id).updated_at).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated group' do
              updated_attrs = attributes_for(:group, name: 'foo')

              patch(
                "/api/v#{api_version}/groups/#{testgroup.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              upd_grp = Group.get(testgroup.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  ApiResponseSuccess.new(status_code: 200,
                                         data: { object: upd_grp }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              updated_attrs = attributes_for(:group, name: 'foo')

              patch(
                "/api/v#{api_version}/groups/#{testgroup.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{ , name: \'foo, enabled: true }' }

              it 'does not update the group' do
                prev_tstamp = testgroup.updated_at

                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Group.get(testgroup.id).name).to eq(testgroup.name)
                expect(Group.get(testgroup.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
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
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_group_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not update the group' do
                prev_tstamp = testgroup.updated_at

                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_group_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Group.get(testgroup.id).name).to eq(testgroup.name)
                expect(Group.get(testgroup.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_group_attrs.to_json,
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
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_group_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_group) }

              it 'does not update the group' do
                prev_tstamp = testgroup.updated_at

                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Group.get(testgroup.id).name).to eq(testgroup.name)
                expect(Group.get(testgroup.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
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

              it 'returns a valid JSON object' do
                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with a resource conflict' do
              let(:resource_conflict) { attributes_for(:group, name: 'admin') }

              it 'does not update the group' do
                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                prev_tstamp = testgroup.updated_at
                expect(Group.get(testgroup.id).name).to eq(testgroup.name)
                expect(Group.get(testgroup.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/groups/#{testgroup.id}",
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
                  "/api/v#{api_version}/groups/#{testgroup.id}",
                  resource_conflict.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end

          context 'operation failed' do
            # it 'returns an API Error' do
            #   invinciblegroup = create(:group, name: 'invincible')
            #   allow(Group).to receive(
            #     :get
            #   ).with(
            #     invinciblegroup.id.to_s
            #   ).and_return(
            #     invinciblegroup
            #   )
            #   allow(Group).to receive(
            #     :get
            #   ).with(
            #     admingroup.id
            #   ).and_return(
            #     admingroup
            #   )
            #   allow(invinciblegroup).to receive(:update).and_return(false)

            #   policy = instance_double('GroupPolicy', update?: true)
            #   allow(policy).to receive(:update?).and_return(true)
            #   allow(policy).to receive(:update_with?).and_return(true)
            #   allow(GroupPolicy).to receive(:new).and_return(policy)

            #   patch(
            #     "/api/v#{api_version}/groups/#{invinciblegroup.id}",
            #     attributes_for(:group, name: 'invincible2').to_json,
            #     auth_headers_apikey(testadmin.id)
            #   )

            #   expect(last_response.status).to eq(500)
            #   expect(last_response.body).to eq(
            #     spec_json_pretty(
            #       api_error(ApiErrors.[](:failed_update)).to_json
            #     )
            #   )
            # end
          end
        end

        describe 'DELETE' do
          let(:testgroup) { create(:group, name: 'test') }
          it 'authorizes the request by using the policies' do
            expect(
              Pundit.authorize(testadmin, testgroup, :destroy?)
            ).to be_truthy
          end

          it 'deletes the requested group if it has no members' do
            id = testgroup.id

            delete(
              "/api/v#{api_version}/groups/#{testgroup.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect(Group.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            delete(
              "/api/v#{api_version}/groups/#{testgroup.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'operation failed' do
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

              delete(
                "/api/v#{api_version}/groups/#{invinciblegroup.id}",
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
        let!(:testgroup) { create(:group) }
        let!(:testuser) { create(:user, name: 'herpderp') }

        describe 'GET all' do
          it 'returns no records' do
            get(
              "/api/v#{api_version}/groups", nil,
              auth_headers_apikey(testuser.id)
            )

            expect(last_response.body).to eq(
              spec_json_pretty({}.to_json)
            )
          end

          it 'returns a valid JSON object' do
            get(
              "/api/v#{api_version}/groups", nil,
              auth_headers_apikey(testuser.id)
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
            get(
              "/api/v#{api_version}/groups/#{testgroup.id}", nil,
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
              "/api/v#{api_version}/groups/#{testgroup.id}", nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testgroup, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            inexistent = testgroup.id
            testgroup.destroy

            get(
              "/api/v#{api_version}/groups/#{inexistent}", nil,
              auth_headers_apikey(testuser.id)
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              spec_json_pretty(
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
            count = Group.all.count

            post(
              "/api/v#{api_version}/groups",
              attributes_for(:group, name: 'new').to_json,
              auth_headers_apikey(testuser.id)
            )

            expect(Group.all.count).to eq(count)
          end

          it 'returns an API Error' do
            post(
              "/api/v#{api_version}/groups",
              attributes_for(:group, name: 'new').to_json,
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
              "/api/v#{api_version}/groups",
              attributes_for(:group, name: 'new').to_json,
              auth_headers_apikey(testuser.id)
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
            updated_attrs = attributes_for(:group, name: 'foo')
            prev_tstamp = testgroup.updated_at

            patch(
              "/api/v#{api_version}/groups/#{testgroup.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect(testgroup.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            updated_attrs = attributes_for(:group, name: 'foo')

            patch(
              "/api/v#{api_version}/groups/#{testgroup.id}",
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
            updated_attrs = attributes_for(:group, name: 'foo')

            patch(
              "/api/v#{api_version}/groups/#{testgroup.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
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
            delete(
              "/api/v#{api_version}/groups/#{testgroup.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect(Group.get(testgroup.id)).not_to eq(nil)
            expect(Group.get(testgroup.id)).to eq(testgroup)
          end

          it 'returns an API Error' do
            delete(
              "/api/v#{api_version}/groups/#{testgroup.id}",
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
              "/api/v#{api_version}/groups/#{testgroup.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end
      end

      context 'by an unauthenticated user' do
        before(:each) do
          create(:group, name: 'admin')
          create(:group, name: 'reseller')
        end

        let(:testgroup) { create(:group) }

        describe 'GET all' do
          it 'returns an an API authentication failed error' do
            get "/api/v#{api_version}/groups"
            expect(last_response.status).to eq(401)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:authentication_failed)).to_json
              )
            )
          end
        end

        describe 'GET one' do
          it 'returns an an API authentication failed error' do
            get "/api/v#{api_version}/groups/#{testgroup.id}"
            expect(last_response.status).to eq(401)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:authentication_failed)).to_json
              )
            )
          end
        end

        describe 'GET inexistent record' do
          it 'returns an an API authentication failed error' do
            inexistent = testgroup.id
            testgroup.destroy
            get "/api/v#{api_version}/groups/#{inexistent}"
            expect(last_response.status).to eq(401)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:authentication_failed)).to_json
              )
            )
          end
        end

        describe 'POST' do
          it 'returns an an API authentication failed error' do
            post(
              "/api/v#{api_version}/groups",
              'group' => attributes_for(:group)
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
          it 'returns an an API authentication failed error' do
            testgroup_foo = create(:group, name: 'foo')
            patch(
              "/api/v#{api_version}/groups/#{testgroup_foo.id}",
              'group' => attributes_for(:group)
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
          it 'returns an an API authentication failed error' do
            delete "/api/v#{api_version}/groups/#{testgroup.id}"
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
