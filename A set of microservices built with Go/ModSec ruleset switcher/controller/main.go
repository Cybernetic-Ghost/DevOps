package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

func healthCheck(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, `{"status":"ok","version":"1.0"}`)
}

func modSecurityHandler(w http.ResponseWriter, r *http.Request) {
	apiKey := r.Header.Get("X-API-Key")
	validKey := os.Getenv("API_KEY")

	if apiKey != validKey {
		http.Error(w, "Forbidden", http.StatusForbidden)
		return
	}

	fmt.Fprintf(w, `{"current_mode":"DetectionOnly","timestamp":"%s"}`, time.Now().Format(time.RFC3339))
}

func main() {
	http.HandleFunc("/health", healthCheck)
	http.HandleFunc("/modsecurity/mode", modSecurityHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	log.Printf("Starting controller on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
