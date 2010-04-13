require 'property/behavior_module'

module Property
  # This class holds a set of property definitions. This is like a Module in ruby:
  # by 'including' this behavior in a class or in an instance, you augment the said
  # object with the behavior's property definitions.
  class Behavior
    include BehaviorModule

    def self.new(name, &block)
      if name.kind_of?(Hash)
        obj = super(name[:name] || name['name'])
      else
        obj = super(name)
      end

      if block_given?
        obj.property(&block)
      end
      obj
    end

    # Initialize a new behavior with the given name
    def initialize(name)
      self.name = name
      initialize_behavior_module
    end
  end
end
