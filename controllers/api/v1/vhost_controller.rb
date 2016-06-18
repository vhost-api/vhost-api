# frozen_string_literal; false
namespace '/api/v1/vhosts' do
  helpers do
    def fetch_scoped_vhosts
      @vhosts = policy_scope(Vhost)
    end
  end

  get do
    authenticate!
    @vhosts = Vhost.all(id: 0)
    fetch_scoped_vhosts
    return_authorized_resource(object: @vhosts)
  end

  post do
    @vhost = Vhost.create!(params[:vhost])
    return_resource object: @vhost
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @vhost = Vhost.get(params[:id])
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
