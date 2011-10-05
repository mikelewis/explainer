if ["development", "test"].include? Rails.env

  # Thanks http://efficient-sql.rubyforge.org/svn/lib/assert_efficient_sql.rb for formatting array
  class Array
    protected
    def qa_columnized_row(fields, sized)
      row = []
      fields.each_with_index do |f, i|
        row << sprintf("%0-#{sized[i]}s", f.to_s)
      end
      row.join(' | ')
    end

    public

    def qa_columnized
      sized = {}
      self.each do |row|
        row.values.each_with_index do |value, i|
          sized[i] = [sized[i].to_i, row.keys[i].length, value.to_s.length].max
        end
      end

      table = []
      table << qa_columnized_row(self.first.keys, sized)
      table << '-' * table.first.length
      self.each { |row| table << qa_columnized_row(row.values, sized) }
      table.join("\n   ") # Spaces added to work with format_log_entry
    end
  end

  class ActiveRecord::ConnectionAdapters::Mysql2Adapter
    private
    alias :old_select :select
    def select(sql, name=nil, binds=[])
      r = old_select(sql, name, binds)
      if sql.start_with?("SELECT")
        table = exec_query("EXPLAIN #{sql.gsub("\0") { quote(*binds.dup.shift.reverse) }}").to_a.qa_columnized
        @logger.debug("\n\n\033[1;34m############ EXPLAIN QUERY for #{name} ############ \033[0m\n" + table + "\n\n")
      end
      r
    end
  end
end
