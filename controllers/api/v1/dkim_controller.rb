# frozen_string_literal: true
namespace '/api/v1/dkims' do
  helpers do
    def fetch_scoped_dkims
      @dkims = policy_scope(Dkim)
    end
  end

  get do
    authenticate!
    @dkims = Dkim.all(id: 0)
    fetch_scoped_dkims
    return_authorized_resource(object: @dkims)
  end

  post do
    @dkim = Dkim.create!(params[:dkim])
    return_resource object: @dkim
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @dkim = Dkim.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @dkim.delete
    end

    patch do
      @dkim.assign_attributes(params[:dkim]).save!
      return_resource object: @dkim
    end

    get do
      return_resource object: @dkim
    end
  end
end
