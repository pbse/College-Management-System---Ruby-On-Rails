class AddIndicesForAdditionalReports < ActiveRecord::Migration
  def self.up
    add_index :finance_fees, [:student_id,:fee_collection_id,:is_paid],:name => "index_on_is_paid"
    add_index :finance_fee_collections, [:batch_id]
    add_index :batches, [:course_id]
  end

  def self.down
    remove_index :students, :name => "index_on_is_paid"
    remove_index :finance_fee_collections, [:batch_id]
    remove_index :batches, [:course_id]
  end
end
