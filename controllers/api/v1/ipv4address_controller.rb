# frozen_string_literal; false
namespace '/api/v1/ipv4addresses' do
  helpers do
    def fetch_scoped_ipv4addresses
      @ipv4addresses = policy_scope(Ipv4Address)
    end
  end

  get do
    authenticate!
    @ipv4addresses = Ipv4Address.all(id: 0)
    fetch_scoped_ipv4addresses
    return_authorized_resource(object: @ipv4addresses)
  end

  post do
    @ipv4address = Ipv4Address.create!(params[:ipv4address])
    return_resource object: @ipv4address
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @ipv4address = Ipv4Address.get(params[:id])
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
