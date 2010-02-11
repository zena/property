require 'property/attribute'
require 'property/dirty'
require 'property/properties'
require 'property/column'
require 'property/declaration'
require 'property/serialization/json'

module Property
  VERSION = '0.5.0'

  def self.included(base)
    base.class_eval do
      include ::Property::Attribute
    end
  end
end
