module Property
  # A schema contains all the property definitions for a given class. If Role is a module,
  # then schema is a Class.
  class Schema < Role
    attr_accessor :roles, :klass

    # Initialize a new schema with a name and the klass linked to the schema.
    def initialize(name, opts = {})
      super
      @klass = opts[:class]

      @roles = [self]

      # Schema inheritance
      unless superschema = opts[:superschema]
        if @klass && @klass.superclass.respond_to?(:schema)
          superschema = @klass.superclass.schema
        end
      end

      if superschema
        include_role superschema
      end
    end

    # Add a set of property definitions to the schema.
    def include_role(role)
      @columns = nil # clear cache
      if role.kind_of?(Schema)
        # Superclass inheritance
        @roles << role.roles
      elsif role.kind_of?(RoleModule)
        @roles << role
      elsif role.respond_to?(:schema) && role.schema.kind_of?(Role)
        @roles << role.schema.roles
      else
        raise TypeError.new("Cannot include role #{role} (invalid type).")
      end
    end

    # Return a hash with indexed types as keys and index definitions as values.
    def index_groups
      index_groups = {}
      @roles.flatten.uniq.each do |b|
        b.indices.each do |list|
          (index_groups[list.first] ||= []) << list[1..-1]
        end
      end
      index_groups
    end

    # Return a hash with the column definitions defined in the schema and in the included
    # roles.
    def columns
      # FIXME: can we memoize this list on the first call ? Do we need to update properties after such a call ?
      # @columns ||=
      begin
        res = {}
        @roles.flatten.uniq.each do |role|
          # TODO: we could check for property redefinitions.
          res.merge!(role.defined_columns)
        end
        res
      end
    end

    # Return the list of active roles. The active roles are all the Roles included
    # in the current object for which properties have been defined (not blank).
    def used_roles_in(object)
      roles.flatten.uniq.select do |role|
        role.used_in(object)
      end
    end

    # Return true if the role has been included or is included in any superclass.
    def has_role?(role)
      if role.kind_of?(Schema)
        role.roles.flatten - @roles.flatten == []
      elsif role.kind_of?(RoleModule)
        @roles.flatten.include?(role)
      elsif role.respond_to?(:schema) && role.schema.kind_of?(Role)
        has_role?(role.schema)
      else
        false
      end
    end

    # When a column is added in a Schema: define accessors in related class
    def add_column(column)
      super
      if @klass
        @klass.define_property_methods(column) if column.should_create_accessors?
      end
    end
  end
end # Property