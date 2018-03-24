# frozen_string_literal: true

namespace '/api/v1/vhosts' do
  get do
    @vhosts = policy_scope(Vhost)
    return_authorized_resource(object: @vhosts)
  end

  post do
    @vhost = Vhost.create!(params[:vhost])
    return_resource object: @vhost
  end

  before %r{/(?<id>\d+)/?.*} do
    # namespace local before blocks are evaluate before global before blocks
    # thus we need to enforce authentication here
    authenticate! if @user.nil?
    @vhost = Vhost.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @vhost.nil?
  end

  namespace '/:id' do
    delete do
      return_resource object: @vhost.delete
    end

    patch do
      @vhost.assign_attributes(params[:vhost]).save!
      return_resource object: @vhost
    end

    get do
      return_resource object: @vhost
    end
  end
end
