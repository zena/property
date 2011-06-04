module Property
  # This module should be inserted in an ActiveRecord class that stores a
  # single property definition in the database and is used with StoredRole.
  module StoredColumn
    def self.included(base)
      base.before_validation :set_index
    end

    # Default values not currently supported.
    def default
      nil
    end

    # No supported options yet.
    def options
      {:index => (index.blank? ? nil : index)}
    end

    # Dummy, can be reimplemented in the class storing the column.
    def type_cast(value)
      nil
    end

    private
      def set_index
        if index == true
          self.index = ptype.to_s
        elsif index.blank?
          self.index = nil
        else
          self.index = self.index.to_s
        end
      end
  end
end