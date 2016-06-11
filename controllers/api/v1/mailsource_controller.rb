namespace '/api/v1/mailsources' do
  get do
    @mailsources = MailSource.all
    return_resource object: @mailsources
  end

  post do
    @mailsource = MailSource.create!(params[:mailsource])
    return_resource object: @mailsource
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @mailsource = MailSource.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @mailsource.delete
    end

    patch do
      @mailsource.assign_attributes(params[:mailsource]).save!
      return_resource object: @mailsource
    end

    get do
      return_resource object: @mailsource
    end
  end
end
