# frozen_string_literal; false
namespace '/api/v1/aliasvhosts' do
  helpers do
    def fetch_scoped_aliasvhosts
      @aliasvhosts = policy_scope(AliasVhost)
    end
  end

  get do
    authenticate!
    @aliasvhosts = AliasVhost.all(id: 0)
    fetch_scoped_aliasvhosts
    return_authorized_resource(object: @aliasvhosts)
  end

  post do
    @aliasvhost = AliasVhost.create!(params[:aliasvhost])
    return_resource object: @aliasvhost
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @aliasvhost = AliasVhost.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @aliasvhost.delete
    end

    patch do
      @aliasvhost.assign_attributes(params[:aliasvhost]).save!
      return_resource object: @aliasvhost
    end

    get do
      return_resource object: @aliasvhost
    end
  end
end
