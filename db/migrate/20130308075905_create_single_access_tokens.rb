class CreateSingleAccessTokens < ActiveRecord::Migration
  def self.up
    create_table :single_access_tokens do |t|
      t.string :client_name
      t.string :access_token

      t.timestamps
    end
  end

  def self.down
    drop_table :single_access_tokens
  end
end
