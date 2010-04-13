module Property
  # This class stores a single property definition in the database and is used
  # with ActiveBehavior.
  class BehaviorColumn < ActiveRecord::Base
    belongs_to :active_behavior
    validates_presence_of :active_behavior

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