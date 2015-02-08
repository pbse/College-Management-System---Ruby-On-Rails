class CreateMenuLinkCategories < ActiveRecord::Migration
  def self.up
    create_table :menu_link_categories do |t|
      t.string :name
      t.text :allowed_roles

      t.timestamps
    end
    MenuLinkCategory.create(:name=>"academics",:allowed_roles=>[:admin,:employee,:student,:parent])
    MenuLinkCategory.create(:name=>"collaboration",:allowed_roles=>[:admin,:employee,:student,:parent])
    MenuLinkCategory.create(:name=>"data_and_reports",:allowed_roles=>[:admin,:custom_import,:custom_report_control,:custom_report_view,:data_imports_admin,:custom_export,:data_management_viewer,:data_management])
    MenuLinkCategory.create(:name=>"administration",:allowed_roles=>[:admin,:hr_basics,:employee_search,:employee_attendance,:payslip_powers,:finance_control,:transport_admin,:hostel_admin,:inventory,:inventory_manager,:inventory_basics,:general_settings,:payment,:inventory_basics])
  end

  def self.down
    drop_table :menu_link_categories
  end
end
