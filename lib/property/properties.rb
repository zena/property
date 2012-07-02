module Property
  class AttributeError < ActiveRecord::Error
    def default_options
      options.reverse_merge :scope => [:activerecord, :errors],
                            :model => @base.class.human_name,
                            :attribute => @base.class.human_attribute_name(attribute.to_s)
    end

    # SECURITY: MAKE SURE WE DO NOT SEND.
    # Value is already in 'options'.
    def value
      nil
    end
  end

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
        elsif value.kind_of?(Hash) && column.klass <= Hash && column.caster.respond_to?(:merge_hash)
          orig = self[key]
          # We *MUST* duplicate hash here or Dirty will not function correctly.
          value = column.caster.merge_hash(orig ? orig.dup : {}, value)
          if value.blank?
            if default = column.default_for(@owner)
              super(key, default)
            else
              delete(key)
            end
          else
            super(key, value)
          end
        else
          super(key, column.type_cast(value))
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

      original_hash = @original_hash || self

      bad_keys         = keys - column_names
      missing_keys     = column_names - keys
      keys_to_validate = keys - bad_keys

      bad_keys.each do |key|
        if original_hash[key] == self[key]
          # ignore invalid legacy value
        elsif self[key].blank?
          # ignore blank values
          self.delete(key)
        else
          # We use our own Error class to make sure 'send' is not used on error keys.
          errors.add(key, Property::AttributeError.new(@owner, key, nil, :message => 'property not declared', :value => self[key]))
        end
      end

      missing_keys.each do |key|
        column = columns[key]
        if column.has_default?
          self[key] = column.default_for(@owner)
        end
      end

      keys_to_validate.each do |key|
        columns[key].validate(self[key], errors)
      end

      bad_keys.empty?
    end

    def columns
      @owner.schema.columns
    end
  end
end
