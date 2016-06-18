# frozen_string_literal; false
namespace '/api/v1/mailsources' do
  helpers do
    def fetch_scoped_mailsources
      @mailsources = policy_scope(MailSource)
    end
  end

  get do
    authenticate!
    @mailsources = MailSource.all(id: 0)
    fetch_scoped_mailsources
    return_authorized_resource(object: @mailsources)
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
