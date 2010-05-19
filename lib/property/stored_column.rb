module Property
  # This module should be inserted in an ActiveRecord class that stores a
  # single property definition in the database and is used with StoredRole.
  module StoredColumn
    # Default values not currently supported.
    def default
      nil
    end

    # No supported options yet.
    def options
      {:index => index?}
    end
  end
end