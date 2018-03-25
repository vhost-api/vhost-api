# frozen_string_literal: true

module FormatHelpers
  def spec_json_pretty(json)
    JSON.pretty_generate(JSON.parse(json)) + "\n"
  end

  def spec_authorized_resource(object: nil, user: nil)
    return spec_json_pretty({}.to_json) if object.nil?

    permitted_attributes = Pundit.policy(user, object).permitted_attributes
    object = object.as_json(only: permitted_attributes)
    spec_apiresponse(ApiResponseSuccess.new(data: { object: object }))
  end

  def spec_authorized_collection(object: nil, params: { fields: nil }, uid: nil)
    return spec_json_pretty({}.to_json) if object.nil? || object.empty?

    @user = User.get(uid)

    begin
      result = spec_limited_collection(collection: object, params: params)
    rescue DataObjects::DataError, ArgumentError
      spec_api_error(ApiErrors.[](:invalid_query))
    rescue Error
      spec_api_error(ApiErrors.[](:invalid_request))
    end

    spec_apiresponse(ApiResponseSuccess.new(data: { objects: result }))
  end

  def spec_limited_collection(collection: nil, params: { fiels: nil })
    unless (params.keys - [:fields]).empty?
      collection = spec_prepare_collection(
        collection: collection, params: params
      )
    end

    fields = field_list(
      permitted: Pundit.policy(@user, collection).permitted_attributes,
      requested: params[:fields]
    )

    prepare_collection_output(collection: collection, fields: fields)
  end

  def spec_prepare_collection(collection: nil, params: { fields: nil })
    collection = search_collection(collection: collection,
                                   query: symbolize_params_hash(params[:q]))

    # sort the collection
    collection = sort_collection(collection: collection,
                                 sort_params: params[:sort])

    # return only requested fields
    filter_params = { limit: params[:limit], offset: params[:offset] }
    unless params.empty?
      collection = filter_collection(collection: collection,
                                     params: filter_params)
    end

    # halt with empty response if search/filter returns nil/empty
    return spec_json_pretty({}.to_json) if collection.nil? ||
                                           collection.empty?

    collection
  end

  def spec_api_error(api_errors_hash, errors = nil)
    spec_apiresponse(api_error(api_errors_hash, errors))
  end

  def spec_apiresponse(response)
    if response.is_a?(ApiResponse)
      spec_json_pretty(response.to_json)
    else
      'internal server error'
    end
  end
end
