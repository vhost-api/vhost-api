# frozen_string_literal; false
namespace '/api/v1/groups' do
  get do
    @groups = Group.all
    return_resource object: @groups
  end

  post do
    @group = Group.create!(params[:group])
    return_resource object: @group
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @group = Group.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @group.delete
    end

    patch do
      @group.assign_attributes(params[:group]).save!
      return_resource object: @group
    end

    get do
      return_resource object: @group
    end
  end
end
