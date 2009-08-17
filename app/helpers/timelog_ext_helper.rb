module TimelogExtHelper
  include TimelogHelper

  def sum_costs(data)
    sum_cost = 0
    data.each do |item|
      sum_cost += item['cost'].to_f
    end
   sum_cost
  end

  def avg_rate(data)
    result = 0
    if data.length > 0
      sum_rate = 0
      data.each do |item|
        sum_rate += item['rate_amount'].to_f
      end
      result = sum_rate/data.length
    end
    result
  end

  def entries_to_csv_with_rate(entries)
    ic = Iconv.new(l(:general_csv_encoding), 'UTF-8')
    decimal_separator = l(:general_csv_decimal_separator)
    custom_fields = TimeEntryCustomField.find(:all)
    export = StringIO.new
    CSV::Writer.generate(export, l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [l(:field_spent_on),
                 l(:field_user),
                 l(:field_activity),
                 l(:field_project),
                 l(:field_issue),
                 l(:field_tracker),
                 l(:field_subject),
                 l(:field_hours),
                 l(:rate_label_rate),
                 l(:rate_ext_label_cost),
                 l(:field_comments)
                 ]
      # Export custom fields
      headers += custom_fields.collect(&:name)
      
      csv << headers.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      # csv lines
      entries.each do |entry|
        fields = [format_date(entry.spent_on),
                  entry.user,
                  entry.activity,
                  entry.project,
                  (entry.issue ? entry.issue.id : nil),
                  (entry.issue ? entry.issue.tracker : nil),
                  (entry.issue ? entry.issue.subject : nil),
                  entry.hours.to_s.gsub('.', decimal_separator),
                  (entry.cost.to_f / entry.hours.to_f).to_s.gsub('.', decimal_separator),
                  entry.cost.to_s.gsub('.', decimal_separator),
                  entry.comments
                  ]
        fields += custom_fields.collect {|f| show_value(entry.custom_value_for(f)) }
                  
        csv << fields.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      end
    end
    export.rewind
    export
  end
    
  def report_to_csv_with_rate(criterias, periods, hours)
    export = StringIO.new
    CSV::Writer.generate(export, l(:general_csv_separator)) do |csv|
      # Column headers
      headers = criterias.collect {|criteria| l(@available_criterias[criteria][:label]) }
      headers += periods
      headers << l(:label_total)
      headers << l(:rate_label_rate)
      headers << l(:rate_ext_label_total_cost)
      csv << headers.collect {|c| to_utf8(c) }
      # Content
      report_criteria_to_csv(csv, criterias, periods, hours)
      # Total row
      row = [ l(:label_total) ] + [''] * (criterias.size - 1)
      total = 0
      tcost = 0
      periods.each do |period|
        sum = sum_hours(select_hours(hours, @columns, period.to_s))
        cost = sum_costs(select_hours(hours, @columns, period.to_s))
        total += sum
        tcost += cost
        row << (sum > 0 ? "%.2f" % sum : '')
      end
      row << "%.2f" %total
      row << " "
      row << "%.2f" %tcost
      csv << row
    end
    export.rewind
    export
  end

  def report_criteria_to_csv_with_rate(csv, criterias, periods, hours, level=0)
    hours.collect {|h| h[criterias[level]].to_s}.uniq.each do |value|
      hours_for_value = select_hours(hours, criterias[level], value)
      next if hours_for_value.empty?
      row = [''] * level
      row << to_utf8(format_criteria_value(criterias[level], value))
      row += [''] * (criterias.length - level - 1)
      total = 0
      tcost = 0
      periods.each do |period|
        sum = sum_hours(select_hours(hours_for_value, @columns, period.to_s))
        cost = sum_costs(select_hours(hours_for_value, @columns, period.to_s))
        total += sum
        tcost += cost
        row << (sum > 0 ? "%.2f" % sum : '')
      end
      row << "%.2f" %total
      row << "%.2f" %avg_rate(hours_for_value)
      row << "%.2f" %tcost
      csv << row
    
      if criterias.length > level + 1
        report_criteria_to_csv(csv, criterias, periods, hours_for_value, level + 1)
      end
    end
  end

  alias_method_chain :entries_to_csv, :rate
  alias_method_chain :report_to_csv, :rate
  alias_method_chain :report_criteria_to_csv, :rate

end
