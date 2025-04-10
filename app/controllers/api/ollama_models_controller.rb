# app/controllers/api/ollama_models_controller.rb
module Api
  class OllamaModelsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def query
      prompt = params[:prompt]

      if prompt.blank?
        render json: { error: "Prompt cannot be blank" }, status: :unprocessable_entity
        return
      end

      # Generate a unique job ID
      job_id = SecureRandom.uuid

      # Schedule the background job
      OllamaQueryJob.perform_later(prompt, job_id)

      # Return the job ID to the client
      render json: { job_id: job_id }, status: :accepted
    end

    def job_status
      job_id = params[:job_id]
      job_response = OllamaJobResponse.find_by(job_id: job_id)
      Rails.logger.info("Job_id: #{job_id}")
      Rails.logger.info("job_response: #{job_response.inspect}")


    
      if job_response
        Rails.logger.info("OKE SO IT IS ACTIVATING THE JOB_reponse")
        render json: {
          state: job_response.state,
          data: job_response.data,
          error: job_response.error
        }, status: :ok
      else
        render json: { state: 'pending' }, status: :ok
      end
    end
  end
end
