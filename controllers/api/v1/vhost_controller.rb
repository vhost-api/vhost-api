namespace '/api/v1/vhosts' do
  get do
    @vhosts = Vhost.all
    return_resource object: @vhosts
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
