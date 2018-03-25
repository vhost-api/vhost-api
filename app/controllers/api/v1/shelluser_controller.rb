# frozen_string_literal: true

namespace '/api/v1/shellusers' do
  get do
    @shellusers = policy_scope(ShellUser)
    return_authorized_resource(object: @shellusers)
  end

  post do
    @shelluser = ShellUser.create!(params[:shelluser])
    return_resource object: @shelluser
  end

  before %r{/(?<id>\d+)/?.*} do
    # namespace local before blocks are evaluate before global before blocks
    # thus we need to enforce authentication here
    authenticate! if @user.nil?
    @shelluser = ShellUser.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @shelluser.nil?
  end

  namespace '/:id' do
    delete do
      return_resource object: @shellUser.delete
    end

    patch do
      @shelluser.assign_attributes(params[:shelluser]).save!
      return_resource object: @shelluser
    end

    get do
      return_resource object: @shelluser
    end
  end
end
