require 'property/attribute'
require 'property/dirty'
require 'property/properties'
require 'property/column'
require 'property/role_module'
require 'property/schema_module'
require 'property/role'
require 'property/schema'
require 'property/declaration'
require 'property/db'
require 'property/index'
require 'property/serialization/json'
require 'property/core_ext/time'
require 'property/base'
require 'property/stored_role'
require 'property/stored_schema'

# Fix for ActiveRecord 2.3 on ruby 2.2
# Not needed for AR3.2
module ActiveRecord
  module Associations
    class AssociationProxy
      def send(method, *args)
        if proxy_respond_to?(method,true)
          super
        else
          load_target
          @target.send(method, *args)
        end
      end
    end
  end
end

module Property
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
