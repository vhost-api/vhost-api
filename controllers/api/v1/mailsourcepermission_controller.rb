# frozen_string_literal; false
namespace '/api/v1/mailsourcepermissions' do
  get do
    @mailsourcepermissions = MailSourcePermission.all
    return_resource object: @mailsourcepermissions
  end

  post do
    @mailsourcepermission = MailSourcePermission.create!(params[
                                                        :mailsourcepermission])
    return_resource object: @mailsourcepermission
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @mailsourcepermission = MailSourcePermission.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @mailsourcepermission.delete
    end

    patch do
      @mailsourcepermission.assign_attributes(params[
                                             :mailsourcepermission]).save!
      return_resource object: @mailsourcepermission
    end

    get do
      return_resource object: @mailsourcepermission
    end
  end
end
