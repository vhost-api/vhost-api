# frozen_string_literal: true
namespace '/api/v1/groups' do
  helpers do
    def fetch_scoped_groups
      @groups = policy_scope(Group)
    end
  end

  get do
    authenticate!
    @groups = Group.all(id: 0)
    fetch_scoped_groups
    return_authorized_resource(object: @groups)
  end

  post do
    authenticate!
    @group = Group.create!(params[:group])
    return_resource object: @group
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @group = Group.get(params[:id])
    halt 404 if @group.nil?
  end

  namespace '/:id' do
    delete do
      authenticate!
      return_resource object: @group.delete
    end

    patch do
      authenticate!
      @group.assign_attributes(params[:group]).save!
      return_resource object: @group
    end

    get do
      authenticate!
      return_resource object: @group
    end
  end
end
