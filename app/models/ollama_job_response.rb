# app/models/ollama_job_response.rb
class OllamaJobResponse < ApplicationRecord
    validates :job_id, presence: true, uniqueness: true
  end
  