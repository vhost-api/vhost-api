# frozen_string_literal: true
namespace '/api/v1/apikeys' do
  get do
    @apikeys = Apikey.all
    return_resource object: @apikeys
  end

  post do
    @apikey = Apikey.create!(params[:apikey])
    return_resource object: @apikey
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @apikey = Apikey.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @apikey.delete
    end

    patch do
      @apikey.assign_attributes(params[:apikey]).save!
      return_resource object: @apikey
    end

    get do
      return_resource object: @apikey
    end
  end
end