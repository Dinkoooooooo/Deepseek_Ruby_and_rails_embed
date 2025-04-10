# Documentation: Ollama Model Query and Job Status

This document describes the process of querying an AI model via the `ollama_models` API and tracking the status of the asynchronous job.

---

## **1. Initial Request**

### **Endpoint**
**POST `/api/ollama_models/query`**

### **Description**
A client sends a request to the `query` endpoint with a prompt, such as `"Are you a robot"`. This triggers the following steps:

### **Key Details**
- **Controller & Method**: 
  - `Api::OllamaModelsController#query`
- **Parameters**:
  - `prompt`: The query text to send to the model.
- **Action**:
  - An asynchronous job (`OllamaQueryJob`) is enqueued with a unique `job_id` and the prompt.

---

## **2. Job Processing**

### **Background Job**
**`OllamaQueryJob`**

### **Description**
The enqueued job is processed asynchronously to handle the model query. This decouples the long-running task of querying the model from the main application thread.

### **Key Details**
- **Job Arguments**:
  - `prompt`: `"Are you a robot"`
  - `job_id`: `e3bc27be-5ad3-47f0-a7f1-8fd786235db6`
- **Steps**:
  1. Sends the `prompt` to the model.
  2. Waits for the model to respond with:
     - **`response`**: The model's output.
     - **`done`**: A flag indicating the task is complete.
  3. Saves the result (`response`, `state`, etc.) in the `ollama_job_responses` table.

---

## **3. Checking Job Status**

### **Endpoint**
**GET `/api/ollama_models/job_status?job_id=<job_id>`**

### **Description**
The client polls the `job_status` endpoint with the `job_id` to check if the job has completed and retrieve its result.

### **Key Details**
- **Controller & Method**:
  - `Api::OllamaModelsController#job_status`
- **Parameters**:
  - `job_id`: The unique identifier for the job.
- **Actions**:
  1. Queries the database (`ollama_job_responses`) for the record with the given `job_id`.
  2. Returns:
     - If found: The job's current state and result.
     - If not found: `"pending"` state until the job completes.

### **Example Responses**
1. **Before Completion**:
   ```json
   {
     "state": "pending"
   }
