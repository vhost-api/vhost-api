# frozen_string_literal: true

namespace '/api/v1/phpruntimes' do
  get do
    @phpruntimes = policy_scope(PhpRuntime)
    return_authorized_resource(object: @phpruntimes)
  end

  post do
    @phpruntime = PhpRuntime.create!(params[:phpruntime])
    return_resource object: @phpruntime
  end

  before %r{/(?<id>\d+)/?.*} do
    # namespace local before blocks are evaluate before global before blocks
    # thus we need to enforce authentication here
    authenticate! if @user.nil?
    @phpruntime = PhpRuntime.get(params[:id])
    return_api_error(ApiErrors.[](:not_found)) if @phpruntime.nil?
  end

  namespace '/:id' do
    delete do
      return_resource object: @phpruntime.delete
    end

    patch do
      @phpruntime.assign_attributes(params[:phpruntime]).save!
      return_resource object: @phpruntime
    end

    get do
      return_resource object: @phpruntime
    end
  end
end
