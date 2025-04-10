# app/services/ollama_model_service.rb
require 'faraday'

class OllamaModelService
  OLLAMA_HOST = '127.0.0.1'
  OLLAMA_PORT = 11434
  MODEL_NAME = "deepseek-r1:1.5b-qwen-distill-q4_K_M"

  def self.query(prompt)
    data = { prompt: prompt, model: MODEL_NAME, stream: false }.to_json
    url = "http://#{OLLAMA_HOST}:#{OLLAMA_PORT}/api/generate"

    begin
      response = Faraday.post(url, data, 'Content-Type' => 'application/json')

      Rails.logger.debug("Response Body: #{response.body}")

      if response.success?
        JSON.parse(response.body)['response']
      else
        raise "Error querying model: #{response.body}"
      end
    rescue StandardError => e
      Rails.logger.error("Error querying Ollama model: #{e.message}")
      raise e
    end
  end
end
