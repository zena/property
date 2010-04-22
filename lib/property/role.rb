require 'property/role_module'

module Property
  # This class holds a set of property definitions. This is like a Module in ruby:
  # by 'including' this role in a class or in an instance, you augment the said
  # object with the role's property definitions.
  class Role
    include RoleModule

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

    # Initialize a new role with the given name
    def initialize(name)
      self.name = name
      initialize_role_module
    end
  end
end
