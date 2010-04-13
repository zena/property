require 'property/behavior_module'

module Property
  # This class lets you store a set of property definitions inside the database. For
  # the rest, this class behaves just like Behavior.
  class ActiveBehavior < ActiveRecord::Base
    include BehaviorModule

    def self.new(arg, &block)
      unless arg.kind_of?(Hash)
        arg = {:name => arg}
      end

      if block_given?
        obj = super(arg) do
          # Dummy block to hide our special property declaration block
        end

        obj.property(&block)
      else
        obj = super(arg)
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
