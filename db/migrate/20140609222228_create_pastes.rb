class CreatePastes < ActiveRecord::Migration
	def self.up
		create_table :pastes do |t|
			t.string     :title, :limit => 140
			t.text       :body
			t.string     :short
			t.string     :lang_code
			t.integer    :life_time, :limit => 7, null: false
			t.timestamps
		end
		add_index :pastes, :short, :unique => true
	end

	def self.down
		drop_table :pastes
	end
end