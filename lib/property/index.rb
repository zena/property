module Property

  # Property::Declaration module is used to declare property definitions in a Class. The module
  # also manages property inheritence in sub-classes.
  module Index

    def self.included(base)
      base.class_eval do
        extend  ClassMethods
        include InstanceMethods
        after_save :property_index
        after_destroy :property_index_destroy
      end
    end

    module ClassMethods
    end

    module InstanceMethods

      private
        # Retrieve the current indices for a given group (:string, :text, etc)
        def get_indices(group_name)
          return {} if new_record?
          res = {}
          Property::Db.fetch_attributes(['key', 'value'], index_table_name(group_name), index_reader_sql).each do |row|
            res[row['key']] = row['value']
          end
          res
        end

        def index_reader_sql
          index_reader.map {|k, v| "`#{k}` = #{self.class.connection.quote(v)}"}.join(' AND ')
        end

        def index_reader
          {index_foreign_key => self.id}
        end

        alias index_writer index_reader

        def index_table_name(group_name)
          "i_#{group_name}_#{self.class.table_name}"
        end

        def index_foreign_key
          self.class.table_name.singularize.foreign_key
        end

        # This method prepares the index
        def property_index
          connection     = self.class.connection
          reader_sql     = index_reader_sql
          foreign_keys   = nil
          foreign_values = nil

          schema.index_groups.each do |group_name, definitions|
            cur_indices = {}
            definitions.each do |key, proc|
              if key
                value = prop[key]
                if !value.blank?
                  if proc
                    cur_indices.merge!(proc.call(self))
                  else
                    cur_indices[key] = value
                  end
                end
              else
                cur_indices.merge!(proc.call(self))
              end
            end

            if group_name.kind_of?(Class)
              # Use a custom indexer
              group_name.set_property_index(self, cur_indices)
            else
              # Add key/value pairs to the default tables
              old_indices = get_indices(group_name)

              old_keys = old_indices.keys
              cur_keys = cur_indices.keys

              new_keys = cur_keys - old_keys
              del_keys = old_keys - cur_keys
              upd_keys = cur_keys & old_keys

              table_name  = index_table_name(group_name)

              upd_keys.each do |key|
                value = cur_indices[key]
                if value.blank?
                  del_keys << key
                else
                  connection.execute "UPDATE #{table_name} SET `value` = #{connection.quote(cur_indices[key])} WHERE #{reader_sql} AND `key` = #{connection.quote(key)}"
                end
              end

              if !del_keys.empty?
                connection.execute "DELETE FROM #{table_name} WHERE #{reader_sql} AND `key` IN (#{del_keys.map{|key| connection.quote(key)}.join(',')})"
              end

              new_keys.reject! {|k| cur_indices[k].blank? }
              if !new_keys.empty?
                # we evaluate this now to have the id on record creation
                foreign_keys   ||= index_writer.keys
                foreign_values ||= foreign_keys.map {|k| index_writer[k]}

                Property::Db.insert_many(
                  table_name,
                  foreign_keys + ['key', 'value'],
                  new_keys.map do |key|
                    foreign_values + [connection.quote(key), connection.quote(cur_indices[key])]
                  end
                )
              end
            end
          end
        end

        # Remove all index entries on destroy
        def property_index_destroy
          connection  = self.class.connection
          foreign_key = index_foreign_key
          current_id  = self.id
          schema.index_groups.each do |group_name, definitions|
            if group_name.kind_of?(Class)
              group_name.delete_property_index(self)
            else
              connection.execute "DELETE FROM #{index_table_name(group_name)} WHERE `#{foreign_key}` = #{current_id}"
            end
          end
        end
    end
  end
end