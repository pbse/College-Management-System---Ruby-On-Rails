module TimetablesHelper
  def formatted_timetable_cell(tt)
    ## Produces view for one particular timetable entry cell
    unless tt.blank?
      unless tt.subject.blank?
        "#{tt.subject.code}\n"
      end
    end
  end
  def formatted_timetable_cell_2(tt,emp)
    ## Produces view for one particular timetable entry cell
    unless tt.blank?
      unless tt.subject.blank?
        unless tt.subject.elective_group.nil?
          sub=tt.subject.elective_group.subjects.select{|s| s.employees.include?(emp)}
          "#{shorten_string(sub.first.code,10)}\n" unless sub.empty?
        else
          "#{shorten_string(tt.subject.code,9)}\n"
        end
      end
    end
  end
  def subject_name(tt)
    ## Produces view for one particular timetable entry cell
    unless tt.blank?
      unless tt.subject.blank?
        "#{tt.subject.name}\n"
      end
    end
  end
  def timetable_batch(tt)
    ## Produces view for one particular timetable entry cell
    unless tt.blank?
      unless tt.batch.blank?
        "#{shorten_string(tt.batch.full_name,15)}"
      end
    end
  end
  def employee_name(tt)
    ## Produces view for one particular timetable entry cell
    unless tt.blank?
      unless tt.employee.blank?
        "#{tt.employee.first_name}"
      end
    end
  end
  def employee_full_name(tt)
    ## Produces view for one particular timetable entry cell
    unless tt.blank?
      unless tt.employee.blank?
        "#{tt.employee.full_name}"
      end
    end
  end
  def split_str(str, len)
  fragment = /.{#{len}}/
  str.split(/(\s+)/).map! { |word|
    (/\s/ === word) ? word : word.gsub(fragment, '\0<wbr></wbr>')
  }.join
end
end