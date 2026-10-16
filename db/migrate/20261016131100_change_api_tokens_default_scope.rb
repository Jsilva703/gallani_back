class ChangeApiTokensDefaultScope < ActiveRecord::Migration[7.1]
  def change
    change_column_default :api_tokens, :scope, from: "admin", to: "integration"
  end
end
