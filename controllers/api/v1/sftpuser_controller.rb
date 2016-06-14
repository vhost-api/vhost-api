# frozen_string_literal; false
namespace '/api/v1/sftpusers' do
  get do
    @sftpusers = SftpUser.all
    return_resource object: @sftpusers
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
