require 'property/behavior_module'

module Property
  # This class lets you store a set of property definitions inside the database. For
  # the rest, this class behaves just like Behavior.
  class ActiveBehavior < ActiveRecord::Base
    include BehaviorModule

    def self.new(name, &block)
      obj = super
      if block_given?
        obj.property(&block)
      end
      obj
    end

    # Initialize a new behavior with the given name
    def initialize(*args)
      super
      initialize_behavior_module
    end
  end
end
