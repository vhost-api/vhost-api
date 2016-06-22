# frozen_string_literal: true
namespace '/api/v1/phpruntimes' do
  helpers do
    def fetch_scoped_phpruntimes
      @phpruntimes = policy_scope(PhpRuntime)
    end
  end

  get do
    authenticate!
    @phpruntimes = PhpRuntime.all(id: 0)
    fetch_scoped_phpruntimes
    return_authorized_resource(object: @phpruntimes)
  end

  post do
    @phpruntime = PhpRuntime.create!(params[:phpruntime])
    return_resource object: @phpruntime
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @phpruntime = PhpRuntime.get(params[:id])
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
