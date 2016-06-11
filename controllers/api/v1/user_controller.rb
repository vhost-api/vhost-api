namespace '/api/v1/users' do
  get do
    @users = User.all
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
