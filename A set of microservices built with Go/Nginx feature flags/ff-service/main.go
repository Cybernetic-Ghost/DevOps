package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	_ "github.com/lib/pq"
)

type Info struct {
	Host  string      `json:"host"`
	HTTP  interface{} `json:"http"`
	Time  string      `json:"time"`
	DBOK  bool        `json:"db_ok"`
	DBErr string      `json:"db_err,omitempty"`
}

func main() {
	r := chi.NewRouter()

	// ===== HTTP metrics =====
	reqCounter := promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total HTTP requests",
		},
		[]string{"path", "method", "status"},
	)
	reqDuration := promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Request duration in seconds",
			Buckets: prometheus.DefBuckets, // 0.005..10s
		},
		[]string{"path", "method"},
	)
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			start := time.Now()
			ww := &respWriter{ResponseWriter: w, status: 200}
			next.ServeHTTP(ww, req)
			path := req.URL.Path
			method := req.Method
			reqCounter.WithLabelValues(path, method, fmt.Sprintf("%d", ww.status)).Inc()
			reqDuration.WithLabelValues(path, method).Observe(time.Since(start).Seconds())
		})
	})

	// Метрики Prometheus
	r.Handle("/metrics", promhttp.Handler())

	// Healthz (без БД)
	r.Get("/healthz", func(w http.ResponseWriter, req *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

	// /dbz — проверка коннекта к БД (Ping)
	r.Get("/dbz", func(w http.ResponseWriter, req *http.Request) {
		dsn := os.Getenv("DB_DSN")
		dbOK := false
		var dbErr string

		if dsn == "" {
			dbErr = "DB_DSN is empty"
		} else {
			db, err := sql.Open("postgres", dsn)
			if err != nil {
				dbErr = fmt.Sprintf("open: %v", err)
			} else {
				defer db.Close()
				db.SetConnMaxLifetime(5 * time.Minute)
				db.SetMaxOpenConns(2)
				db.SetMaxIdleConns(1)

				if err := db.Ping(); err != nil {
					dbErr = fmt.Sprintf("ping: %v", err)
				} else {
					dbOK = true
				}
			}
		}

		resp := Info{
			Host: req.Host,
			HTTP: map[string]interface{}{
				"method": req.Method,
				"url":    req.URL.String(),
			},
			Time:  time.Now().Format(time.RFC3339),
			DBOK:  dbOK,
			DBErr: dbErr,
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(resp)
	})

	// Корень
	r.Get("/", func(w http.ResponseWriter, req *http.Request) {
		fmt.Fprintln(w, "ff-service alive")
	})

	addr := ":8080"
	log.Printf("listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, r))
}

// tiny wrapper to capture status code for metrics
type respWriter struct {
	http.ResponseWriter
	status int
}

func (w *respWriter) WriteHeader(code int) {
	w.status = code
	w.ResponseWriter.WriteHeader(code)
}
