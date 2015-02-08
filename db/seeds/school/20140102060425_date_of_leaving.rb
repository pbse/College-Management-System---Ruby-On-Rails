
sql_update = "update archived_students set date_of_leaving=created_at where date_of_leaving is NULL"
ActiveRecord::Base.connection.execute(sql_update)