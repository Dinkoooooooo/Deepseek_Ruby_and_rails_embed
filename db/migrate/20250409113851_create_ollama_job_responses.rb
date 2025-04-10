class CreateOllamaJobResponses < ActiveRecord::Migration[7.2]
  def change
    create_table :ollama_job_responses do |t|
      t.string :job_id
      t.text :prompt
      t.string :state
      t.text :data
      t.text :error

      t.timestamps
    end
  end
end
