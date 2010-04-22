module Property
  # This class stores a single property definition in the database and is used
  # with StoredRole.
  class StoredColumn < ActiveRecord::Base
    belongs_to :stored_role
    validates_presence_of :stored_role

    # Default values not currently supported.
    def default
      nil
    end

    # No supported options yet.
    def options
      {}
    end
  end
end