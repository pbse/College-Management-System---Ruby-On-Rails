class CreateBiometricInformations < ActiveRecord::Migration
  def self.up
    create_table :biometric_informations do |t|
      t.references :user
      t.string :biometric_id

      t.timestamps
    end
  end

  def self.down
    drop_table :biometric_informations
  end
end
