class CreateTradeupContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :tradeup_contracts do |t|
      t.references :tradeup_search, null: false, foreign_key: true
      t.float  :profit,     null: false
      t.string :collection, null: false
      t.text   :data,       null: false
      t.timestamps
    end
    add_index :tradeup_contracts, %i[tradeup_search_id profit]
  end
end
