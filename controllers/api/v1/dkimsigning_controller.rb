# frozen_string_literal: true
namespace '/api/v1/dkimsignings' do
  get do
    @dkimsignings = DkimSigning.all
    return_resource object: @dkimsignings
  end

  post do
    @dkimsigning = DkimSigning.create!(params[:dkimsigning])
    return_resource object: @dkimsigning
  end

  before %r{\A/(?<id>\d+)/?.*} do
    @dkimsigning = DkimSigning.get(params[:id])
  end

  namespace '/:id' do
    delete do
      return_resource object: @dkimsigning.delete
    end

    patch do
      @dkimsigning.assign_attributes(params[:dkimsigning]).save!
      return_resource object: @dkimsigning
    end

    get do
      return_resource object: @dkimsigning
    end
  end
end
