# frozen_string_literal; false
namespace '/api/v1/domains' do
  helpers do
    def user_domains
      # my_logger.debug "user ---> #{@user.inspect}"
      @domains = policy_scope(Domain)
    end
  end

  get do
    authenticate!
    @domains = Domain.all(id: 0)
    user_domains
    # @domains = Domain.all
    # return_resource object: @domains
    permitted_attributes = Pundit.policy(@user, @domains).permitted_attributes
    return_json_pretty(@domains.to_json(only: permitted_attributes))
  end

  post do
    @domain = Domain.create!(params[:domain])
    return_resource object: @domain
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @domain = Domain.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @domain.delete
    end

    patch do
      @domain.assign_attributes(params[:domain]).save!
      return_resource object: @domain
    end

    get do
      return_resource object: @domain
    end
  end
end
