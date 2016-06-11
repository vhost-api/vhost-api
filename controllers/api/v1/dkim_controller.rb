namespace '/api/v1/dkims' do
  get do
    @dkims = Dkim.all
    return_resource object: @dkims
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
