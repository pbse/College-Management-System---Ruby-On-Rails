if Configuration.find_by_config_key("FeatureLockAdditionalReports").try(:config_value) == "1"
  Configuration.destroy_all(:config_key => "FeatureLockAdditionalReports")
end