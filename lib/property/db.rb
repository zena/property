# FIXME: we should patch the connection adapters instead of having 'case, when' evaluated each time
# For example:
# module ActiveRecord
#   module ConnectionAdapters
#     class MysqlAdapter
#       include Zena::Db::MysqlAdditions
#     end
#   end
# end


module Property

  # This module is just a helper to fetch raw data from the database and could be removed in future versions of Rails
  # if the framework provides these methods.
  module Db
    extend self

    def quote(value)
      connection.quote(value)
    end

    def adapter
      connection.class.to_s[/ConnectionAdapters::(.*)Adapter/,1].downcase
    end

    def execute(*args)
      ActiveRecord::Base.connection.execute(*args)
    end

    def update(*args)
      ActiveRecord::Base.connection.update(*args)
    end

    def connection
      ActiveRecord::Base.connection
    end

    # Insert a list of values (multicolumn insert). The values should be properly escaped before
    # being passed to this method.
    def insert_many(table, columns, values)
      values = values.compact.uniq
      case adapter
      when 'sqlite3'
        pre_query = "INSERT INTO #{table} (#{columns.join(',')}) VALUES "
        values.each do |v|
          execute pre_query + "(#{v.join(',')})"
        end
      else
        values = values.map {|v| "(#{v.join(',')})"}.join(', ')
        execute "INSERT INTO #{table} (#{columns.map{|c| "`#{c}`"}.join(',')}) VALUES #{values}"
      end
    end

    def fetch_attributes(attributes, table_name, sql)
      sql = "SELECT #{attributes.map{|a| connection.quote_column_name(a)}.join(',')} FROM #{table_name} WHERE #{sql}"
      connection.select_all(sql)
    end
  end # Db
end # Property