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
          Property::Db.fetch_attributes(['key', 'value'], index_table_name(group_name), index_reader_sql(group_name)).each do |row|
            res[row['key']] = row['value']
          end
          res
        end

        def index_reader_sql(group_name)
          @index_reader_sql ||= begin
            index_reader(group_name).map do |k, v|
              if k == :with
                v.map do |subk, subv|
                  if subv.kind_of?(Array)
                    "`#{subk}` IN (#{subv.map {|ssubv| connection.quote(ssubv)}.join(',')})"
                  else
                    "`#{subk}` = #{self.class.connection.quote(subv)}"
                  end
                end.join(' AND ')
              else
                "`#{k}` = #{self.class.connection.quote(v)}"
              end
            end.join(' AND ')
          end
        end

        def index_reader(group_name)
          {index_foreign_key => self.id}
        end

        def index_writer(group_name)
          index_reader(group_name)
        end

        def index_table_name(group_name)
          "i_#{group_name}_#{self.class.table_name}"
        end

        def index_foreign_key
          @index_foreign_key ||=self.class.table_name.singularize.foreign_key
        end

        # Create a list of index entries
        def create_indices(group_name, new_keys, cur_indices)
          # Build insert_many query
          writer       = index_writer(group_name)
          foreign_keys = index_foreign_keys(writer)

          Property::Db.insert_many(
            index_table_name(group_name),
            foreign_keys + %w{key value},
            map_index_values(new_keys, cur_indices, foreign_keys, writer)
          )
        end

        def index_foreign_keys(writer)
          if with = writer[:with]
            writer.keys - [:with] + with.keys
          else
            writer.keys
          end
        end

        def map_index_values(new_keys, cur_indices, index_foreign_keys, index_writer)
          if with = index_writer[:with]
            foreign_values = explode_list(index_foreign_keys.map {|k| index_writer[k] || with[k]})
          else
            foreign_values = [index_foreign_keys.map {|k| index_writer[k]}]
          end

          values = new_keys.map do |key|
            [connection.quote(key), connection.quote(cur_indices[key])]
          end

          res = []
          foreign_values.each do |list|
            list = list.map {|k| connection.quote(k)}
            values.each do |value|
              res << (list + value)
            end
          end
          res
        end

        # Takes a mixed array and explodes it
        # [x, ['en','fr'], y, [a,b]] ==> [[x,'en',y,a], [x,'en',y',b], [x,'fr',y,a], [x,'fr',y,b]]
        def explode_list(list)
          res = [[]]
          list.each do |key|
            if key.kind_of?(Array)
              res_bak = res
              res = []
              key.each do |k|
                res_bak.each do |list|
                  res << (list + [k])
                end
              end
            else
              res.each do |list|
                list << key
              end
            end
          end
          res
        end

        # Update an index entry
        def update_index(group_name, key, value)
          self.class.connection.execute "UPDATE #{index_table_name(group_name)} SET `value` = #{connection.quote(value)} WHERE #{index_reader_sql(group_name)} AND `key` = #{connection.quote(key)}"
        end

        # Delete a list of indices (value became blank).
        def delete_indices(group_name, keys)
          self.class.connection.execute "DELETE FROM #{index_table_name(group_name)} WHERE #{index_reader_sql(group_name)} AND `key` IN (#{keys.map{|key| connection.quote(key)}.join(',')})"
        end

        # This method prepares the index
        def property_index
          schema.index_groups.each do |group_name, definitions|
            cur_indices = {}
            definitions.each do |key, proc|
              if key
                value = prop[key]
                if !value.blank?
                  if proc
                    # Get value(s) to index through proc
                    cur_indices.merge!(proc.call(self))
                  else
                    # Set current value from prop
                    cur_indices[key] = value
                  end
                end
              else
                # No key: group index generated with
                # p.index(group_name) do |record| ...
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

              upd_keys.each do |key|
                value = cur_indices[key]
                if value.blank?
                  del_keys << key
                elsif value != old_indices[key]
                  update_index(group_name, key, value)
                end
              end

              if !del_keys.empty?
                delete_indices(group_name, del_keys)
              end

              new_keys.reject! {|k| cur_indices[k].blank? }
              if !new_keys.empty?
                create_indices(group_name, new_keys, cur_indices)
              end
            end
          end
          @index_reader_sql = nil
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