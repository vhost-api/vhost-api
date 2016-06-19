# frozen_string_literal; false
namespace '/api/v1/ipv6addresses' do
  helpers do
    def fetch_scoped_ipv6addresses
      @ipv6addresses = policy_scope(Ipv6Address)
    end
  end

  get do
    authenticate!
    @ipv6addresses = Ipv6Address.all(id: 0)
    fetch_scoped_ipv6addresses
    return_authorized_resource(object: @ipv6addresses)
  end

  post do
    @ipv6address = Ipv6Address.create!(params[:ipv6address])
    return_resource object: @ipv6address
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @ipv6address = Ipv6Address.get(params[:id])
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
