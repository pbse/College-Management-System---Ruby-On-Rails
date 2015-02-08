class UpdateMangerIdRecordAsUserId < ActiveRecord::Migration
  def self.up

    #employee manager_id update
    all_employees= ActiveRecord::Base.connection.execute("select * from employees").all_hashes
    all_employees.each do |e|
      if e["reporting_manager_id"].present?
        sql="UPDATE employees AS x INNER JOIN employees AS y ON x.reporting_manager_id = y.id SET x.reporting_manager_id = y.user_id"
        ActiveRecord::Base.connection.execute(sql)
      end
    end

    #archived_employee manager_id update
    all_archived_employees= ActiveRecord::Base.connection.execute("select * from archived_employees").all_hashes
    is_user_id_present = false
    if ActiveRecord::Base.connection.execute("desc archived_employees").all_hashes.map{|f| f["Field"]}.include?("user_id")
      is_user_id_present = true
    end
    all_archived_employees.each do |a_e|
      if a_e["reporting_manager_id"].present?
        #search in employee table
        manager = ActiveRecord::Base.connection.execute("select user_id from employees where id=#{a_e["reporting_manager_id"]}").all_hashes
        #search in archived_employee table
        unless manager.present? and (is_user_id_present == true)
          manager = ActiveRecord::Base.connection.execute("select user_id from archived_employees where former_id=#{a_e["reporting_manager_id"]}").all_hashes
        end
        if manager.present? and manager.first.present? and manager.first["user_id"].present?
          sql="update archived_employees set reporting_manager_id=#{manager.first["user_id"]} where id=#{a_e["id"]}"
        else
          sql="update archived_employees set reporting_manager_id=NULL where id=#{a_e["id"]}"
        end
        #final update in archived_employees table
        ActiveRecord::Base.connection.execute(sql)
      end
    end

  end

  def self.down
    
  end
end
