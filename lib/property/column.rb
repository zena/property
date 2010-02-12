require 'active_record'
ActiveRecord.load_all!

module Property
  # The Column class is used to hold information about a Property declaration,
  # such as name, type and options. It is also used to typecast from strings to
  # the proper type (date, integer, float, etc).
  class Column < ::ActiveRecord::ConnectionAdapters::Column
    SAFE_NAMES_REGEXP = %r{\A[a-zA-Z_]+\Z}

    def initialize(name, default, type, options={})
      name = name.to_s
      extract_property_options(options)
      if type.kind_of?(Class)
        @klass = type
      end
      super(name, default, type, options)
    end

    def validate(value, errors)
      if @klass && !value.kind_of?(@klass)
        errors.add(name, "cannot cast #{value.class} to #{@klass}")
      end
    end

    def should_create_accessors?
      name =~ SAFE_NAMES_REGEXP
    end

    def indexed?
      @indexed
    end

    def default_for(owner)
      if default.kind_of?(Proc)
        default.call
      elsif default.kind_of?(Symbol)
        owner.send(default)
      else
        default
      end
    end

    def klass
      @klass || super
    end

    def type_cast(value)
      if type == :string
        value = value.to_s
        value.blank? ? nil : value
      elsif @klass
        value
      else
        super
      end
    end

    private
      def extract_property_options(options)
        @indexed = options.delete(:indexed)
      end

      def extract_default(default)
        (default.kind_of?(Proc) || default.kind_of?(Symbol)) ? default : type_cast(default)
      end

  end # Column
end # Property