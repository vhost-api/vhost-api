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
            get(
              "/api/v#{api_version}/dkims", nil,
              auth_headers_apikey(testadmin.id)
            )

            scope = Pundit.policy_scope(testadmin, Dkim)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testadmin.id
              )
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/dkims", nil,
              auth_headers_apikey(testadmin.id)
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
            get(
              "/api/v#{api_version}/dkims/#{testdkim.id}", nil,
              auth_headers_apikey(testadmin.id)
            )

            @user = testadmin
            expect(last_response.body).to eq(
              spec_authorized_resource(object: testdkim, user: testadmin)
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/dkims/#{testdkim.id}", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'returns an API Error' do
            inexistent = testdkim.id
            testdkim.destroy

            get(
              "/api/v#{api_version}/dkims/#{inexistent}", nil,
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

        describe 'POST /:id/regenerate' do
          it 'generates a fresh keypair' do
            testdkim.private_key = 'foo'
            testdkim.public_key = 'bar'
            testdkim.save

            post(
              "/api/v#{api_version}/dkims/#{testdkim.id}/regenerate", nil,
              auth_headers_apikey(testadmin.id)
            )

            privkey_regex = %r{
              ^-----BEGIN\x20RSA\x20PRIVATE\x20KEY-----
              .*
              -----END\x20RSA\x20PRIVATE\x20KEY-----
            }mx

            pubkey_regex = %r{
              ^-----BEGIN\x20PUBLIC\x20KEY-----
              .*
              -----END\x20PUBLIC\x20KEY-----
            }mx

            updated_dkim = Dkim.get(testdkim.id)

            expect(last_response.status).to eq(200)
            expect(updated_dkim.private_key =~ privkey_regex).to be_truthy
            expect(updated_dkim.public_key =~ pubkey_regex).to be_truthy
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
              count = Dkim.all.count

              post(
                "/api/v#{api_version}/dkims",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(Dkim.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new dkim' do
              post(
                "/api/v#{api_version}/dkims",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = Dkim.last

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
                "/api/v#{api_version}/dkims",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new dkim' do
              post(
                "/api/v#{api_version}/dkims",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
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

              it 'does not create a new dkim' do
                count = Dkim.all.count

                post(
                  "/api/v#{api_version}/dkims",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Dkim.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/dkims",
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
                error_msg += '\'{, selector: \'foo, enabled:true}\''
                post(
                  "/api/v#{api_version}/dkims?verbose",
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
                  "/api/v#{api_version}/dkims",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_dkim_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not create a new dkim' do
                count = Dkim.all.count

                post(
                  "/api/v#{api_version}/dkims",
                  invalid_dkim_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Dkim.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/dkims",
                  invalid_dkim_attrs.to_json,
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
                error_msg = 'The attribute \'foo\' is not accessible in Dkim'
                post(
                  "/api/v#{api_version}/dkims?verbose",
                  invalid_dkim_attrs.to_json,
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
                  "/api/v#{api_version}/dkims",
                  invalid_dkim_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_dkim) }

              it 'does not create a new dkim' do
                count = Dkim.all.count

                post(
                  "/api/v#{api_version}/dkims",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Dkim.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/dkims",
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
                    { field: 'selector',
                      errors: ['Selector must not be blank'] }
                  ]
                }

                post(
                  "/api/v#{api_version}/dkims?validate",
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
                  "/api/v#{api_version}/dkims",
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
              expect(
                Pundit.authorize(testadmin, Dkim, :create?)
              ).to be_truthy
            end

            it 'updates an existing dkim with new values' do
              upd_attrs = attributes_for(
                :dkim,
                selector: "foo@#{testdkim.domain.name}"
              )
              prev_tstamp = testdkim.updated_at

              patch(
                "/api/v#{api_version}/dkims/#{testdkim.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(
                Dkim.get(testdkim.id).selector
              ).to eq(upd_attrs[:selector])
              expect(
                Dkim.get(testdkim.id).updated_at
              ).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated dkim' do
              upd_attrs = attributes_for(
                :dkim,
                selector: "foo@#{testdkim.domain.name}"
              )

              patch(
                "/api/v#{api_version}/dkims/#{testdkim.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              upd_source = Dkim.get(testdkim.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  ApiResponseSuccess.new(status_code: 200,
                                         data: { object: upd_source }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              upd_attrs = attributes_for(:dkim, selector: 'foo')

              patch(
                "/api/v#{api_version}/dkims/#{testdkim.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{, selector: \'foo, enabled:true}' }

              it 'does not update the dkim' do
                prev_tstamp = testdkim.updated_at

                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  Dkim.get(testdkim.id).selector
                ).to eq(testdkim.selector)
                expect(
                  Dkim.get(testdkim.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
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
                error_msg += '\'{, selector: \'foo, enabled:true}\''
                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}?verbose",
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
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_dkim_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not update the dkim' do
                prev_tstamp = testdkim.updated_at

                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
                  invalid_dkim_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  Dkim.get(testdkim.id).selector
                ).to eq(testdkim.selector)
                expect(
                  Dkim.get(testdkim.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
                  invalid_dkim_attrs.to_json,
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
                error_msg = 'The attribute \'foo\' is not accessible in Dkim'
                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}?verbose",
                  invalid_dkim_attrs.to_json,
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
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
                  invalid_dkim_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_dkim) }

              it 'does not update the dkim' do
                prev_tstamp = testdkim.updated_at

                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  Dkim.get(testdkim.id).selector
                ).to eq(testdkim.selector)
                expect(
                  Dkim.get(testdkim.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
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
                    { field: 'selector',
                      errors: ['Selector must not be blank'] }
                  ]
                }

                patch(
                  "/api/v#{api_version}/dkims/#{testdkim.id}?validate",
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
                  "/api/v#{api_version}/dkims/#{testdkim.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end

          context 'operation failed' do
            let(:domain) { create(:domain, name: 'invincible.de') }

            # it 'returns an API Error' do
            #   invincible = create(:dkim,
            #                       selector: 'foobar',
            #                       domain_id: domain.id)
            #   allow(Dkim).to receive(:get).with(
            #     invincible.id.to_s
            #   ).and_return(invincible)
            #   policy = instance_double('DkimPolicy', update?: true)
            #   allow(policy).to receive(:update?).and_return(true)
            #   allow(policy).to receive(:update_with?).and_return(true)
            #   allow(DkimPolicy).to receive(:new).and_return(policy)
            #   dummy = build(:dkim)
            #   allow(Dkim).to receive(:new).and_return(dummy)
            #   allow(dummy).to receive(:valid?).and_return(true)

            #   allow(invincible).to receive(:update).and_raise(
            #     DataMapper::SaveFailureError
            #   )

            #   patch(
            #     "/api/v#{api_version}/dkims/#{invincible.id}",
            #     attributes_for(:dkim, selector: 'foo').to_json,
            #     auth_headers_apikey(testadmin.id)
            #   )

            #   # expect(last_response.status).to eq(500)
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
            expect(
              Pundit.authorize(testadmin, Dkim, :destroy?)
            ).to be_truthy
          end

          it 'deletes the requested dkim' do
            id = testdkim.id

            delete(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect(Dkim.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            delete(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'operation failed' do
            it 'returns an API Error' do
              invincible = create(:dkim,
                                  selector: 'invincible')
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

              delete(
                "/api/v#{api_version}/dkims/#{invincible.id}",
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
        let!(:testuser) { create(:user_with_dkims) }
        let!(:owner) { create(:user_with_dkims) }
        let!(:testdkim) do
          Dkim.first(domain_id: owner.domains.first.id)
        end

        describe 'GET all' do
          it 'returns only its own dkims' do
            get(
              "/api/v#{api_version}/dkims", nil,
              auth_headers_apikey(testuser.id)
            )

            scope = Pundit.policy_scope(testuser, Dkim)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testuser.id
              )
            )
          end

          it 'returns a valid JSON object' do
            get(
              "/api/v#{api_version}/dkims", nil,
              auth_headers_apikey(testuser.id)
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
            get(
              "/api/v#{api_version}/dkims/#{testdkim.id}", nil,
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
              "/api/v#{api_version}/dkims/#{testdkim.id}", nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'does not authorize the request' do
            expect do
              testdkim.destroy
              Pundit.authorize(testuser, testdkim, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            inexistent = testdkim.id
            testdkim.destroy

            get(
              "/api/v#{api_version}/dkims/#{inexistent}", nil,
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
            count = Dkim.all.count

            post(
              "/api/v#{api_version}/dkims",
              new.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect(Dkim.all.count).to eq(count + 1)
          end

          it 'returns an API Success containing the new dkim' do
            post(
              "/api/v#{api_version}/dkims",
              new.to_json,
              auth_headers_apikey(testuser.id)
            )

            new = Dkim.last

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
              "/api/v#{api_version}/dkims",
              new.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'with using different user_id in attributes' do
            let(:testuser) { create(:user_with_dkims) }
            let(:anotheruser) { create(:user_with_domains) }

            it 'does not create a new dkim' do
              count = Dkim.all.count

              post(
                "/api/v#{api_version}/dkims",
                attributes_for(:dkim,
                               name: 'new@new.org',
                               domain_id: anotheruser.domains.first.id).to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(Dkim.all.count).to eq(count)
            end

            it 'returns an API Error' do
              post(
                "/api/v#{api_version}/dkims",
                attributes_for(:dkim,
                               name: 'new@new.org',
                               domain_id: anotheruser.domains.first.id).to_json,
                auth_headers_apikey(testuser.id)
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
                "/api/v#{api_version}/dkims",
                attributes_for(:dkim,
                               name: 'new@new.org',
                               domain_id: anotheruser.domains.first.id).to_json,
                auth_headers_apikey(testuser.id)
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
            upd_attrs = attributes_for(:dkim, selector: 'foo')
            prev_tstamp = testdkim.updated_at

            patch(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
              upd_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect(testdkim.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            upd_attrs = attributes_for(:dkim, selector: 'foo')

            patch(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
              upd_attrs.to_json,
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
            upd_attrs = attributes_for(:dkim, selector: 'foo')

            patch(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
              upd_attrs.to_json,
              auth_headers_apikey(testuser.id)
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
            delete(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect(Dkim.get(testdkim.id)).not_to eq(nil)
            expect(Dkim.get(testdkim.id)).to eq(testdkim)
          end

          it 'returns an API Error' do
            delete(
              "/api/v#{api_version}/dkims/#{testdkim.id}",
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
              "/api/v#{api_version}/dkims/#{testdkim.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end
      end

      context 'by an unauthenticated user' do
        let!(:testdkim) { create(:dkim) }

        before(:each) do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testuser) { create(:user) }

        describe 'GET all' do
          it 'returns an an API authentication error' do
            get "/api/v#{api_version}/dkims"
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
            get "/api/v#{api_version}/dkims/#{testdkim.id}"
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
            inexistent = testdkim.id
            testdkim.destroy
            get "/api/v#{api_version}/dkims/#{inexistent}"
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
              "/api/v#{api_version}/dkims",
              'dkim' => attributes_for(:dkim)
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
            testdkim_foo = create(:dkim, selector: 'foo')
            patch(
              "/api/v#{api_version}/dkims/#{testdkim_foo.id}",
              'dkim' => attributes_for(:dkim)
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
            delete "/api/v#{api_version}/dkims/#{testdkim.id}"
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
