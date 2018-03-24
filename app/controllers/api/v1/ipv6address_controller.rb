# frozen_string_literal: true

namespace '/api/v1/ipv6addresses' do
  get do
    @ipv6addresses = policy_scope(Ipv6Address)
    return_authorized_resource(object: @ipv6addresses)
  end

  post do
    @ipv6address = Ipv6Address.create!(params[:ipv6address])
    return_resource object: @ipv6address
  end

  before %r{/(?<id>\d+)/?.*} do
    # namespace local before blocks are evaluate before global before blocks
    # thus we need to enforce authentication here
    authenticate! if @user.nil?
    @ipv6address = Ipv6Address.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @ipv6address.nil?
  end

  namespace '/:id' do
    delete do
      return_resource object: @ipv6address.delete
    end

    patch do
      @ipv6address.assign_attributes(params[:ipv6address]).save!
      return_resource object: @ipv6address
    end

    get do
      return_resource object: @ipv6address
    end
  end
end
