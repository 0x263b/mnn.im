class CreateShorts < ActiveRecord::Migration
	def self.up
		create_table :shorts do |t|
			t.string     :long, :limit => 2024
			t.string     :short
			t.integer    :life_time, :limit => 7, null: false
			t.timestamps
		end
		add_index :shorts, :short, :unique => true
	end

	def self.down
		drop_table :shorts
	end
end
