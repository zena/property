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
      super(name, default, type, options)
    end

    def validate(value, errors)
      # Do nothing for the moment
    end

    def should_create_accessors?
      name =~ SAFE_NAMES_REGEXP
    end

    def indexed?
      @indexed
    end

    def extract_property_options(options)
      @indexed = options.delete(:indexed)
    end
  end # Column
end # Property