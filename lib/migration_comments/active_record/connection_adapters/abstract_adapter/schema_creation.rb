module MigrationComments::ActiveRecord::ConnectionAdapters::AbstractAdapter
  module SchemaCreation
    def self.included(base)
      base.class_eval do
        alias_method_chain :column_options, :migration_comments
        alias_method_chain :visit_TableDefinition, :migration_comments
        alias_method_chain :visit_ColumnDefinition, :migration_comments
      end
    end

    def column_options_with_migration_comments(o)
      column_options = o.primary_key? ? {} : column_options_without_migration_comments(o)
      column_options[:comment] = o.comment.comment_text if o.comment
      column_options
    end

    def visit_TableDefinition_with_migration_comments(o)
      if @conn.inline_comments?
        create_sql = "CREATE#{' TEMPORARY' if o.temporary} TABLE "
        create_sql << "#{quote_table_name(o.name)}#{o.table_comment} ("
        create_sql << o.columns.map { |c| accept c }.join(', ')
        create_sql << ") #{o.options}"
        create_sql
      else
        visit_TableDefinition_without_migration_comments(o)
      end
    end

    def visit_ColumnDefinition_with_migration_comments(o)
      if @conn.inline_comments?
        sql_type = type_to_sql(o.type.to_sym, o.limit, o.precision, o.scale)
        column_sql = "#{quote_column_name(o.name)} #{sql_type}"
        add_column_options!(column_sql, column_options(o))
        column_sql
      else
        visit_ColumnDefinition_without_migration_comments(o)
      end
    end
  end
end