# frozen_string_literal: true

namespace '/api/v1/ipv4addresses' do
  get do
    @ipv4addresses = policy_scope(Ipv4Address)
    return_authorized_resource(object: @ipv4addresses)
  end

  post do
    @ipv4address = Ipv4Address.create!(params[:ipv4address])
    return_resource object: @ipv4address
  end

  before %r{/(?<id>\d+)/?.*} do
    # namespace local before blocks are evaluate before global before blocks
    # thus we need to enforce authentication here
    authenticate! if @user.nil?
    @ipv4address = Ipv4Address.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @ipv4address.nil?
  end

  namespace '/:id' do
    delete do
      return_resource object: @ipv4address.delete
    end

    patch do
      @ipv4address.assign_attributes(params[:ipv4address]).save!
      return_resource object: @ipv4address
    end

    get do
      return_resource object: @ipv4address
    end
  end
end
