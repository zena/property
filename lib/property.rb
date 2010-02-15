require 'property/attribute'
require 'property/dirty'
require 'property/properties'
require 'property/column'
require 'property/behavior'
require 'property/schema'
require 'property/declaration'
require 'property/serialization/json'
require 'property/core_ext/time'

module Property
  VERSION = '0.8.2'

  def self.included(base)
    base.class_eval do
      include ::Property::Attribute
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
