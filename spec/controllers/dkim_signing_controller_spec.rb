# frozen_string_literal: true
require File.expand_path '../../spec_helper.rb', __FILE__

describe 'VHost-API DkimSigning Controller' do
  let(:appconfig) { YAML.load(File.read('config/appconfig.yml'))['test'] }

  api_versions = %w(1)

  api_versions.each do |api_version|
    context "API version #{api_version}" do
      context 'by an admin user' do
        let!(:admingroup) { create(:group, name: 'admin') }
        let!(:resellergroup) { create(:group, name: 'reseller') }
        let!(:testdkimsigning) { create(:dkimsigning) }
        let!(:testadmin) { create(:admin, password: 'secret') }

        describe 'GET all' do
          it 'authorizes (policies) and returns an array of dkimsignings' do
            get(
              "/api/v#{api_version}/dkimsignings", nil,
              auth_headers_apikey(testadmin.id)
            )

            scope = Pundit.policy_scope(testadmin, DkimSigning)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testadmin.id
              )
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/dkimsignings", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'authorizes the request by using the policies' do
            expect(
              Pundit.authorize(testadmin, testdkimsigning, :show?)
            ).to be_truthy
          end

          it 'returns the dkimsigning' do
            get(
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}", nil,
              auth_headers_apikey(testadmin.id)
            )

            @user = testadmin
            expect(last_response.body).to eq(
              spec_authorized_resource(object: testdkimsigning, user: testadmin)
            )
          end

          it 'returns valid JSON' do
            get(
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}", nil,
              auth_headers_apikey(testadmin.id)
            )
            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'returns an API Error' do
            inexistent = testdkimsigning.id
            testdkimsigning.destroy

            get(
              "/api/v#{api_version}/dkimsignings/#{inexistent}", nil,
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
          let(:domain) do
            create(:domain, name: 'new.org', user_id: testadmin.id)
          end
          let(:dkim) do
            create(:dkim, domain_id: domain.id)
          end
          let(:author) { domain.name }
          let(:new_attributes) do
            attributes_for(:dkimsigning,
                           author: author,
                           dkim_id: dkim.id)
          end

          context 'with valid attributes' do
            it 'authorizes the request by using the policies' do
              expect(
                Pundit.authorize(testadmin, DkimSigning, :create?)
              ).to be_truthy
            end

            it 'creates a new dkimsigning' do
              count = DkimSigning.all.count

              post(
                "/api/v#{api_version}/dkimsignings",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(DkimSigning.all.count).to eq(count + 1)
            end

            it 'returns an API Success containing the new dkimsigning' do
              post(
                "/api/v#{api_version}/dkimsignings",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = DkimSigning.last

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
                "/api/v#{api_version}/dkimsignings",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end

            it 'redirects to the new dkimsigning' do
              post(
                "/api/v#{api_version}/dkimsignings",
                new_attributes.to_json,
                auth_headers_apikey(testadmin.id)
              )

              new = DkimSigning.last

              expect(last_response.location).to eq(
                "http://example.org/api/v#{api_version}/dkimsignings/#{new.id}"
              )
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{, author: \'foo, enabled:true}' }

              it 'does not create a new dkimsigning' do
                count = DkimSigning.all.count

                post(
                  "/api/v#{api_version}/dkimsignings",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(DkimSigning.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/dkimsignings",
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
                  "/api/v#{api_version}/dkimsignings",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_dkimsigning_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not create a new dkimsigning' do
                count = DkimSigning.all.count

                post(
                  "/api/v#{api_version}/dkimsignings",
                  invalid_dkimsigning_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(DkimSigning.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/dkimsignings",
                  invalid_dkimsigning_attrs.to_json,
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
                error_msg += 'DkimSigning'
                post(
                  "/api/v#{api_version}/dkimsignings?verbose",
                  invalid_dkimsigning_attrs.to_json,
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
                  "/api/v#{api_version}/dkimsignings",
                  invalid_dkimsigning_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_dkimsigning) }

              it 'does not create a new dkimsigning' do
                count = DkimSigning.all.count

                post(
                  "/api/v#{api_version}/dkimsignings",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(DkimSigning.all.count).to eq(count)
              end

              it 'returns an API Error' do
                post(
                  "/api/v#{api_version}/dkimsignings",
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
                  "/api/v#{api_version}/dkimsignings",
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
                Pundit.authorize(testadmin, DkimSigning, :create?)
              ).to be_truthy
            end

            it 'updates an existing dkimsigning with new values' do
              upd_attrs = attributes_for(
                :dkimsigning,
                author: "foo@#{testdkimsigning.dkim.domain.name}"
              )
              prev_tstamp = testdkimsigning.updated_at

              patch(
                "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect(
                DkimSigning.get(testdkimsigning.id).author
              ).to eq(upd_attrs[:author])
              expect(
                DkimSigning.get(testdkimsigning.id).updated_at
              ).to be > prev_tstamp
            end

            it 'returns an API Success containing the updated dkimsigning' do
              upd_attrs = attributes_for(
                :dkimsigning,
                author: "foo@#{testdkimsigning.dkim.domain.name}"
              )

              patch(
                "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              upd_dksgn = DkimSigning.get(testdkimsigning.id)

              expect(last_response.status).to eq(200)
              expect(last_response.body).to eq(
                spec_json_pretty(
                  ApiResponseSuccess.new(status_code: 200,
                                         data: { object: upd_dksgn }).to_json
                )
              )
            end

            it 'returns a valid JSON object' do
              upd_attrs = attributes_for(:dkimsigning, author: 'foo@foo.org')

              patch(
                "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
                upd_attrs.to_json,
                auth_headers_apikey(testadmin.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end

          context 'with malformed request data' do
            context 'invalid json' do
              let(:invalid_json) { '{, author: \'foo, enabled:true}' }

              it 'does not update the dkimsigning' do
                prev_tstamp = testdkimsigning.updated_at

                patch(
                  "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  DkimSigning.get(testdkimsigning.id).author
                ).to eq(testdkimsigning.author)
                expect(
                  DkimSigning.get(testdkimsigning.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
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
                  "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
                  invalid_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'invalid attributes' do
              let(:invalid_user_attrs) { { foo: 'bar', disabled: 1234 } }

              it 'does not update the dkimsigning' do
                prev_tstamp = testdkimsigning.updated_at

                patch(
                  "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
                  invalid_user_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  DkimSigning.get(testdkimsigning.id).author
                ).to eq(testdkimsigning.author)
                expect(
                  DkimSigning.get(testdkimsigning.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
                  invalid_user_attrs.to_json,
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
                  "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
                  invalid_user_attrs.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end

            context 'with invalid values' do
              let(:invalid_values) { attributes_for(:invalid_dkimsigning) }

              it 'does not update the dkimsigning' do
                prev_tstamp = testdkimsigning.updated_at

                patch(
                  "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )

                expect(
                  DkimSigning.get(testdkimsigning.id).author
                ).to eq(testdkimsigning.author)
                expect(
                  DkimSigning.get(testdkimsigning.id).updated_at
                ).to eq(prev_tstamp)
              end

              it 'returns an API Error' do
                patch(
                  "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
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
                  "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
                  invalid_values.to_json,
                  auth_headers_apikey(testadmin.id)
                )
                expect { JSON.parse(last_response.body) }.not_to raise_exception
              end
            end
          end

          context 'operation failed' do
            let(:domain) { create(:domain, name: 'invincible.de') }
            let(:dkim) { create(:dkim, domain_id: domain.id) }

            # it 'returns an API Error' do
            #   invincible = create(:dkimsigning,
            #                       author: 'foo@invincible.de',
            #                       dkim_id: dkim.id)
            #   allow(DkimSigning).to receive(
            #     :get
            #   ).with(
            #     invincible.id.to_s
            #   ).and_return(
            #     invincible
            #   )
            #   allow(invincible).to receive(:update).and_return(false)
            #   policy = instance_double('DkimSigningPolicy', update?: true)
            #   allow(policy).to receive(:update?).and_return(true)
            #   allow(policy).to receive(:update_with?).and_return(true)
            #   allow(DkimSigningPolicy).to receive(:new).and_return(policy)

            #   patch(
            #     "/api/v#{api_version}/dkimsignings/#{invincible.id}",
            #     attributes_for(:dkimsigning, author: 'invincible.de').to_json,
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
            expect(
              Pundit.authorize(testadmin, DkimSigning, :destroy?)
            ).to be_truthy
          end

          it 'deletes the requested dkimsigning' do
            id = testdkimsigning.id

            delete(
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect(DkimSigning.get(id)).to eq(nil)
          end

          it 'returns a valid JSON object' do
            delete(
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
              nil,
              auth_headers_apikey(testadmin.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'operation failed' do
            it 'returns an API Error' do
              invincible = create(:dkimsigning,
                                  author: 'foo@invincible.org')
              allow(DkimSigning).to receive(
                :get
              ).with(
                invincible.id.to_s
              ).and_return(
                invincible
              )
              allow(invincible).to receive(:destroy).and_return(false)
              policy = instance_double('DkimSigningPolicy', destroy?: true)
              allow(policy).to receive(:destroy?).and_return(true)
              allow(DkimSigningPolicy).to receive(:new).and_return(policy)

              delete(
                "/api/v#{api_version}/dkimsignings/#{invincible.id}",
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
        let!(:testuser) { create(:user_with_dkimsignings) }
        let!(:owner) { create(:user_with_dkimsignings) }
        let!(:testdkimsigning) do
          DkimSigning.first(dkim_id: owner.domains.first.dkims.first.id)
        end

        describe 'GET all' do
          it 'returns only its own dkimsignings' do
            get(
              "/api/v#{api_version}/dkimsignings", nil,
              auth_headers_apikey(testuser.id)
            )

            scope = Pundit.policy_scope(testuser, DkimSigning)

            expect(last_response.body).to eq(
              spec_authorized_collection(
                object: scope,
                uid: testuser.id
              )
            )
          end

          it 'returns a valid JSON object' do
            get(
              "/api/v#{api_version}/dkimsignings", nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET one' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testdkimsigning, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            get(
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}", nil,
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
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}", nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'GET inexistent record' do
          it 'does not authorize the request' do
            expect do
              testdkimsigning.destroy
              Pundit.authorize(testuser, testdkimsigning, :show?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'returns an API Error' do
            inexistent = testdkimsigning.id
            testdkimsigning.destroy

            get(
              "/api/v#{api_version}/dkimsignings/#{inexistent}", nil,
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
          let(:testuser) { create(:user_with_dkimsignings) }
          let(:dkim) { testuser.domains.first.dkims.first }
          let(:new) do
            attributes_for(:dkimsigning,
                           author: "new@#{dkim.domain.name}",
                           dkim_id: dkim.id)
          end

          it 'authorizes the request' do
            expect(
              Pundit.authorize(testuser, DkimSigning, :create?)
            ).to be_truthy
            expect(
              Pundit.policy(testuser, DkimSigning).create_with?(new)
            ).to be_truthy
          end

          it 'does create a new dkimsigning' do
            count = DkimSigning.all.count

            post(
              "/api/v#{api_version}/dkimsignings",
              new.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect(DkimSigning.all.count).to eq(count + 1)
          end

          it 'returns an API Success containing the new dkimsigning' do
            post(
              "/api/v#{api_version}/dkimsignings",
              new.to_json,
              auth_headers_apikey(testuser.id)
            )

            new = DkimSigning.last

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
              "/api/v#{api_version}/dkimsignings",
              new.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end

          context 'with using different dkim_id in attributes' do
            let(:testuser) { create(:user_with_dkimsignings) }
            let(:anotheruser) { create(:user_with_dkims) }

            it 'does not create a new dkimsigning' do
              count = DkimSigning.all.count

              post(
                "/api/v#{api_version}/dkimsignings",
                attributes_for(
                  :dkimsigning,
                  author: anotheruser.domains.first.name,
                  dkim_id: anotheruser.domains.first.dkims.first.id
                ).to_json,
                auth_headers_apikey(testuser.id)
              )

              expect(DkimSigning.all.count).to eq(count)
            end

            it 'returns an API Error' do
              post(
                "/api/v#{api_version}/dkimsignings",
                attributes_for(
                  :dkimsigning,
                  author: anotheruser.domains.first.name,
                  dkim_id: anotheruser.domains.first.dkims.first.id
                ).to_json,
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
                "/api/v#{api_version}/dkimsignings",
                attributes_for(
                  :dkimsigning,
                  author: anotheruser.domains.first.name,
                  dkim_id: anotheruser.domains.first.dkims.first.id
                ).to_json,
                auth_headers_apikey(testuser.id)
              )

              expect { JSON.parse(last_response.body) }.not_to raise_exception
            end
          end
        end

        describe 'PATCH' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testdkimsigning, :update?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not update the dkimsigning' do
            upd_attrs = attributes_for(:dkimsigning, author: 'foo@foo.org')
            prev_tstamp = testdkimsigning.updated_at

            patch(
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
              upd_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect(testdkimsigning.updated_at).to eq(prev_tstamp)
          end

          it 'returns an API Error' do
            upd_attrs = attributes_for(:dkimsigning, author: 'foo@foo.org')

            patch(
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
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
            upd_attrs = attributes_for(:dkimsigning, author: 'foo@foo.org')

            patch(
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
              upd_attrs.to_json,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end

        describe 'DELETE' do
          it 'does not authorize the request' do
            expect do
              Pundit.authorize(testuser, testdkimsigning, :destroy?)
            end.to raise_exception(Pundit::NotAuthorizedError)
          end

          it 'does not delete the dkimsigning' do
            delete(
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect(DkimSigning.get(testdkimsigning.id)).not_to eq(nil)
            expect(DkimSigning.get(testdkimsigning.id)).to eq(testdkimsigning)
          end

          it 'returns an API Error' do
            delete(
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
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
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}",
              nil,
              auth_headers_apikey(testuser.id)
            )

            expect { JSON.parse(last_response.body) }.not_to raise_exception
          end
        end
      end

      context 'by an unauthenticated user' do
        let!(:testdkimsigning) { create(:dkimsigning) }

        before(:each) do
          create(:user, name: 'admin')
          create(:user, name: 'reseller')
        end

        let(:testuser) { create(:user) }

        describe 'GET all' do
          it 'returns an an API authentication error' do
            get "/api/v#{api_version}/dkimsignings"
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
            get "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}"
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
            inexistent = testdkimsigning.id
            testdkimsigning.destroy
            get "/api/v#{api_version}/dkimsignings/#{inexistent}"
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
              "/api/v#{api_version}/dkimsignings",
              'dkimsigning' => attributes_for(:dkimsigning)
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
            testdkimsigning_foo = create(:dkimsigning, author: 'foo.org')
            patch(
              "/api/v#{api_version}/dkimsignings/#{testdkimsigning_foo.id}",
              'dkimsigning' => attributes_for(:dkimsigning)
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
            delete "/api/v#{api_version}/dkimsignings/#{testdkimsigning.id}"
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
