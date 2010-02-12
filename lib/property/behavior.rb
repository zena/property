module Property
  # This class holds a set of property definitions. This is like a Module in ruby:
  # by 'including' this behavior in a class or in an instance, you augment the said
  # object with the behavior's property definitions.
  class Behavior
    attr_accessor :name, :included

    # Initialize a new behavior with the given name
    def initialize(name)
      @name = name
    end

    # List all property definitiosn for the current behavior
    def columns
      @columns ||= {}
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
        if columns[name.to_s]
          raise TypeError.new("Property '#{name}' is already defined.")
        else
          columns[name.to_s] = Property::Column.new(name, default, type, options)
        end
      end
  end
end
