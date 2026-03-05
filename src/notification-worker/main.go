// Package main implements a notification worker that polls the Alert API
// and simulates sending SMS/Email dispatches for new alerts.
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

// Alert represents an emergency alert from the Alert API.
type Alert struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Severity    string `json:"severity"`
	Location    string `json:"location"`
	Description string `json:"description"`
	CreatedAt   string `json:"created_at"`
}

func main() {
	alertAPIURL := getEnv("ALERT_API_URL", "http://alert-api-service:8000")
	pollInterval := getEnvDuration("POLL_INTERVAL", 10*time.Second)

	log.Printf("[notification-worker] Starting — polling %s every %s", alertAPIURL, pollInterval)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// Track already-processed alert IDs
	processed := make(map[string]bool)
	ticker := time.NewTicker(pollInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			log.Println("[notification-worker] Shutting down gracefully.")
			return
		case <-ticker.C:
			alerts, err := fetchAlerts(ctx, alertAPIURL+"/alerts")
			if err != nil {
				log.Printf("[notification-worker] Error fetching alerts: %v", err)
				continue
			}

			for _, a := range alerts {
				if processed[a.ID] {
					continue
				}
				dispatchNotifications(a)
				processed[a.ID] = true
			}
		}
	}
}

// fetchAlerts retrieves the current list of alerts from the Alert API.
func fetchAlerts(ctx context.Context, url string) ([]Alert, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, fmt.Errorf("create request: %w", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("http get: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read body: %w", err)
	}

	var alerts []Alert
	if err := json.Unmarshal(body, &alerts); err != nil {
		return nil, fmt.Errorf("json decode: %w", err)
	}

	return alerts, nil
}

// dispatchNotifications simulates sending SMS and Email for an alert.
func dispatchNotifications(a Alert) {
	log.Printf("[SMS]   Dispatching alert '%s' (severity=%s, location=%s) to emergency contacts",
		a.Title, a.Severity, a.Location)
	log.Printf("[EMAIL] Dispatching alert '%s' (severity=%s, location=%s) to subscriber list",
		a.Title, a.Severity, a.Location)
}

// getEnv returns the value of an environment variable or a default.
func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

// getEnvDuration parses a duration from an environment variable.
func getEnvDuration(key string, fallback time.Duration) time.Duration {
	if v := os.Getenv(key); v != "" {
		d, err := time.ParseDuration(v)
		if err == nil {
			return d
		}
		log.Printf("[notification-worker] Invalid duration for %s: %s, using default", key, v)
	}
	return fallback
}
