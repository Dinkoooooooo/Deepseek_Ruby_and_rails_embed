Here's a complete step-by-step guide to set up a ChatGPT integration using Delayed Job for background processing.

1. Setup Delayed Job
Add Delayed Job to your Gemfile:

ruby
Copy
Edit
gem 'delayed_job_active_record'
Install the gem:

bash
Copy
Edit
bundle install
Generate the required migration for Delayed Job and migrate the database:

bash
Copy
Edit
rails generate delayed_job:active_record
rails db:migrate
Start the Delayed Job worker:

bash
Copy
Edit
bin/delayed_job start
2. Create a Model for Job Responses
You’ll need a model to store the ChatGPT responses.

Generate the model:

bash
Copy
Edit
rails generate model ChatGptJobResponse job_id:string state:string data:text error:text
Migrate the database:

bash
Copy
Edit
rails db:migrate
Add validations to the model (app/models/chat_gpt_job_response.rb):

ruby
Copy
Edit
class ChatGptJobResponse < ApplicationRecord
  validates :job_id, presence: true, uniqueness: true
end
3. Set Up the Job
Create a background job to handle the ChatGPT API call.

Generate the job:

bash
Copy
Edit
rails generate job chat_gpt_query
Update the job file (app/jobs/chat_gpt_query_job.rb):

ruby
Copy
Edit
class ChatGptQueryJob < ApplicationJob
  queue_as :default

  def perform(prompt, job_id)
    begin
      # Call ChatGPT API
      client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
      response = client.completions(
        parameters: {
          model: "gpt-4",
          prompt: prompt,
          max_tokens: 150
        }
      )

      # Save response in the database
      job_response = ChatGptJobResponse.find_or_initialize_by(job_id: job_id)
      job_response.update!(state: 'done', data: response['choices'].first['text'])
    rescue StandardError => e
      # Handle errors
      job_response = ChatGptJobResponse.find_or_initialize_by(job_id: job_id)
      job_response.update!(state: 'error', error: e.message)
    end
  end
end
4. Create the Controller
Create a controller to handle frontend requests and query job statuses.

Create app/controllers/api/chat_gpt_models_controller.rb:

ruby
Copy
Edit
module Api
  class ChatGptModelsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def query
      prompt = params[:prompt]

      if prompt.blank?
        render json: { error: "Prompt cannot be blank" }, status: :unprocessable_entity
        return
      end

      # Generate a unique job ID
      job_id = SecureRandom.uuid

      # Queue the job
      ChatGptQueryJob.perform_later(prompt, job_id)

      # Respond with job ID
      render json: { job_id: job_id }, status: :accepted
    end

    def job_status
      job_id = params[:job_id]
      job_response = ChatGptJobResponse.find_by(job_id: job_id)

      if job_response
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
5. Add Routes
Define routes for the API endpoints.

Edit config/routes.rb:

ruby
Copy
Edit
namespace :api do
  resources :chat_gpt_models, only: [] do
    collection do
      post :query
      get :job_status
    end
  end
end
6. Frontend Integration
To test the API or connect it to your frontend:

Query Endpoint (/api/chat_gpt_models/query):

json
Copy
Edit
POST /api/chat_gpt_models/query
{
  "prompt": "Your question here"
}
Response:

json
Copy
Edit
{
  "job_id": "123e4567-e89b-12d3-a456-426614174000"
}
Job Status Endpoint (/api/chat_gpt_models/job_status):

json
Copy
Edit
GET /api/chat_gpt_models/job_status?job_id=123e4567-e89b-12d3-a456-426614174000
Response while the job is still running:

json
Copy
Edit
{
  "state": "pending"
}
Response when the job is done:

json
Copy
Edit
{
  "state": "done",
  "data": "ChatGPT response here",
  "error": null
}
Response if an error occurred:

json
Copy
Edit
{
  "state": "error",
  "data": null,
  "error": "Error message here"
}
7. Test the Setup
Start the Rails server:

bash
Copy
Edit
rails server
Use a tool like Postman, Curl, or your frontend to send requests.

Monitor the background jobs in Delayed Job:

bash
Copy
Edit
rails jobs:work
8. Optional: Monitor Delayed Job
To monitor and manage background jobs, you can use a gem like Delayed Job Web:

Add it to your Gemfile:

ruby
Copy
Edit
gem 'delayed_job_web'
Mount it in your routes (config/routes.rb):

ruby
Copy
Edit
mount DelayedJobWeb => '/delayed_job'
Access the web interface at http://localhost:3000/delayed_job.
