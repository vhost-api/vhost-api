# frozen_string_literal; false
namespace '/api/v1/foobars' do
  get do
    @foobars = Foobar.all
    return_resource object: @foobars
  end

  post do
    @foobar = Foobar.create!(params[:foobar])
    return_resource object: @foobar
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @foobar = Foobar.find(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @foobar.delete
    end

    patch do
      @foobar.assign_attributes(params[:foobar]).save!
      return_resource object: @foobar
    end

    get do
      return_resource object: @foobar
    end
  end
end
