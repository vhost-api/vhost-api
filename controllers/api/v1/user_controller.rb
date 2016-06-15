# frozen_string_literal; false
namespace '/api/v1/users' do
  helpers do
    def users_visible
      @users = policy_scope(User)
    end
  end

  get do
    authenticate!
    @users = User.all(id: 0)
    users_visible
    return_resource object: @users
  end

  post do
    @user = User.create!(params[:user])
    return_resource object: @user
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @user = User.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @user.delete
    end

    patch do
      @user.assign_attributes(params[:user]).save!
      return_resource object: @user
    end

    get do
      return_resource object: @user
    end
  end
end
