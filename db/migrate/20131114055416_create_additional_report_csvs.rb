class CreateAdditionalReportCsvs < ActiveRecord::Migration
  def self.up
    create_table :additional_report_csvs do |t|
      t.string :model_name
      t.string :method_name
      t.text :parameters

      t.timestamps
    end
  end

  def self.down
    drop_table :additional_report_csvs
  end
end
