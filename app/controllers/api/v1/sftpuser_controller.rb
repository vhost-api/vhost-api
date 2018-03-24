# frozen_string_literal: true

namespace '/api/v1/sftpusers' do
  get do
    @sftpusers = policy_scope(SftpUser)
    return_authorized_resource(object: @sftpusers)
  end

  post do
    @sftpuser = SftpUser.create!(params[:sftpuser])
    return_resource object: @sftpuser
  end

  before %r{/(?<id>\d+)/?.*} do
    # namespace local before blocks are evaluate before global before blocks
    # thus we need to enforce authentication here
    authenticate! if @user.nil?
    @sftpuser = SftpUser.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @sftpuser.nil?
  end

  namespace '/:id' do
    delete do
      return_resource object: @SftpUser.delete
    end

    patch do
      @sftpuser.assign_attributes(params[:sftpuser]).save!
      return_resource object: @sftpuser
    end

    get do
      return_resource object: @sftpuser
    end
  end
end
