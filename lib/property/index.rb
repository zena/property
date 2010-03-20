require 'versions/after_commit' # we need Versions gem's 'after_commit'

module Property

  # Property::Declaration module is used to declare property definitions in a Class. The module
  # also manages property inheritence in sub-classes.
  module Index

    def self.included(base)
      base.class_eval do
        extend  ClassMethods
        include InstanceMethods
        before_save :property_index
        before_destroy :property_index_destroy
      end
    end

    module ClassMethods
    end

    module InstanceMethods

      private
        # Retrieve the current indexes for a given group (:string, :text, etc)
        def get_indexes(group_name)
          return {} if new_record?
          res = {}
          Property::Db.fetch_attributes(['key', 'value'], index_table_name(group_name), "#{index_foreign_key} = #{self.id}").each do |row|
            res[row['key']] = row['value']
          end
          res
        end

        def index_table_name(group_name)
          "i_#{group_name}_#{self.class.table_name}"
        end

        def index_foreign_key
          self.class.table_name.singularize.foreign_key
        end

        # This method prepares the index
        def property_index
          connection  = self.class.connection
          foreign_key = index_foreign_key

          schema.index_groups.each do |group_name, definitions|
            old_indexes = get_indexes(group_name)
            cur_indexes = {}
            definitions.each do |key_or_proc|
              if key_or_proc.kind_of?(Proc)
                cur_indexes.merge!(key_or_proc.call(self))
              else
                cur_indexes[key_or_proc] = prop[key_or_proc]
              end
            end

            old_keys = old_indexes.keys
            cur_keys = cur_indexes.keys

            new_keys = cur_keys - old_keys
            del_keys = old_keys - cur_keys
            upd_keys = cur_keys & old_keys

            after_commit do
              table_name  = index_table_name(group_name)

              upd_keys.each do |key|
                value = cur_indexes[key]
                if value.blank?
                  del_keys << key
                else
                  connection.execute "UPDATE #{table_name} SET value = #{connection.quote(cur_indexes[key])} WHERE #{foreign_key} = #{self.id} AND key = #{connection.quote(key)}"
                end
              end

              if !del_keys.empty?
                connection.execute "DELETE FROM #{table_name} WHERE #{foreign_key} = #{self.id} AND key IN (#{del_keys.map{|key| connection.quote(key)}.join(',')})"
              end

              new_keys.reject! {|k| cur_indexes[k].blank? }
              if !new_keys.empty?
                Property::Db.insert_many(
                  table_name,
                  [foreign_key, 'key', 'value'],
                  new_keys.map do |key|
                    [self.id, connection.quote(key), connection.quote(cur_indexes[key])]
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
            after_commit do
              connection.execute "DELETE FROM #{index_table_name(group_name)} WHERE #{foreign_key} = #{current_id}"
            end
          end
        end
    end
  end
end