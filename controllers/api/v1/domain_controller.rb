# frozen_string_literal: true
namespace '/api/v1/domains' do
  helpers do
    def fetch_scoped_domains
      @domains = policy_scope(Domain)
    end
  end

  get do
    authenticate!
    @domains = Domain.all(id: 0)
    fetch_scoped_domains
    return_authorized_resource(object: @domains)
  end

  post do
    @domain = Domain.create!(params[:domain])
    return_resource object: @domain
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @domain = Domain.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @domain.delete
    end

    patch do
      @domain.assign_attributes(params[:domain]).save!
      return_resource object: @domain
    end

    get do
      return_resource object: @domain
    end
  end
end
