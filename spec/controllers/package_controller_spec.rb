# frozen_string_literal: true

require File.expand_path('../spec_helper.rb', __dir__)

# rubocop:disable Metrics/BlockLength, RSpec/NestedGroups, RSpec/LetSetup
# rubocop:disable RSpec/MultipleExpectations, Security/YAMLLoad
# rubocop:disable RSpec/EmptyLineAfterFinalLet
# rubocop:disable RSpec/HookArgument
describe 'VHost-API Package Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w[1]

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      context 'when by an admin user' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:usergroup) { create(:group, name: 'user') }
        let(:testpackage) { create(:package, name: 'Test') }
        let(:testadmin) { create(:admin, password: 'secret') }

        describe 'GET all' do
          it 'authorizes (policies) and returns an array of packages' do
            get(
              "/api/v#{api_version}/packages", nil,
              auth_headers_apikey(testadmin.id)
            )
            scope = Pundit.policy_scope(testadmin, Package)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testadmin.id
              )
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/packages", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'authorizes the request by using the policies' do
            expect(
              Pundit.authorize(testadmin, testpackage, :show?)
            ).to be_truthy
          end

          it 'returns the package' do
            get(
              "/api/v#{api_version}/packages/#{testpackage.id}", nil,
              auth_headers_apikey(testadmin.id)
            )

            @user = testadmin
            expect(last_response.body).to eq(
              spec_authorized_resource(object: testpackage, user: testadmin)
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/packages/#{testpackage.id}", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'returns an API Error' do
            inexistent = testpackage.id
            testpackage.destroy

            get(
              "/api/v#{api_version}/packages/#{inexistent}", nil,
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
          context 'when with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(
                Pundit.authorize(testadmin, Package, :create?)
              ).to be_truthy
            end

            it 'creates a new package' do
              count = Package.all(user_id: testadmin.id).count

              post(
                "/api/v#{api_version}/packages",
                attributes_for(:package, name: 'new').to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(Package.all(user_id: testadmin.id).count).to eq(count + 1)
            end

            it 'returns an API Success containing the new package' do
              post(
                "/api/v#{api_version}/packages",
                attributes_for(:package, name: 'new').to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = Package.last

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
                "/api/v#{api_version}/packages",
                attributes_for(:package, name: 'new').to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new package' do
              post(
                "/api/v#{api_version}/packages",
                attributes_for(:package, name: 'new').to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = Package.last

              expect(last_response.location).to eq(
                "http://example.org/api/v#{api_version}/packages/#{new.id}"
              )
            end
          end

          context 'when with malformed request data' do
            context 'when invalid json' do
              let(:invalid_json) { '{ , name: \'foo, enabled: true }' }

              it 'does not create a new package' do
                count = Package.all(user_id: testadmin.id).count

                post(
                  "/api/v#{api_version}/packages",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Package.all(user_id: testadmin.id).count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/packages",
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
                  "/api/v#{api_version}/packages?verbose",
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
                  "/api/v#{api_version}/packages",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when invalid attributes' do
              let(:invalid_package_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not create a new package' do
                count = Package.all(user_id: testadmin.id).count

                post(
                  "/api/v#{api_version}/packages",
                  invalid_package_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Package.all(user_id: testadmin.id).count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/packages",
                  invalid_package_attrs.to_json,
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
                error_msg = 'The attribute \'foo\' is not accessible in Package'
                post(
                  "/api/v#{api_version}/packages?verbose",
                  invalid_package_attrs.to_json,
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
                  "/api/v#{api_version}/packages",
                  invalid_package_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_package) }

              it 'does not create a new package' do
                count = Package.all(user_id: testadmin.id).count

                post(
                  "/api/v#{api_version}/packages",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Package.all(user_id: testadmin.id).count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/packages",
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
                    { field: 'name',
                      errors: ['Name must not be blank'] },
                    { field: 'price_unit',
                      errors: ['Price unit must not be blank'] },
                    { field: 'user_id',
                      errors: ['User must not be blank'] }
                  ]
                }

                post(
                  "/api/v#{api_version}/packages?validate",
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
                  "/api/v#{api_version}/packages",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end
        end

        describe 'PATCH' do
          context 'when with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(
                Pundit.authorize(testadmin, Package, :create?)
              ).to be_truthy
            end

            it 'updates an existing package with new values' do
              upd_attrs = attributes_for(:package, name: 'foo')
              prev_tstamp = testpackage.updated_at

              sleep 1.0

              patch(
                "/api/v#{api_version}/packages/#{testpackage.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(Package.get(testpackage.id).name).to eq(upd_attrs[:name])
              expect(Package.get(testpackage.id).updated_at).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated package' do
              updated_attrs = attributes_for(:package, name: 'foo')

              patch(
                "/api/v#{api_version}/packages/#{testpackage.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              upd_user = Package.get(testpackage.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  ApiResponseSuccess.new(status_code: 200,
                                         data: { object: upd_user }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              updated_attrs = attributes_for(:package, name: 'foo')

              patch(
                "/api/v#{api_version}/packages/#{testpackage.id}",
                updated_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'when with malformed request data' do
            context 'when invalid json' do
              let(:invalid_json) { '{ , name: \'foo, enabled: true }' }

              it 'does not update the package' do
                prev_tstmp = testpackage.updated_at

                patch(
                  "/api/v#{api_version}/packages/#{testpackage.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Package.get(testpackage.id).name).to eq(testpackage.name)
                expect(Package.get(testpackage.id).updated_at).to eq(prev_tstmp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/packages/#{testpackage.id}",
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
                patch(
                  "/api/v#{api_version}/packages/#{testpackage.id}?verbose",
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
                  "/api/v#{api_version}/packages/#{testpackage.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when invalid attributes' do
              let(:invalid_package_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not update the package' do
                prev_tstmp = testpackage.updated_at

                patch(
                  "/api/v#{api_version}/packages/#{testpackage.id}",
                  invalid_package_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Package.get(testpackage.id).name).to eq(testpackage.name)
                expect(Package.get(testpackage.id).updated_at).to eq(prev_tstmp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/packages/#{testpackage.id}",
                  invalid_package_attrs.to_json,
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
                error_msg = 'The attribute \'foo\' is not accessible in Package'
                patch(
                  "/api/v#{api_version}/packages/#{testpackage.id}?verbose",
                  invalid_package_attrs.to_json,
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
                  "/api/v#{api_version}/packages/#{testpackage.id}",
                  invalid_package_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'when with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_package) }

              it 'does not update the package' do
                prev_tstmp = testpackage.updated_at

                patch(
                  "/api/v#{api_version}/packages/#{testpackage.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(Package.get(testpackage.id).name).to eq(testpackage.name)
                expect(Package.get(testpackage.id).updated_at).to eq(prev_tstmp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/packages/#{testpackage.id}",
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
                    { field: 'name',
                      errors: ['Name must not be blank'] },
                    { field: 'price_unit',
                      errors: ['Price unit must not be blank'] }
                  ]
                }

                patch(
                  "/api/v#{api_version}/packages/#{testpackage.id}?validate",
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
                  "/api/v#{api_version}/packages/#{testpackage.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end
        end

        describe 'DELETE' do
          it 'authorizes the request by using the policies' do
            expect(Pundit.authorize(testadmin, Package, :destroy?)).to be_truthy
          end

          it 'deletes the requested package' do
            id = testpackage.id

            delete(
              "/api/v#{api_version}/packages/#{testpackage.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect(Package.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            delete(
              "/api/v#{api_version}/packages/#{testpackage.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'when operation failed' do
            it 'returns an API Error' do
              invinciblepackage = create(:package, name: 'invincible')
              allow(Package).to receive(
                :get
              ).with(
                invinciblepackage.id.to_s
              ).and_return(
                invinciblepackage
              )
              allow(Package).to receive(
                :get
              ).with(
                testadmin.id
              ).and_return(
                testadmin
              )
              allow(invinciblepackage).to receive(:destroy).and_return(false)

              policy = instance_double('PackagePolicy', destroy?: true)
              allow(policy).to receive(:destroy?).and_return(true)
              allow(PackagePolicy).to receive(:new).and_return(policy)

              delete(
                "/api/v#{api_version}/packages/#{invinciblepackage.id}",
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
        let!(:usergroup) { create(:group, name: 'user') }
        let(:testadmin) { create(:admin) }
        let!(:testpackage) { create(:package) }
        let!(:user) { create(:user, name: 'herpderp') }
        before(:each) do
          user.packages = [testpackage]
          user.save
        end

        describe 'GET all' do
          it 'returns no package' do
            get(
              "/api/v#{api_version}/packages", nil,
              auth_headers_apikey(user.id)
            )

            expect(last_response.body).to eq(
              spec_apiresponse(
                ApiResponseSuccess.new(
                  data: { objects: {} }
                )
              )
            )
          end

          it 'returns a valid JSON object' do
            get(
              "/api/v#{api_version}/packages", nil,
              auth_headers_apikey(user.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          let(:otherpackage) { create(:package, user_id: testadmin.id) }
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(user, otherpackage, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            get(
              "/api/v#{api_version}/packages/#{otherpackage.id}", nil,
              auth_headers_apikey(user.id)
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
              "/api/v#{api_version}/packages/#{otherpackage.id}", nil,
              auth_headers_apikey(user.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          let(:otherpackage) { create(:package) }
          it 'does not authorize the request' do
            expect do
              otherpackage.users = []
              otherpackage.save
              otherpackage.destroy
              Pundit.authorize(user, otherpackage, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            inexistent = otherpackage.id
            otherpackage.users = []
            otherpackage.save
            otherpackage.destroy

            get(
              "/api/v#{api_version}/packages/#{inexistent}", nil,
              auth_headers_apikey(user.id)
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
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(user, Package, :create?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not create a new package' do
            count = Package.all.count

            post(
              "/api/v#{api_version}/packages",
              attributes_for(:package, name: 'new').to_json,
              auth_headers_apikey(user.id)
            )

            expect(Package.all.count).to eq(count)
          end

          it 'returns an API Error' do
            post(
              "/api/v#{api_version}/packages",
              attributes_for(:package, name: 'new').to_json,
              auth_headers_apikey(user.id)
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
              "/api/v#{api_version}/packages",
              attributes_for(:package, name: 'new').to_json,
              auth_headers_apikey(user.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'PATCH' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(user, testpackage, :update?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not update the package' do
            updated_attrs = attributes_for(:package, name: 'foo')
            prev_tstamp = testpackage.updated_at

            patch(
              "/api/v#{api_version}/packages/#{testpackage.id}",
              updated_attrs.to_json,
              auth_headers_apikey(user.id)
            )

            expect(testpackage.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            updated_attrs = attributes_for(:package, name: 'foo')

            patch(
              "/api/v#{api_version}/packages/#{testpackage.id}",
              updated_attrs.to_json,
              auth_headers_apikey(user.id)
            )

            expect(last_response.status).to eq(403)
            expect(last_response.body).to eq(
              spec_json_pretty(
                api_error(ApiErrors.[](:unauthorized)).to_json
              )
            )
          end

          it 'returns a valid JSON object' do
            updated_attrs = attributes_for(:package, name: 'foo')

            patch(
              "/api/v#{api_version}/packages/#{testpackage.id}",
              updated_attrs.to_json,
              auth_headers_apikey(user.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'DELETE' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(user, testpackage, :destroy?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not delete the package' do
            delete(
              "/api/v#{api_version}/packages/#{testpackage.id}",
              nil,
              auth_headers_apikey(user.id)
            )

            expect(Package.get(testpackage.id)).not_to eq(nil)
            expect(Package.get(testpackage.id)).to eq(testpackage)
          end

          it 'returns an API Error' do
            delete(
              "/api/v#{api_version}/packages/#{testpackage.id}",
              nil,
              auth_headers_apikey(user.id)
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
              "/api/v#{api_version}/packages/#{testpackage.id}",
              nil,
              auth_headers_apikey(user.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end
      end

      context 'when by an unauthenticated (thus authentication_failed) user' do
        before(:each) do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testpackage) { create(:package) }

        describe 'GET all' do
          it 'returns an an API authentication failed error' do
            get "/api/v#{api_version}/packages"
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
            get "/api/v#{api_version}/packages/#{testpackage.id}"
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
            inexistent = testpackage.id
            testpackage.destroy
            get "/api/v#{api_version}/packages/#{inexistent}"
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
              "/api/v#{api_version}/packages",
              'package' => attributes_for(:package)
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
            testpackage_foo = create(:package, name: 'foo')
            patch(
              "/api/v#{api_version}/packages/#{testpackage_foo.id}",
              'package' => attributes_for(:package)
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
            delete "/api/v#{api_version}/packages/#{testpackage.id}"
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
# rubocop:enable RSpec/EmptyLineAfterFinalLet
# rubocop:enable RSpec/HookArgument
