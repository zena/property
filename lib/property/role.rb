require 'property/redefined_property_error'
require 'property/redefined_method_error'

module Property
  # The Role holds information on a group of property columns. The "Role" is used
  # in the same way as the ruby Module: as a mixin. The Schema class "includes" roles.
  class Role
    include RoleModule

    # Create a new role. If a block is provided, this block can be used
    # to define properties:
    #
    # Example:
    #  @role = Role.new('Poet') do |p|
    #    p.string :muse
    #  end
    def self.new(name, opts = nil, &block)
      if name.kind_of?(Hash)
        obj = super(name[:name] || name['name'], opts)
      else
        obj = super(name, opts)
      end

      if block_given?
        obj.property(&block)
      end
      obj
    end

    # Initialize a new role with the given name
    def initialize(name, opts = nil)
      @name = name
      initialize_role_module
    end
  end
end
