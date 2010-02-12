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
  VERSION = '0.7.0'

  def self.included(base)
    base.class_eval do
      include ::Property::Attribute
    end
  end
end
