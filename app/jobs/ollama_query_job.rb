# app/jobs/ollama_query_job.rb
class OllamaQueryJob < ApplicationJob
  queue_as :default

  def perform(prompt, job_id)
    begin
      # Query the model
      response = OllamaModelService.query(prompt)

      # Save the response to the database
      OllamaJobResponse.create!(
        job_id: job_id,
        prompt: prompt,
        state: 'done',
        data: response
      )
    rescue StandardError => e
      # Save the error to the database
      OllamaJobResponse.create!(
        job_id: job_id,
        prompt: prompt,
        state: 'error',
        error: e.message
      )
    end
  end
end
