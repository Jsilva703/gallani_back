class CreateApiTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :api_tokens do |t|
      t.string :label, null: false
      t.string :token_digest, null: false
      t.string :scope, null: false, default: "admin"
      t.boolean :active, null: false, default: true
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :api_tokens, :token_digest, unique: true
    add_index :api_tokens, %i[scope active]
  end
end
