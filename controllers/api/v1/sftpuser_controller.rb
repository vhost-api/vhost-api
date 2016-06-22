# frozen_string_literal: true
namespace '/api/v1/sftpusers' do
  helpers do
    def fetch_scoped_sftpusers
      @sftpusers = policy_scope(SftpUser)
    end
  end

  get do
    authenticate!
    @sftpusers = SftpUser.all(id: 0)
    fetch_scoped_sftpusers
    return_authorized_resource(object: @sftpusers)
  end

  post do
    @sftpuser = SftpUser.create!(params[:sftpuser])
    return_resource object: @sftpuser
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @sftpuser = SftpUser.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @SftpUser.delete
    end

    patch do
      @sftpuser.assign_attributes(params[:sftpuser]).save!
      return_resource object: @sftpuser
    end

    get do
      return_resource object: @sftpuser
    end
  end
end
