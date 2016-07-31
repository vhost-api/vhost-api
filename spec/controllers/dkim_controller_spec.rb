# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API Dkim Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w(1)

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      context 'by an admin user' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:testdkim) { create(:dkim) }
        let!(:testadmin) { create(:admin, password: 'secret') }

        describe 'GET all' do
          it 'authorizes (policies) and returns an array of dkims' do
            clear_cookies

            get(
              "/api/v#{api_version}/dkims", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(last_response.body).to eq(
              return_json_pretty(
                Pundit.policy_scope(testadmin, Dkim).to_json
              )
            )
          end

          it 'returns valid JSON' do
            clear_cookies

            get(
              "/api/v#{api_version}/dkims", nil,
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
              Pundit.authorize(testadmin, testdkim, :show?)
            ).to be_truthy
          end

          it 'returns the dkim' do
            clear_cookies

            get(
              "/api/v#{api_version}/dkims/#{testdkim.id}", nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            @user = testadmin
            expect(last_response.body).to eq(
              return_authorized_resource(object: testdkim)
            )
          end

          it 'returns valid JSON' do
            clear_cookies

            get(
              "/api/v#{api_version}/dkims/#{testdkim.id}", nil,
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

            inexistent = testdkim.id
            testdkim.destroy

            get(
              "/api/v#{api_version}/dkims/#{inexistent}", nil,
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
          let(:selector) { 'new@new.org' }
          let(:new_attributes) do
            attributes_for(:dkim,
                           selector: selector,
                           domain_id: domain.id)
          end

          context 'with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(
                Pundit.authorize(testadmin, Dkim, :create?)
              ).to be_truthy
            end

            it 'creates a new dkim' do
              clear_cookies

              count = Dkim.all.count

              post(
                "/api/v#{api_version}/dkims",
                new_attributes.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(Dkim.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new dkim' do
              clear_cookies

              post(
                "/api/v#{api_version}/dkims",
                new_attributes.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              new = Dkim.last

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
                "/api/v#{api_version}/dkims",
                new_attributes.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new dkim' do
              clear_cookies

              post(
                "/api/v#{api_version}/dkims",
                new_attributes.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              new = Dkim.last

              expect(last_response.location).to eq(
                "http://example.org/api/v#{api_version}/dkims/#{new.id}"
              )
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{, selector: \'foo, enabled:true}' }
              let(:invalid_json_msg) do
                '784: unexpected token at \'{, selector: \'foo, enabled:true}\''
              end

              it 'does not create a new dkim' do
                clear_cookies

                count = Dkim.all.count

                post(
                  "/api/v#{api_version}/dkims",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Dkim.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/dkims",
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
                  "/api/v#{api_version}/dkims",
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
              let(:invalid_dkim_attrs) { { foo: 'bar', disabled: 1234 } }
              let(:invalid_attrs_msg) do
                'invalid selector'
              end

              it 'does not create a new dkim' do
                clear_cookies

                count = Dkim.all.count

                post(
                  "/api/v#{api_version}/dkims",
                  invalid_dkim_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Dkim.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/dkims",
                  invalid_dkim_attrs.to_json,
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
                  "/api/v#{api_version}/dkims",
                  invalid_dkim_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_dkim) }
              let(:invalid_values_msg) do
                'invalid selector'
              end

              it 'does not create a new dkim' do
                clear_cookies

                count = Dkim.all.count

                post(
                  "/api/v#{api_version}/dkims",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(Dkim.all.count).to eq(count)
              end

              it 'returns an API Error' do
                clear_cookies

                post(
                  "/api/v#{api_version}/dkims",
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
                  "/api/v#{api_version}/dkims",
                  invalid_values.to_json,
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
              expect(
                Pundit.authorize(testadmin, Dkim, :create?)
              ).to be_truthy
            end

            it 'updates an existing dkim with new values' do
              clear_cookies

              upd_attrs = attributes_for(
                :dkim,
                selector: "foo@#{testdkim.domain.name}"
              )
              prev_tstamp = testdkim.updated_at

              patch(
                "/api/v#{api_version}/dkims/#{testdkim.id}",
                upd_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              expect(
                Dkim.get(testdkim.id).selector
              ).to eq(upd_attrs[:selector])
              expect(
                Dkim.get(testdkim.id).updated_at
              ).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated dkim' do
              clear_cookies

              upd_attrs = attributes_for(
                :dkim,
                selector: "foo@#{testdkim.domain.name}"
              )

              patch(
                "/api/v#{api_version}/dkims/#{testdkim.id}",
                upd_attrs.to_json,
                appconfig[:session][:key] => {
                  user_id: testadmin.id,
                  group: Group.get(testadmin.group_id).name
                }
              )

              upd_source = Dkim.get(testdkim.id)

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

              upd_attrs = attributes_for(:dkim, selector: 'foo@foo.org')

              patch(
                "/api/v#{api_version}/dkims/#{testdkim.id}",
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
              let(:invalid_json) { '{, selector: \'foo, enabled:true}' }
              let(:invalid_json_msg) do
                '784: unexpected token at \'{, selector: \'foo, enabled:true}\''
              end

              it 'does not update the dkim' do
                clear_cookies

                prev_tstamp = testdkim.updated_at

                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
                  invalid_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(
                  Dkim.get(testdkim.id).selector
                ).to eq(testdkim.selector)
                expect(
                  Dkim.get(testdkim.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
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
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
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
                'invalid selector'
              end

              it 'does not update the dkim' do
                clear_cookies

                prev_tstamp = testdkim.updated_at

                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
                  invalid_user_attrs.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(
                  Dkim.get(testdkim.id).selector
                ).to eq(testdkim.selector)
                expect(
                  Dkim.get(testdkim.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
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
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
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
              let(:invalid_values) { attributes_for(:invalid_dkim) }
              let(:invalid_values_msg) do
                'invalid selector'
              end

              it 'does not update the dkim' do
                clear_cookies

                prev_tstamp = testdkim.updated_at

                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
                  invalid_values.to_json,
                  appconfig[:session][:key] => {
                    user_id: testadmin.id,
                    group: Group.get(testadmin.group_id).name
                  }
                )

                expect(
                  Dkim.get(testdkim.id).selector
                ).to eq(testdkim.selector)
                expect(
                  Dkim.get(testdkim.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                clear_cookies

                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
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
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
                  invalid_values.to_json,
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
              invincible = create(:dkim,
                                  selector: 'foo@invincible.de',
                                  domain_id: domain.id)
              allow(Dkim).to receive(
                :get
              ).with(
                invincible.id.to_s
              ).and_return(
                invincible
              )
              allow(invincible).to receive(:update).and_return(false)
              policy = instance_double('DkimPolicy', update?: true)
              allow(policy).to receive(:update?).and_return(true)
              allow(policy).to receive(:update_with?).and_return(true)
              allow(DkimPolicy).to receive(:new).and_return(policy)

              clear_cookies

              patch(
                "/api/v#{api_version}/dkims/#{invincible.id}",
                attributes_for(:dkim, selector: 'f@invincible.de').to_json,
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
              Pundit.authorize(testadmin, Dkim, :destroy?)
            ).to be_truthy
          end

          it 'deletes the requested dkim' do
            clear_cookies

            id = testdkim.id

            delete(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testadmin.id,
                group: Group.get(testadmin.group_id).name
              }
            )

            expect(Dkim.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            clear_cookies

            delete(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
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
              invincible = create(:dkim,
                                  selector: 'foo@invincible.org')
              allow(Dkim).to receive(
                :get
              ).with(
                invincible.id.to_s
              ).and_return(
                invincible
              )
              allow(invincible).to receive(:destroy).and_return(false)
              policy = instance_double('DkimPolicy', destroy?: true)
              allow(policy).to receive(:destroy?).and_return(true)
              allow(DkimPolicy).to receive(:new).and_return(policy)

              clear_cookies

              delete(
                "/api/v#{api_version}/dkims/#{invincible.id}",
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
        let!(:testuser) { create(:user_with_dkims) }
        let!(:owner) { create(:user_with_dkims) }
        let!(:testdkim) do
          Dkim.first(domain_id: owner.domains.first.id)
        end
        let(:unauthorized_msg) { 'insufficient permissions or quota exhausted' }

        describe 'GET all' do
          it 'returns only its own dkims' do
            clear_cookies

            get(
              "/api/v#{api_version}/dkims", nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(last_response.body).to eq(
              return_json_pretty(
                Pundit.policy_scope(testuser, Dkim).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            clear_cookies

            get(
              "/api/v#{api_version}/dkims", nil,
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
              Pundit.authorize(testuser, testdkim, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            clear_cookies

            get(
              "/api/v#{api_version}/dkims/#{testdkim.id}", nil,
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
              "/api/v#{api_version}/dkims/#{testdkim.id}", nil,
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
              testdkim.destroy
              Pundit.authorize(testuser, testdkim, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            clear_cookies

            inexistent = testdkim.id
            testdkim.destroy

            get(
              "/api/v#{api_version}/dkims/#{inexistent}", nil,
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
          let(:testuser) { create(:user_with_dkims) }
          let(:domain) { testuser.domains.first }
          let(:new) do
            attributes_for(:dkim,
                           selector: "new@#{domain.name}",
                           domain_id: domain.id)
          end

          it 'authorizes the request' do
            expect(
              Pundit.authorize(testuser, Dkim, :create?)
            ).to be_truthy
            expect(
              Pundit.policy(testuser, Dkim).create_with?(new)
            ).to be_truthy
          end

          it 'does create a new dkim' do
            clear_cookies

            count = Dkim.all.count

            post(
              "/api/v#{api_version}/dkims",
              new.to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(Dkim.all.count).to eq(count + 1)
          end

          it 'returns an API Success containing the new dkim' do
            clear_cookies

            post(
              "/api/v#{api_version}/dkims",
              new.to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            new = Dkim.last

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
              "/api/v#{api_version}/dkims",
              new.to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'with using different user_id in attributes' do
            let(:testuser) { create(:user_with_dkims) }
            let(:anotheruser) { create(:user_with_domains) }

            it 'does not create a new dkim' do
              clear_cookies

              count = Dkim.all.count

              post(
                "/api/v#{api_version}/dkims",
                attributes_for(:dkim,
                               name: 'new@new.org',
                               domain_id: anotheruser.domains.first.id).to_json,
                appconfig[:session][:key] => {
                  user_id: testuser.id,
                  group: Group.get(testuser.group_id).name
                }
              )

              expect(Dkim.all.count).to eq(count)
            end

            it 'returns an API Error' do
              clear_cookies

              post(
                "/api/v#{api_version}/dkims",
                attributes_for(:dkim,
                               name: 'new@new.org',
                               domain_id: anotheruser.domains.first.id).to_json,
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
                "/api/v#{api_version}/dkims",
                attributes_for(:dkim,
                               name: 'new@new.org',
                               domain_id: anotheruser.domains.first.id).to_json,
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
              Pundit.authorize(testuser, testdkim, :update?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not update the dkim' do
            clear_cookies

            upd_attrs = attributes_for(:dkim, selector: 'foo@foo.org')
            prev_tstamp = testdkim.updated_at

            patch(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
              upd_attrs.to_json,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(testdkim.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            clear_cookies

            upd_attrs = attributes_for(:dkim, selector: 'foo@foo.org')

            patch(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
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

            upd_attrs = attributes_for(:dkim, selector: 'foo@foo.org')

            patch(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
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
              Pundit.authorize(testuser, testdkim, :destroy?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not delete the dkim' do
            clear_cookies

            delete(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
              nil,
              appconfig[:session][:key] => {
                user_id: testuser.id,
                group: Group.get(testuser.group_id).name
              }
            )

            expect(Dkim.get(testdkim.id)).not_to eq(nil)
            expect(Dkim.get(testdkim.id)).to eq(testdkim)
          end

          it 'returns an API Error' do
            clear_cookies

            delete(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
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
              "/api/v#{api_version}/dkims/#{testdkim.id}",
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
        let!(:testdkim) { create(:dkim) }
        let(:unauthorized_msg) { 'insufficient permissions or quota exhausted' }

        before(:each) do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testuser) { create(:user) }

        describe 'GET all' do
          it 'returns an an API unauthorized error' do
            get "/api/v#{api_version}/dkims"
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
            get "/api/v#{api_version}/dkims/#{testdkim.id}"
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
            inexistent = testdkim.id
            testdkim.destroy
            get "/api/v#{api_version}/dkims/#{inexistent}"
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
              "/api/v#{api_version}/dkims",
              'dkim' => attributes_for(:dkim)
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
            testdkim_foo = create(:dkim, selector: 'foo@foo.org')
            patch(
              "/api/v#{api_version}/dkims/#{testdkim_foo.id}",
              'dkim' => attributes_for(:dkim)
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
            delete "/api/v#{api_version}/dkims/#{testdkim.id}"
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
