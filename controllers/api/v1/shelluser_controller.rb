# frozen_string_literal; false
namespace '/api/v1/shellusers' do
  helpers do
    def fetch_scoped_shellusers
      @shellusers = policy_scope(ShellUser)
    end
  end

  get do
    authenticate!
    @shellusers = ShellUser.all(id: 0)
    fetch_scoped_shellusers
    return_authorized_resource(object: @shellusers)
  end

  post do
    @shelluser = ShellUser.create!(params[:shelluser])
    return_resource object: @shelluser
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @shelluser = ShellUser.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @shellUser.delete
    end

    patch do
      @shelluser.assign_attributes(params[:shelluser]).save!
      return_resource object: @shelluser
    end

    get do
      return_resource object: @shelluser
    end
  end
end
