class CreateTradeupSearches < ActiveRecord::Migration[8.1]
  def change
    create_table :tradeup_searches do |t|
      t.text    :params_json,    null: false
      t.string  :status,         null: false, default: "pending"
      t.integer :total_jobs
      t.integer :completed_jobs, null: false, default: 0
      t.timestamps
    end
  end
end
