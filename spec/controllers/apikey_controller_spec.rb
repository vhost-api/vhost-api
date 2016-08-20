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
            get(
              "/api/v#{api_version}/apikeys", nil,
              auth_headers_apikey(testadmin.id)
            )

            scope = Pundit.policy_scope(testadmin, Apikey)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testadmin.id
              )
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/apikeys", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'authorizes the request by using the policies' do
            expect(Pundit.authorize(testadmin, testapikey, :show?)).to be_truthy
          end

          it 'returns the apikey' do
            get(
              "/api/v#{api_version}/apikeys/#{testapikey.id}", nil,
              auth_headers_apikey(testadmin.id)
            )

            @user = testadmin
            expect(last_response.body).to eq(
              spec_authorized_resource(object: testapikey, user: testadmin)
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/apikeys/#{testapikey.id}", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'returns an API Error' do
            inexistent = testapikey.id
            testapikey.destroy

            get(
              "/api/v#{api_version}/apikeys/#{inexistent}", nil,
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
            let(:apikey_attrs) { attributes_for(:apikey) }

            it 'authorizes the request by using the policies' do
              expect(Pundit.authorize(testadmin, Apikey, :create?)).to be_truthy
            end

            it 'creates a new apikey' do
              count = Apikey.all.count

              post(
                "/api/v#{api_version}/apikeys",
                apikey_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              # need to expect two more than counted before du to
              # the auth_headers_apikey call will create a fresh one
              expect(Apikey.all.count).to eq(count + 2)
            end

            it 'returns an API Success containing the new apikey' do
              post(
                "/api/v#{api_version}/apikeys",
                apikey_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = Apikey.last.as_json
              new[:apikey] = apikey_attrs[:apikey]

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
                "/api/v#{api_version}/apikeys",
                apikey_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new apikey' do
              post(
                "/api/v#{api_version}/apikeys",
                apikey_attrs.to_json,
                auth_headers_apikey(testadmin.id)
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

              it 'does not create a new apikey' do
                count = Apikey.all.count

                post(
                  "/api/v#{api_version}/apikeys",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                # need to expect one more than counted before du to
                # the auth_headers_apikey call will create a fresh one
                expect(Apikey.all.count).to eq(count + 1)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/apikeys",
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
                error_msg += '\'{ , name: \'foo, enabled: true }\''
                post(
                  "/api/v#{api_version}/apikeys?verbose",
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
                  "/api/v#{api_version}/apikeys",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_apikey_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not create a new apikey' do
                count = Apikey.all.count

                post(
                  "/api/v#{api_version}/apikeys",
                  invalid_apikey_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                # need to expect one more than counted before du to
                # the auth_headers_apikey call will create a fresh one
                expect(Apikey.all.count).to eq(count + 1)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/apikeys",
                  invalid_apikey_attrs.to_json,
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
                error_msg += 'Apikey'
                post(
                  "/api/v#{api_version}/apikeys?verbose",
                  invalid_apikey_attrs.to_json,
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
                  "/api/v#{api_version}/apikeys",
                  invalid_apikey_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_apikey) }

              it 'does not create a new apikey' do
                count = Apikey.all.count

                post(
                  "/api/v#{api_version}/apikeys",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                # need to expect one more than counted before du to
                # the auth_headers_apikey call will create a fresh one
                expect(Apikey.all.count).to eq(count + 1)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/apikeys",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:apikey_length)).to_json
                  )
                )
              end

              it 'shows a validate error message when using validate param' do
                invalid_values = attributes_for(:apikey, user_id: nil)
                errors = {
                  validation: [
                    { field: 'user_id',
                      errors: ['User must not be blank'] }
                  ]
                }

                post(
                  "/api/v#{api_version}/apikeys?validate",
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
                  "/api/v#{api_version}/apikeys",
                  invalid_values.to_json,
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
              expect(Pundit.authorize(testadmin, Apikey, :create?)).to be_truthy
            end

            it 'updates an existing apikey with new values' do
              updated_attrs = attributes_for(:apikey, comment: 'herpderp')
              prev_tstamp = testapikey.updated_at

              patch(
                "/api/v#{api_version}/apikeys/#{testapikey.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(
                Apikey.get(testapikey.id).comment
              ).to eq(updated_attrs[:comment])
              expect(Apikey.get(testapikey.id).updated_at).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated apikey' do
              updated_attrs = attributes_for(:apikey, comment: 'herpderp')

              patch(
                "/api/v#{api_version}/apikeys/#{testapikey.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              upd_user = Apikey.get(testapikey.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  ApiResponseSuccess.new(status_code: 200,
                                         data: { object: upd_user }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              updated_attrs = attributes_for(:apikey, comment: 'herpderp')

              patch(
                "/api/v#{api_version}/apikeys/#{testapikey.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{, comment:\'foo, enabled: true }' }

              it 'does not update the apikey' do
                prev_tstamp = testapikey.updated_at

                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  Apikey.get(testapikey.id).comment
                ).to eq(testapikey.comment)
                expect(Apikey.get(testapikey.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
                error_msg += '\'{, comment:\'foo, enabled: true }\''
                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}?verbose",
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
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_apikey_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not update the apikey' do
                prev_tstamp = testapikey.updated_at

                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
                  invalid_apikey_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  Apikey.get(testapikey.id).comment
                ).to eq(testapikey.comment)
                expect(Apikey.get(testapikey.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
                  invalid_apikey_attrs.to_json,
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
                error_msg += 'Apikey'
                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}?verbose",
                  invalid_apikey_attrs.to_json,
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
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
                  invalid_apikey_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_apikey) }

              it 'does not update the apikey' do
                prev_tstamp = testapikey.updated_at

                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  Apikey.get(testapikey.id).apikey
                ).to eq(testapikey.apikey)
                expect(Apikey.get(testapikey.id).updated_at).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(last_response.status).to eq(422)
                expect(last_response.body).to eq(
                  spec_json_pretty(
                    api_error(ApiErrors.[](:apikey_length)).to_json
                  )
                )
              end

              it 'shows a validate error message when using validate param' do
                invalid_values = attributes_for(:apikey, user_id: nil)
                errors = {
                  validation: [
                    { field: 'user_id',
                      errors: ['User must not be blank'] }
                  ]
                }

                patch(
                  "/api/v#{api_version}/apikeys/#{testapikey.id}?validate",
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
                  "/api/v#{api_version}/apikeys/#{testapikey.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end

          context 'operation failed' do
            # it 'returns an API Error' do
            #   invincibleapikey = create(:apikey)
            #   allow(Apikey).to receive(
            #     :get
            #   ).with(
            #     invincibleapikey.id.to_s
            #   ).and_return(
            #     invincibleapikey
            #   )
            #   allow(invincibleapikey).to receive(:update).and_return(false)
            #   policy = instance_double('ApikeyPolicy', update?: true)
            #   allow(policy).to receive(:update?).and_return(true)
            #   allow(policy).to receive(:update_with?).and_return(true)
            #   allow(ApikeyPolicy).to receive(:new).and_return(policy)

            #   patch(
            #     "/api/v#{api_version}/apikeys/#{invincibleapikey.id}",
            #     attributes_for(:apikey, comment: 'foobar').to_json,
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
          it 'authorizes the request by using the policies' do
            expect(Pundit.authorize(testadmin, Apikey, :destroy?)).to be_truthy
          end

          it 'deletes the requested apikey' do
            id = testapikey.id

            delete(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect(Apikey.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            delete(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'operation failed' do
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

              delete(
                "/api/v#{api_version}/apikeys/#{invincibleapikey.id}",
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
        let!(:testuser) { create(:user_with_apikeys) }
        let!(:owner) { create(:user_with_apikeys) }
        let!(:testapikey) { owner.apikeys.first }

        describe 'GET all' do
          it 'returns only its own apikeys' do
            get(
              "/api/v#{api_version}/apikeys", nil,
              auth_headers_apikey(testuser.id)
            )

            scope = Pundit.policy_scope(testuser, Apikey)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testuser.id
              )
            )
          end

          it 'returns a valid JSON object' do
            get(
              "/api/v#{api_version}/apikeys", nil,
              auth_headers_apikey(testuser.id)
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
            get(
              "/api/v#{api_version}/apikeys/#{testapikey.id}", nil,
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
              "/api/v#{api_version}/apikeys/#{testapikey.id}", nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'does not authorize the request' do
            expect do
              testapikey.destroy
              Pundit.authorize(testuser, testapikey, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            inexistent = testapikey.id
            testapikey.destroy

            get(
              "/api/v#{api_version}/apikeys/#{inexistent}", nil,
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
            let(:testuser) { create(:user_with_exhausted_apikey_quota) }
            it 'does not authorize the request' do
              expect do
                Pundit.authorize(testuser, Apikey, :create?)
              end.to raise_exception(Pundit::NotAuthorizedError)
            end

            it 'does not create a new apikey' do
              count = Apikey.all.count

              post(
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey).to_json,
                auth_headers_apikey(testuser.id)
              )

              # need to expect one more than counted before du to
              # the auth_headers_apikey call will create a fresh one
              expect(Apikey.all.count).to eq(count + 1)
            end

            it 'returns an API Error' do
              post(
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey).to_json,
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
                "/api/v#{api_version}/apikeys",
                attributes_for(:apikey).to_json,
                auth_headers_apikey(testuser.id)
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
              count = Apikey.all.count

              post(
                "/api/v#{api_version}/apikeys",
                newapikey.to_json,
                auth_headers_apikey(testuser.id)
              )

              # need to expect two more than counted before du to
              # the auth_headers_apikey call will create a fresh one
              expect(Apikey.all.count).to eq(count + 2)
            end

            it 'returns an API Success containing the new apikey' do
              post(
                "/api/v#{api_version}/apikeys",
                newapikey.to_json,
                auth_headers_apikey(testuser.id)
              )

              new = Apikey.last.as_json
              new[:apikey] = newapikey[:apikey]

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
                "/api/v#{api_version}/apikeys",
                newapikey.to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with using different user_id in attributes' do
            let(:testuser) { create(:user_with_apikeys) }
            let(:anotheruser) { create(:user) }
            let(:unauthorized_attrs) do
              attributes_for(
                :apikey,
                user_id: anotheruser.id
              )
            end

            it 'does not create a new apikey' do
              count = Apikey.all.count

              post(
                "/api/v#{api_version}/apikeys",
                unauthorized_attrs.to_json,
                auth_headers_apikey(testuser.id)
              )

              # need to expect one more than counted before du to
              # the auth_headers_apikey call will create a fresh one
              expect(Apikey.all.count).to eq(count + 1)
            end

            it 'returns an API Error' do
              post(
                "/api/v#{api_version}/apikeys",
                unauthorized_attrs.to_json,
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
                "/api/v#{api_version}/apikeys",
                unauthorized_attrs.to_json,
                auth_headers_apikey(testuser.id)
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
            updated_attrs = attributes_for(:apikey)
            prev_tstamp = testapikey.updated_at

            patch(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect(testapikey.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            updated_attrs = attributes_for(:apikey)

            patch(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
            updated_attrs = attributes_for(:apikey)

            patch(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
              updated_attrs.to_json,
              auth_headers_apikey(testuser.id)
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
            delete(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect(Apikey.get(testapikey.id)).not_to eq(nil)
            expect(Apikey.get(testapikey.id)).to eq(testapikey)
          end

          it 'returns an API Error' do
            delete(
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
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
              "/api/v#{api_version}/apikeys/#{testapikey.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end
      end

      context 'by an unauthenticated user' do
        let!(:testapikey) { create(:apikey) }

        before(:each) do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testuser) { create(:user) }

        describe 'GET all' do
          it 'returns an an API authentication error' do
            get "/api/v#{api_version}/apikeys"
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
            get "/api/v#{api_version}/apikeys/#{testapikey.id}"
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
            inexistent = testapikey.id
            testapikey.destroy
            get "/api/v#{api_version}/apikeys/#{inexistent}"
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
              "/api/v#{api_version}/apikeys",
              'apikey' => attributes_for(:apikey)
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
            testapikey_foo = create(:apikey)
            patch(
              "/api/v#{api_version}/apikeys/#{testapikey_foo.id}",
              'apikey' => attributes_for(:apikey)
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
            delete "/api/v#{api_version}/apikeys/#{testapikey.id}"
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
