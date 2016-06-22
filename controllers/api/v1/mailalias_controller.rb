# frozen_string_literal: true
namespace '/api/v1/mailaliases' do
  helpers do
    def fetch_scoped_mailaliases
      @mailaliases = policy_scope(MailAlias)
    end
  end

  get do
    authenticate!
    @mailaliases = MailAlias.all(id: 0)
    fetch_scoped_mailaliases
    return_authorized_resource(object: @mailaliases)
  end

  post do
    @mailalias = MailAlias.create!(params[:mailalias])
    return_resource object: @mailalias
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @mailalias = MailAlias.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @mailalias.delete
    end

    patch do
      @mailalias.assign_attributes(params[:mailalias]).save!
      return_resource object: @mailalias
    end

    get do
      return_resource object: @mailalias
    end
  end
end
