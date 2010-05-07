
module Property
  # This class holds all the properties of a given class or instance. It is used
  # to validate content and type_cast during write operations.
  #
  # The properties are not directly defined in the schema. They are stored in a
  # Role instance which checks that the database is in sync with the properties
  # defined.
  class Schema
    attr_reader :roles, :role, :binding

    # Create a new Schema. If a class_name is provided, the schema automatically
    # creates a default Role to store definitions.
    def initialize(class_name, binding)
      @binding = binding
      @roles = []
      if class_name
        @role  = Role.new(class_name)
        include_role @role
        @roles << @role
      end
    end

    # Return an identifier for the schema to help locate property redefinition errors.
    def name
      @role ? @role.name : @binding.to_s
    end

    # If the parameter is a class, the schema will inherit the property definitions
    # from the class. If the parameter is a Role, the properties from that
    # role will be included. Any new columns added to a role or any new
    # roles included in a class will be dynamically added to the sub-classes (just like
    # Ruby class inheritance, module inclusion works).
    # If you ...
    def has_role(thing)
      if thing.kind_of?(Class)
        if thing.respond_to?(:schema) && thing.schema.kind_of?(Schema)
          schema_class = thing.schema.binding
          if @binding.ancestors.include?(schema_class)
            check_super_methods = false
          else
            check_super_methods = true
          end
          thing.schema.roles.flatten.each do |role|
            include_role role, check_super_methods
          end
          self.roles << thing.schema.roles
        else
          raise TypeError.new("expected Role or class with schema, found #{thing}")
        end
      elsif thing.kind_of?(RoleModule)
        include_role thing
        self.roles << thing
      else
        raise TypeError.new("expected Role or class with schema, found #{thing.class}")
      end
    end

    # Return the list of active roles. The active roles are all the Roles included
    # in the current object for which properties have been defined (not blank).
    def used_roles_in(object)
      roles.flatten.uniq.reject do |role|
        !role.used_in(object)
      end
    end

    # Return the list of column names.
    def column_names
      columns.keys
    end

    # Return true if the schema has a property with the given name.
    def has_column?(name)
      name = name.to_s
      [@roles].flatten.each do |role|
        return true if role.has_column?(name)
      end
      false
    end

    # Return column definitions from all included roles.
    def columns
      columns = {}
      @roles.flatten.uniq.each do |b|
        columns.merge!(b.columns)
      end
      columns
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

    private
      def include_role(role, check_methods = true)
        return if roles.flatten.include?(role)

        stored_column_names = role.column_names

        check_duplicate_property_definitions(role, stored_column_names)
        check_duplicate_method_definitions(role, stored_column_names) if check_methods

        role.included_in(self)
        @binding.send(:include, role.accessor_module)
      end

      def check_duplicate_property_definitions(role, keys)
        common_keys = keys & self.columns.keys
        if !common_keys.empty?
          raise RedefinedPropertyError.new("Cannot include role '#{role.name}' in '#{name}'. Duplicate definitions: #{common_keys.join(', ')}")
        end
      end

      def check_duplicate_method_definitions(role, keys)
        common_keys = []
        keys.each do |k|
          common_keys << k if @binding.superclass.method_defined?(k)
        end

        if !common_keys.empty?
          raise RedefinedMethodError.new("Cannot include role '#{role.name}' in '#{@binding}'. Would hide methods in superclass: #{common_keys.join(', ')}")
        end
      end

  end
end
