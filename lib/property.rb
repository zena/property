require 'property/attribute'
require 'property/dirty'
require 'property/properties'
require 'property/column'
require 'property/behavior'
require 'property/active_behavior'
require 'property/schema'
require 'property/declaration'
require 'property/db'
require 'property/index'
require 'property/serialization/json'
require 'property/core_ext/time'
require 'property/base'

module Property
  VERSION = '1.0.0'

  def self.included(base)
    base.class_eval do
      include Attribute
      include Serialization::JSON
      include Declaration
      include Dirty
      include Index
    end
  end

  def self.validators
    @@validators ||= []
  end

  def self.validate_property_class(type)
    @@validators.each do |validator|
      return false unless validator.validate(type)
    end
    true
  end
end
