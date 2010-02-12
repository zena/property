module Property
  # This class holds a set of property definitions. This is like a Module in ruby:
  # by 'including' this behavior in a class or in an instance, you augment the said
  # object with the behavior's property definitions.
  class Behavior
    attr_accessor :name, :included

    def self.new(name, dependant_schema = nil)
      obj = super
      if block_given?
        yield obj
      end
      obj
    end

    # Initialize a new behavior with the given name
    def initialize(name, dependant_schema = nil)
      @dependant_schema = dependant_schema
      @name  = name
    end

    # List all property definitiosn for the current behavior
    def columns
      @columns ||= {}
    end

    # Return the list of column names.
    def column_names
      columns.keys
    end

    # Use this method to declare properties into a Behavior.
    # Example:
    #  @behavior.property.string 'phone', :default => ''
    #
    # You can also use a block:
    #  @behavior.property do |p|
    #    p.string 'phone', 'name', :default => ''
    #  end
    def property
      if block_given?
        yield self
      end
      self
    end

    # If someday we find the need to insert other native classes directly in the DB, we
    # could use this:
    # p.serialize MyClass, xxx, xxx
    # def serialize(klass, name, options={})
    #   if @klass.super_schema.columns[name.to_s]
    #     raise TypeError.new("Property '#{name}' is already defined in a superclass.")
    #   elsif !@klass.validate_property_class(type)
    #     raise TypeError.new("Custom type '#{type}' cannot be serialized.")
    #   else
    #     # Find a way to insert the type (maybe with 'serialize'...)
    #     # (@klass.own_schema.columns ||= {})[name] = Property::Column.new(name, type, options)
    #   end
    # end

    # def string(*args)
    #   options = args.extract_options!
    #   column_names = args
    #   default = options.delete(:default)
    #   column_names.each { |name| column(name, default, 'string', options) }
    # end
    %w( string text integer float decimal datetime timestamp time date binary boolean ).each do |column_type|
      class_eval <<-EOV
        def #{column_type}(*args)
          options = args.extract_options!
          column_names = args
          default = options.delete(:default)
          column_names.each { |name| add_column(name, default, '#{column_type}', options) }
        end
      EOV
    end

    private
      def add_column(name, default, type, options)
        raise TypeError.new("Cannot modify a Behavior that has already been included") if @included

        if columns[name.to_s]
          raise TypeError.new("Property '#{name}' is already defined.")
        else
          column = Property::Column.new(name, default, type, options)
          if @dependant_schema
            @dependant_schema.add_column(column)
          end
          columns[column.name] = column
        end
      end
  end
end
