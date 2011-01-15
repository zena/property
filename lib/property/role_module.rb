module Property
  # The RoleModule enables a class to hold information on a group of property columns.
  # This enables classes to act in the same way as the ruby Module: as a mixin.
  # The Schema class "includes" roles.
  module RoleModule
    def name
      @name
    end

    # Return true if the role contains the given column (property).
    def has_column?(name)
      column_names.include?(name)
    end

    # Return the list of column names.
    def column_names
      columns.keys
    end

    # List all property columns defined for this role
    def columns
      defined_columns
    end

    # Use this method to declare properties into a Role or Schema.
    #
    # Example:
    #  @role.property.string 'phone', :default => ''
    #
    # You can also use the "property" method in the class to access the schema:
    #
    # Example:
    #  Page.property.string 'phone', :default => ''
    #
    # You can also use a block:
    #  Page.property do |p|
    #    p.string 'phone', 'name', :default => ''
    #  end
    def property
      if block_given?
        yield self
      end
      self
    end

    %w( string text integer float decimal datetime timestamp time date binary boolean ).each do |column_type|
      class_eval <<-EOV
        def #{column_type}(*args)
          options = args.extract_options!
          column_names = args.flatten
          default = options.delete(:default)
          column_names.each { |name| add_column(Property::Column.new(name, default, '#{column_type}', options.merge(:role => self))) }
        end
      EOV
    end

    # This is used to serialize a non-native DB type. Use:
    #   p.serialize 'pet', Dog
    def serialize(name, klass, options = {})
      Property.validate_property_class(klass)
      add_column(Property::Column.new(name, nil, klass, options.merge(:role => self)))
    end

    # This is used to create complex indices with the following syntax:
    #
    #   p.index(:text) do |r| # r = record
    #     {
    #       "high"           => "gender:#{r.gender} age:#{r.age} name:#{r.name}",
    #       "name_#{r.lang}" => r.name, # multi-lingual index
    #     }
    #   end
    #
    # The first argument is the type (used to locate the table where the data will be stored) and the block
    # will be yielded with the record and should return a hash of key => value pairs.
    def index(type, &block)
      #                 type,  key, proc
      group_indices << [type, nil, block]
    end

    # Returns true if the role is used by the given object. A role is
    # considered to be used if any of it's defined columns is not blank in the object's
    # properties.
    def used_in(object)
      object.properties.keys & defined_columns.keys != []
    end

    # Returns the list of column names in the current role that are used by the
    # given object (value not blank).
    def used_keys_in(object)
      object.properties.keys & column_names
    end

    # Return a list of index definitions from the defined columns in the form [type, key, proc_or_nil]
    def defined_indices
      defined_columns.values.select do |c|
        c.indexed?
      end.map do |c|
        [c.index, c.name, c.index_proc]
      end + group_indices
    end

    def inspect
      # "#<#{self.class}:#{sprintf("0x%x", object_id)} #{@name.inspect} @klass = #{@klass.inspect} @defined_columns = #{@defined_columns.inspect}>"
      "#<#{self.class}:'#{name}' #{defined_columns.keys.join(', ')}>"
    end

    # List all property columns defined for this role
    def defined_columns
      @defined_columns ||= {}
    end

    protected
      def group_indices
        @group_indices ||= []
      end

      # @internal
      def add_column(column)
        name = column.name
        # we do not use self.defined_columns because this triggers the load_columns_from_db in StoredRole (= inf loop).
        defined_columns = (@defined_columns ||= {})

        if defined_columns[name]
          raise RedefinedPropertyError.new("Property '#{name}' is already defined.")
        else
          defined_columns[column.name] = column
          if @klass && column.should_create_accessors?
            @klass.define_property_methods(column)
          end
        end
      end
  end # RoleModule
end # Property