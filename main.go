package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os/exec"

	"github.com/rs/cors"
)

// Question represents a single quiz question for the frontend.
type Question struct {
	ID      string   `json:"id"`
	Text    string   `json:"text"`
	Options []string `json:"options"`
	Answer  string   `json:"answer"`
}

// GumloopRequestBody is the request body for the Gumloop API.
type GumloopRequestBody struct {
	Topic string `json:"topic"`
}

func main() {
	http.HandleFunc("/success", successHandler)
	http.HandleFunc("/generate-questions", generateQuestionsHandler)

	c := cors.Default()
	handler := c.Handler(http.DefaultServeMux)

	log.Println("Server starting on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", handler))
}

func successHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	response := map[string]string{"message": "Server is running successfully!"}
	json.NewEncoder(w).Encode(response)
}

func generateQuestionsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var requestBody GumloopRequestBody
	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if requestBody.Topic == "" {
		http.Error(w, "Topic is required", http.StatusBadRequest)
		return
	}

	questions, err := generateQuestionsFromPython(requestBody.Topic)
	if err != nil {
		log.Printf("Error generating questions from Python script: %v", err)
		http.Error(w, "Failed to generate questions", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(questions)
}

// generateQuestionsFromPython executes the Python script to generate questions.
// The Python script is now responsible for all parsing and transformation.
func generateQuestionsFromPython(topic string) ([]Question, error) {
	pythonPath := "/usr/bin/python3"
	scriptPath := "generate_questions.py"

	cmd := exec.Command(pythonPath, scriptPath, topic)

	output, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("failed to execute python script: %w, output: %s", err, string(output))
	}

	var questions []Question
	if err := json.Unmarshal(output, &questions); err != nil {
		return nil, fmt.Errorf("failed to unmarshal python script output: %w, output: %s", err, string(output))
	}

	return questions, nil
}
