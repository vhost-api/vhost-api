# frozen_string_literal: true

# rubocop:disable Security/Eval
require 'bundler/setup'
require 'data_mapper'
require 'dm-migrations'
require 'dm-constraints'
require 'dm-timestamps'
require 'dm-serializer'
require 'yaml'
require 'json'
require 'bcrypt'
require 'active_support/inflector'

lp = '../../'

require_relative "#{lp}app/models/group"
require_relative "#{lp}app/models/package"
require_relative "#{lp}app/models/user"
require_relative "#{lp}app/models/apikey"
require_relative "#{lp}app/models/domain"
require_relative "#{lp}app/models/dkim"
require_relative "#{lp}app/models/dkimsigning"
require_relative "#{lp}app/models/mailaccount"
require_relative "#{lp}app/models/mailforwarding"
require_relative "#{lp}app/models/mailsource"
require_relative "#{lp}app/models/mailalias"
require_relative "#{lp}app/models/ipv4address"
require_relative "#{lp}app/models/ipv6address"
require_relative "#{lp}app/models/phpruntime"
require_relative "#{lp}app/models/vhost"
require_relative "#{lp}app/models/shell"
require_relative "#{lp}app/models/sftpuser"
require_relative "#{lp}app/models/shelluser"
require_relative "#{lp}app/models/sshpubkey"
require_relative "#{lp}app/models/databaseuser"
require_relative "#{lp}app/models/database"

# rubocop:disable Security/YAMLLoad
appconfig = YAML.load(File.read("#{lp}config/appconfig.yml"))['production']
# rubocop:enable Security/YAMLLoad

api_modules = appconfig[:api_modules]
enabled_modules = []

# core modules
%w[group user apikey package].each do |f|
  enabled_modules.push(f)
end

# optional modules
optional_modules = []
api_modules.map(&:upcase).each do |apimod|
  case apimod
  when 'EMAIL' then optional_modules.push(
    %w[domain dkim dkimsigning mailaccount mailalias mailsource mailforwarding]
  )
  when 'VHOST' then optional_modules.push(
    %w[domain ipv4address ipv6address phpruntime sftpuser shelluser vhost]
  )
  # TODO: no dns controllers exist yet
  when 'DNS' then optional_modules.push(%w[domain])
  # TODO: no database/databaseuser controllers exist yet
  when 'DATABASE' then nil
  end
end

def get_type_from_primitive(primitive)
  type = nil
  case primitive.to_s
  when 'Integer'
    type = 'integer'
  when 'String'
    type = 'string'
  when 'TrueClass', 'FalseClass'
    type = 'boolean'
  end
  type
end

enabled_modules.push(optional_modules)
enabled_modules = enabled_modules.flatten.uniq

controller_files = []
enabled_modules.each do |endpoint|
  controller_files.push("#{lp}app/controllers/api/v1/#{endpoint}_controller.rb")
end

namespaces = []
modules = {}

controller_files.each do |f|
  File.open(f) do |file|
    match = file.read.match(%r{namespace '/api/v1/(.*)' do})

    if match
      namespace = match.captures[0].to_s

      namespaces.push(namespace)

      class_name = ''
      filename = if namespace == 'mailaliases'
                   'mailalias.rb'
                 else
                   "#{namespace[0..-2]}.rb"
                 end

      File.open("#{lp}app/models/#{filename}") do |model_file|
        class_match = model_file.read.match(%r{^class (.*)$})
        class_name = class_match.captures[0].to_s if class_match
      end

      modules[class_name] = {
        class_name: class_name,
        filename: filename,
        namespace: namespace
      }
    end
  end
end

contact_info = {
  name: 'Thore Bödecker',
  email: 'me@foxxx0.de',
  url: 'https://github.com/vhost-api/vhost-api/'
}

license_info = {
  name: 'AGPL v3',
  url: 'https://github.com/vhost-api/vhost-api/blob/master/LICENSE'
}

result = {}
result[:swagger] = '2.0'
result[:info] = { title: 'vhost-api',
                  description: 'vhost-api',
                  version: '0.1.2-alpha',
                  contact: contact_info,
                  license: license_info }
result[:schemes] = ['https']
result[:basePath] = '/api/v1'
result[:produces] = ['application/json']

paths = {}
definitions = {}

paths['/auth/login'] = {
  post: {
    summary: 'API Login Action',
    description: 'Returns an Apikey after successful login',
    tags: ['Auth'],
    consumes: ['application/json'],
    parameters: [
      { in: 'body',
        name: 'body',
        description: 'Auth Data',
        required: true,
        schema: {
          '$ref' => '#/definitions/Auth'
        } }
    ],
    responses: {
      '200' => {
        description: 'Success',
        schema: {
          '$ref' => '#/definitions/AuthSuccess'
        }
      },
      '403' => {
        description: 'apikey quota exhausted'
      }
    }
  }
}

# rubocop:disable Metrics/BlockLength
modules.each do |_, module_value|
  ns = module_value[:namespace]
  class_name = module_value[:class_name]
  filename = module_value[:filename]

  clazz = Object.const_get(class_name)

  paths["/#{ns}"] = {
    get: {
      summary: "Collection of #{class_name.pluralize}",
      description: "Get the full collection of created #{class_name.pluralize}",
      tags: [class_name],
      parameters: [
        { in: 'query',
          name: 'limit',
          description: 'Limits the output',
          required: false,
          type: 'integer' },
        { in: 'query',
          name: 'offset',
          description: 'Offsets the output (needs limit)',
          required: false,
          type: 'integer' },
        { in: 'query',
          name: 'q[fieldName]',
          description: 'Seach for the field',
          required: false,
          type: 'string' },
        { in: 'query',
          name: 'sort',
          description: 'Sort by given field name (descending by - prefix)',
          required: false,
          type: 'string' },
        { in: 'query',
          name: 'fields',
          description: 'Give only the requested fields (comma separated list)',
          required: false,
          type: 'string' }
      ],
      responses: {
        '200' => {
          description: "An array of #{class_name.pluralize}",
          schema: {
            type: 'array',
            items: {
              '$ref' => "\#/definitions/#{class_name}"
            }
          }
        },
        default: {
          description: 'Unexpected error',
          schema: {
            '$ref' => '#/definitions/Error'
          }
        }
      }
    },
    post: {
      summary: "Creates a new #{class_name}",
      description: "Create a new #{class_name} with the request body",
      tags: [class_name],
      consumes: ['application/json'],
      parameters: [
        { in: 'body',
          name: 'body',
          description: "The #{class_name} object without id",
          required: true,
          schema: {
            '$ref' => "\#/definitions/#{class_name}"
          } }
      ],
      responses: {
        '201' => {
          description: 'Success'
        },
        '400' => {
          description: 'Malformed request data'
        },
        '409' => {
          description: 'Resource conflict'
        }
      }
    }
  }
  paths["/#{ns}/{#{class_name.downcase}Id}"] = {
    delete: {
      summary: "Delete #{class_name}",
      description: "Deletes the #{class_name} by the given id",
      parameters: [
        { in: 'path',
          name: "#{class_name.downcase}Id",
          description: "#{class_name} id",
          required: true,
          type: 'integer',
          format: 'int64' }
      ],
      responses: {
        '200' => {
          description: 'Success'
        },
        '500' => {
          description: 'Could not delete'
        }
      }
    },
    patch: {
      summary: "Update #{class_name}",
      description: "Updates the given fields in the #{class_name} by id",
      consumes: ['application/json'],
      parameters: [
        { in: 'path',
          name: "#{class_name.downcase}Id",
          description: "#{class_name} id",
          required: true,
          type: 'integer',
          format: 'int64' },
        { in: 'body',
          name: 'body',
          description: "The update fields of the #{class_name} object",
          required: true,
          schema: {
            '$ref' => "\#/definitions/#{class_name}"
          } }
      ],
      responses: {
        '200' => {
          description: 'Success'
        },
        '400' => {
          description: 'Malformed request'
        },
        '409' => {
          description: 'Resource conflict'
        },
        '422' => {
          description: 'Invalid request data'
        },
        '500' => {
          description: 'Could not update'
        }
      }
    }
  }

  definitions[class_name] = {
    type: 'object',
    properties: {}
  }

  clazz.properties.each do |prop|
    type = get_type_from_primitive(prop.primitive)

    definitions[class_name][:properties][prop.name] = {
      type: type,
      description: "#{prop.name} of #{class_name}"
    }
  end

  clazz.relationships.each do |relation|
    unless relation.is_a?(DataMapper::Associations::ManyToOne::Relationship)
      next
    end

    parent_model_info = modules[relation.parent_model_name]

    File.open("#{lp}app/models/#{filename}") do |file|
      regex = 'relationships:\s*\{\s*' +
              relation.name.to_s +
              ':\s*\{([a-z:_,\[\] ]*)\}'

      match = file.read.match(regex)

      only = match.captures[0].to_s if match

      if only
        # rubocop:disable Style/EvalWithLocation
        only_hash = eval("{ #{only} }")
        # rubocop:enable Style/EvalWithLocation

        relation_hash = {
          type: 'object',
          properties: {}
        }

        only_hash.each do |_, value|
          value.each do |field|
            parent_clazz = Object.const_get(parent_model_info[:class_name])

            parent_property = parent_clazz.properties[field]
            sub_type = get_type_from_primitive(parent_property.primitive)

            relation_hash[:properties][field] = {
              type: sub_type,
              description: "#{field} of #{relation.parent_model_name}"
            }
          end
        end

        definitions[class_name][:properties][relation.name] = relation_hash
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

definitions['Error'] = {
  type: 'object',
  properties: {
    code: {
      type: 'integer',
      format: 'int32'
    },
    message: {
      type: 'string'
    },
    fields: {
      type: 'string'
    }
  }
}

definitions['Auth'] = {
  type: 'object',
  properties: {
    username: {
      type: 'string'
    },
    password: {
      type: 'string'
    },
    apikey_comment: {
      type: 'string'
    }
  }
}

definitions['AuthSuccess'] = {
  type: 'object',
  properties: {
    user_id: {
      type: 'integer',
      format: 'int32'
    },
    apikey: {
      type: 'string'
    }
  }
}

result[:paths] = paths
result[:definitions] = definitions

output = JSON.pretty_generate(JSON.parse(result.to_json)) + "\n"

puts output
# rubocop:enable Security/Eval
