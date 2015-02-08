class AddAttachmentToAdditionalReportCsv < ActiveRecord::Migration
  def self.up
    add_column :additional_report_csvs, :csv_report_file_name, :string
    add_column :additional_report_csvs, :csv_report_content_type, :string
    add_column :additional_report_csvs, :csv_report_file_size, :integer
    add_column :additional_report_csvs, :csv_report_updated_at, :datetime
  end

  def self.down
    remove_column :additional_report_csvs, :csv_report_file_name
    remove_column :additional_report_csvs, :csv_report_content_type
    remove_column :additional_report_csvs, :csv_report_file_size
    remove_column :additional_report_csvs, :csv_report_updated_at
  end
end
