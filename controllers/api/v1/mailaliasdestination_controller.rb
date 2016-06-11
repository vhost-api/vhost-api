namespace '/api/v1/mailaliasdestinations' do
  get do
    @mailaliasdestinations = MailAliasDestination.all
    return_resource object: @mailaliasdestinations
  end

  post do
    @mailaliasdestination = MailAliasDestination.create!(params[:mailaliasdestination])
    return_resource object: @mailaliasdestination
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @mailaliasdestination = MailAliasDestination.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @mailaliasdestination.delete
    end

    patch do
      @mailaliasdestination.assign_attributes(params[:mailaliasdestination]).save!
      return_resource object: @mailaliasdestination
    end

    get do
      return_resource object: @mailaliasdestination
    end
  end
end
