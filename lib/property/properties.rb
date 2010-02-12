module Property
  class Properties < Hash
    attr_accessor :owner
    include Property::DirtyProperties

    def self.json_create(serialized)
      self[serialized['data']]
    end

    def to_json(*args)
      { 'json_class' => self.class.name, 'data' => Hash[self] }.to_json(*args)
    end

    def []=(key, value)
      if column = columns[key]
        if value.blank?
          if default = column.default_for(@owner)
            super(key, default)
          else
            delete(key)
          end
        else
          super(key, column.type_cast(value.to_s))
        end
      else
        super
      end
    end

    # We need to write our own merge so that typecasting is called
    def merge!(attributes)
      raise TypeError.new("can't convert #{attributes.class} into Hash") unless attributes.kind_of?(Hash)
      attributes.each do |key, value|
        self[key] = value
      end
    end

    def validate
      column_names = columns.keys
      errors = @owner.errors
      no_errors = true

      bad_keys         = keys - column_names
      missing_keys     = column_names - keys
      keys_to_validate = keys - bad_keys

      bad_keys.each do |key|
        errors.add("#{key}", 'property is not declared')
      end

      missing_keys.each do |key|
        column = columns[key]
        if column.has_default?
          self[key] = column.default_for(@owner)
        end
      end

      keys_to_validate.each do |key|
        value  = self[key]
        column = columns[key]
        if value.blank?
          if column.has_default?
            self[key] = column.default_for(@owner)
          else
            delete(key)
          end
        else
          columns[key].validate(self[key], errors)
        end
      end

      bad_keys.empty?
    end

    def columns
      @columns ||= @owner.schema.columns
    end
  end
end
