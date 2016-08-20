# frozen_string_literal: true
def symbolize_params_hash(params)
  return {} if params.nil?
  params.reduce({}) do |memo, (k, v)|
    memo.tap { |m| m[k.to_sym] = v }
  end
end

def return_json_pretty(json)
  content_type :json, charset: 'utf-8'
  result = JSON.pretty_generate(JSON.parse(json)) + "\n"
  result_digest = Digest::SHA256.hexdigest(result)
  etag result_digest
  halt 304 if request.env['HTTP_IF_NONE_MATCH'] == result_digest
  result
end

def return_authorized_resource(object: nil)
  return return_apiresponse(
    ApiResponseSuccess.new(data: { object: nil })
  ) if object.nil?

  permitted_attributes = Pundit.policy(@user, object).permitted_attributes
  object = object.as_json(only: permitted_attributes)
  return_apiresponse(ApiResponseSuccess.new(data: { object: object }))
end

def return_authorized_collection(object: nil, params: { fields: nil })
  begin
    object = limited_collection(collection: object, params: params)
  rescue DataObjects::DataError, ArgumentError
    return_api_error(ApiErrors.[](:invalid_query))
  rescue => err
    binding.pry
    log_app('error', "#{err.message}\n#{err.backtrace}")
    return_api_error(ApiErrors.[](:invalid_request))
  end
  return_apiresponse(ApiResponseSuccess.new(data: { objects: object }))
end

def limited_collection(collection: nil, params: { fields: nil })
  return {} if collection.nil? || collection.empty?

  collection = prepare_collection(
    collection: collection, params: params
  ) unless (params.keys - [:fields]).empty?

  fields = field_list(
    permitted: Pundit.policy(@user, collection).permitted_attributes,
    requested: params[:fields]
  )

  prepare_collection_output(collection: collection, fields: fields)
end

def prepare_collection(collection: nil, params: { fields: nil })
  collection = search_collection(collection: collection,
                                 query: symbolize_params_hash(params[:q]))

  # sort the collection
  collection = sort_collection(collection: collection, params: params[:sort])

  # return only requested fields
  filter_params = { limit: params[:limit], offset: params[:offset] }
  collection = filter_collection(collection: collection,
                                 params: filter_params) unless params.empty?

  # halt with empty response if search/filter returns nil/empty
  halt 200, return_apiresponse(
    ApiResponseSuccess.new(data: { objects: {} })
  ) if collection.nil? || collection.empty?

  collection
end

def string_to_bool(str)
  return true if str =~ %r{^(true|yes|TRUE|YES|y|1)$}
  return false if str =~ %r{^(false|no|FALSE|NO|n|0)$}
  raise ArgumentError
end

def search_collection(collection: nil, query: nil)
  return collection if query.nil?

  query.keys.each do |key|
    # booleans need to be searched differently
    search_query = if key.to_s =~ %r{enabled$}
                     { key => string_to_bool(query[key]) }
                   else
                     { key.like => "%#{query[key]}%" }
                   end
    collection = collection.all(search_query)
  end
  collection
end

def filter_collection(collection: nil, params: { fields: nil })
  return collection if params.nil? || params.empty?
  limit = params[:limit].to_i
  offset = params[:offset].to_i

  collection = collection.all(limit: limit, offset: offset) unless limit.zero?

  collection
end

def sort_collection(collection: nil, params: nil)
  return collection if params.nil?

  sort_columns = params.split(',')
  query = []
  sort_columns.each do |col|
    query.push(col[0] == '-' ? col[1..-1].to_sym.desc : col.to_sym.asc)
  end

  collection.all(order: query)
end

def prepare_collection_output(collection: nil, fields: nil)
  return {} if collection.nil? || collection.empty?
  result = {}
  collection.each do |record|
    # result.push(record.as_json(only: fields))
    result[record.id] = record.as_json(only: fields)
  end
  result
end

def field_list(permitted: nil, requested: nil)
  return permitted if requested.nil?

  requested_fields = params[:fields].split(',').map(&:to_sym)

  return_api_error(ApiErrors.[](:invalid_query)) unless
    (requested_fields - permitted).empty?

  permitted & requested_fields
end

def return_resource(object: nil)
  clazz = object.model.to_s.downcase.pluralize

  return_json_pretty({ clazz => object }.to_json)
end

def return_api_error(api_errors_hash, errors = nil)
  return_apiresponse(api_error(api_errors_hash, errors))
end

def api_error(api_errors_hash, errors = nil)
  ApiResponseError.new(
    status_code: api_errors_hash[:status],
    error_id: api_errors_hash[:code],
    message: api_errors_hash[:message],
    data: errors
  )
end

def return_apiresponse(response)
  if response.is_a?(ApiResponse)
    halt response.status_code, return_json_pretty(response.to_json)
  else
    halt 500
  end
end
