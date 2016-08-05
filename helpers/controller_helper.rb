# frozen_string_literal: true
def symbolize_params_hash(params)
  params.reduce({}) do |memo, (k, v)|
    memo.tap { |m| m[k.to_sym] = v }
  end
end

def return_json_pretty(json)
  JSON.pretty_generate(JSON.load(json)) + "\n"
end

def return_authorized_resource(object: nil)
  return return_json_pretty(
    api_error(ApiErrors.[](:unauthorized)).to_json
  ) if @user.nil?

  return return_json_pretty({}.to_json) if object.nil?

  permitted_attributes = Pundit.policy(@user, object).permitted_attributes
  return_json_pretty(object.to_json(only: permitted_attributes))
end

def return_authorized_collection(object: nil, params: nil)
  raise Pundit::NotAuthorizedError if @user.nil?

  return return_json_pretty({}.to_json) if object.nil? || object.empty?

  result = limited_collection(collection: object, params: params)

  return_json_pretty(result.to_json)
end

def limited_collection(collection: nil, params: nil)
  collection = filter_collection(collection: collection,
                                 params: params) unless params.empty?

  return invalid_query_params if collection.nil? || collection.empty?

  fields = field_list(
    permitted: Pundit.policy(@user, collection).permitted_attributes,
    requested: params[:fields]
  )

  prepare_collection(collection: collection, fields: fields)
end

def filter_collection(collection: nil, params: nil)
  return collection if params.nil? || params.empty?
  limit = params[:limit].to_i
  offset = params[:offset].to_i

  if limit
    collection = collection.all(limit: limit, offset: offset)
  else
    invalid_query_params
  end

  collection
end

def prepare_collection(collection: nil, fields: nil)
  result = []
  collection.sort.each do |record|
    result.push(record.as_json(only: fields))
  end
  result
end

def invalid_query_params
  api_error(ApiErrors.[](:invalid_query)).to_json
end

def field_list(permitted: nil, requested: nil)
  return permitted if requested.nil?
  permitted & params[:fields].map(&:to_sym)
end

def return_resource(object: nil)
  clazz = object.model.to_s.downcase.pluralize

  respond_to do |type|
    type.html do
      haml clazz.to_sym
    end

    type.json do
      return_json_pretty({ clazz => object }.to_json)
    end
  end
end

def return_api_error(api_errors_hash)
  return_apiresponse(api_error(api_errors_hash))
end

def api_error(api_errors_hash)
  ApiResponseError.new(
    status_code: api_errors_hash[:status],
    error_id: api_errors_hash[:code],
    message: api_errors_hash[:message]
  )
end

def return_apiresponse(response)
  if response.is_a?(ApiResponseSuccess)
    status response.status_code
    return_json_pretty response.to_json
  elsif response.is_a?(ApiResponseError)
    halt response.status_code, return_json_pretty(response.to_json)
  else
    halt 500
  end
end
