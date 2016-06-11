require 'json'

class Env
  def initialize(name)
    @name = name
  end

  def model
    'env'
  end

  def to_json
    {environment: @name}.to_json
  end

  attr_reader :name
end
