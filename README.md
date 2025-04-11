
# Documentation: Ollama Model Query and Job Status

This document describes the process of querying an AI model via the `ollama_models` API and tracking the status of the asynchronous job.

---

## **1. Initial Request**

### **Endpoint**
**POST `/api/ollama_models/query`**


(An example of the request can be seen at app/views/pages/blank.html.erb under the script tag)
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
   ```
2. **After Completion**:
   ```json
   {
     "state": "done",
     "data": "<think></think>Hi! I'm DeepSeek-R1, an artificial intelligence assistant created by DeepSeek. ..."
   }
   ```

---

## **4. Final Job Completion**

### **Background Job Actions**
Once the job completes:
1. Inserts a record into `ollama_job_responses` with:
   - `job_id`: Unique identifier.
   - `prompt`: Original input.
   - `state`: `"done"`.
   - `data`: The model's response.
2. Commits the transaction, making the result accessible via `job_status`.

---

## **Summary of Key Components**

| Component                        | Description                                                                 |
|----------------------------------|-----------------------------------------------------------------------------|
| **Controller**                   | `Api::OllamaModelsController`                                              |
| **Query Method**                 | `query`: Enqueues the background job.                                       |
| **Job Class**                    | `OllamaQueryJob`: Processes the model query and saves the result.           |
| **Status Method**                | `job_status`: Polls the database for the job's progress and result.         |
| **Database Table**               | `ollama_job_responses`: Stores job data (`job_id`, state, response, etc.).  |
| **Polling**                      | Repeated calls to `job_status` track the job's progress.                    |

---

## **Flow Diagram**

1. **Client** sends `POST /api/ollama_models/query`.
2. **Server** enqueues `OllamaQueryJob`:
   - Generates a `job_id`.
   - Responds with `202 Accepted`.
3. **Job Worker** executes `OllamaQueryJob`:
   - Processes the prompt.
   - Saves the result to `ollama_job_responses`.
4. **Client** polls `GET /api/ollama_models/job_status?job_id=<job_id>`:
   - Returns `"pending"` until complete.
   - Eventually returns the model's result.

---
