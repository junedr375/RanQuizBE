package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
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

	c := cors.New(cors.Options{
		AllowedOrigins: []string{
			"https://enchanting-truffle-462314.netlify.app",
			"http://localhost:3000",
		},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	})
	handler := c.Handler(http.DefaultServeMux)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080" // Default port if not specified
	}
	log.Printf("Server starting on port %s...", port)
	log.Fatal(http.ListenAndServe(":"+port, handler))
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
	pythonPath := "python3"
	scriptPath := "/app/generate_questions.py"

	cmd := exec.Command(pythonPath, scriptPath, topic)

	output, err := cmd.CombinedOutput()
	if err != nil {
		// Capture stderr separately for better error reporting
		stderrOutput := ""
		if exitErr, ok := err.(*exec.ExitError); ok {
			stderrOutput = string(exitErr.Stderr)
		}
		return nil, fmt.Errorf("failed to execute python script: %w, stdout: %s, stderr: %s", err, string(output), stderrOutput)
	}

	var questions []Question
	if err := json.Unmarshal(output, &questions); err != nil {
		return nil, fmt.Errorf("failed to unmarshal python script output: %w, output: %s", err, string(output))
	}

	return questions, nil
}
