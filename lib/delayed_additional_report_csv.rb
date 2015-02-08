class DelayedAdditionalReportCsv
  attr_accessor :csv_report_id
  def initialize(csv_report_id)
    @csv_report_id = csv_report_id
  end

  def perform
    @csv_report=AdditionalReportCsv.find(@csv_report_id)
    @csv_report.csv_generation
  end

end