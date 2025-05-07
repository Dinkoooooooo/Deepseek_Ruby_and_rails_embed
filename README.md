# Complete Guide: Setting Up ChatGPT Integration with Delayed Job

This guide walks you through the complete process of integrating ChatGPT with your Rails application using Delayed Job for background processing. It includes all steps and reflects the latest changes to the `ChatGptQueryJob` file. This will require a API key to a account that has API credits

## 1. Setup Delayed Job

### Add Delayed Job to Your Gemfile:
```ruby
gem 'delayed_job_active_record'
```

### Install the Gem:
```bash
bundle install
```

### Generate the Required Migration for Delayed Job and Migrate the Database:
```bash
rails generate delayed_job:active_record
rails db:migrate
```

### Start the Delayed Job Worker:
```bash
bin/delayed_job start
```

---

## 2. Create a Model for Job Responses

### Generate the Model:
```bash
rails generate model ChatGptJobResponse job_id:string state:string data:text error:text
```

### Migrate the Database:
```bash
rails db:migrate
```

### Add Validations to the Model:
Update `app/models/chat_gpt_job_response.rb`:
```ruby
class ChatGptJobResponse < ApplicationRecord
  validates :job_id, presence: true, uniqueness: true
end
```

---

## 3. Set Up the Background Job

### Generate the Job:
```bash
rails generate job chat_gpt_query
```

### Update the Job File:
Edit `app/jobs/chat_gpt_query_job.rb`:
```ruby
class ChatGptQueryJob < ApplicationJob
  queue_as :default

  def perform(prompt, job_id)
    # Initialize client with timeout and proper key param
    client = OpenAI::Client.new(
      access_token: ENV['OPENAI_API_KEY'], # Changed from api_key to access_token
      request_timeout: 30                   # Add timeout to prevent hanging
    )

    # Make the API request
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
        max_tokens: 1000                    # Add token limit for cost control
      }
    )

    # Process response with better error handling
    if response&.dig('choices', 0, 'message', 'content')
      content = response['choices'][0]['message']['content']
      ChatGptJobResponse.find_or_create_by(job_id: job_id).update(
        state: 'done',
        data: content,
        error: nil
      )
    else
      raise "Invalid API response: #{response}"
    end
  rescue OpenAI::Error => e
    # Specific OpenAI errors
    ChatGptJobResponse.find_or_create_by(job_id: job_id).update(
      state: 'error',
      error: "OpenAI Error: #{e.message}"
    )
  rescue => e
    # General errors
    ChatGptJobResponse.find_or_create_by(job_id: job_id).update(
      state: 'error',
      error: "System Error: #{e.message}"
    )
    raise e # Re-raise for job retries if configured
  end
end
```

---

## 4. Create the Controller

### Create the Controller File:
Create `app/controllers/api/chat_gpt_models_controller.rb`:
```ruby
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
```

---

## 5. Add Routes

### Define Routes for the API Endpoints:
Edit `config/routes.rb`:
```ruby
namespace :api do
  resources :chat_gpt_models, only: [] do
    collection do
      post :query
      get :job_status
    end
  end
end
```

---

## 6. Frontend Integration

### Query Endpoint (`/api/chat_gpt_models/query`):
#### Request:
```json
POST /api/chat_gpt_models/query
{
  "prompt": "Your question here"
}
```

#### Response:
```json
{
  "job_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

### Job Status Endpoint (`/api/chat_gpt_models/job_status`):
#### Request:
```json
GET /api/chat_gpt_models/job_status?job_id=123e4567-e89b-12d3-a456-426614174000
```

#### Responses:
While the job is still running:
```json
{
  "state": "pending"
}
```

When the job is done:
```json
{
  "state": "done",
  "data": "ChatGPT response here",
  "error": null
}
```

If an error occurred:
```json
{
  "state": "error",
  "data": null,
  "error": "Error message here"
}
```

---

## 7. Test the Setup

### Start the Rails Server:
```bash
rails server
```

### Use Tools to Test:
Use tools like Postman, Curl, or your frontend to send requests to the API endpoints.

### Monitor Background Jobs:
```bash
rails jobs:work
```

---

## 8. Optional: Monitor Delayed Job

### Add Monitoring Gem:
Add the `delayed_job_web` gem to your Gemfile:
```ruby
gem 'delayed_job_web'
```

### Mount the Web Interface:
Edit `config/routes.rb`:
```ruby
mount DelayedJobWeb => '/delayed_job'
```

### Access the Interface:
Visit [http://localhost:3000/delayed_job](http://localhost:3000/delayed_job) to monitor and manage your background jobs.
