package main

import (
	"net/http"
	"strconv"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total de requisicoes HTTP recebidas pelo auth-service.",
		},
		[]string{"method", "route", "status"},
	)

	httpRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Duracao das requisicoes HTTP do auth-service em segundos.",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "route", "status"},
	)
)

func init() {
	prometheus.MustRegister(httpRequestsTotal, httpRequestDuration)
}

type statusResponseWriter struct {
	http.ResponseWriter
	status      int
	wroteHeader bool
}

func (w *statusResponseWriter) WriteHeader(status int) {
	if w.wroteHeader {
		return
	}
	w.status = status
	w.wroteHeader = true
	w.ResponseWriter.WriteHeader(status)
}

func (w *statusResponseWriter) Write(body []byte) (int, error) {
	if !w.wroteHeader {
		w.WriteHeader(http.StatusOK)
	}
	return w.ResponseWriter.Write(body)
}

func metricsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Nao contabilizar o endpoint de scrape nas metricas da propria API.
		if r.URL.Path == "/metrics" {
			next.ServeHTTP(w, r)
			return
		}

		route := normalizedRoute(r.URL.Path)
		recorder := &statusResponseWriter{
			ResponseWriter: w,
			status:         http.StatusOK,
		}

		timer := prometheus.NewTimer(prometheus.ObserverFunc(func(seconds float64) {
			httpRequestDuration.WithLabelValues(
				r.Method,
				route,
				strconv.Itoa(recorder.status),
			).Observe(seconds)
		}))

		next.ServeHTTP(recorder, r)
		timer.ObserveDuration()

		httpRequestsTotal.WithLabelValues(
			r.Method,
			route,
			strconv.Itoa(recorder.status),
		).Inc()
	})
}

func normalizedRoute(path string) string {
	switch path {
	case "/health":
		return "/health"
	case "/validate":
		return "/validate"
	case "/admin/keys":
		return "/admin/keys"
	default:
		return "unmatched"
	}
}

func registerMetricsHandler(mux *http.ServeMux) {
	mux.Handle("/metrics", promhttp.Handler())
}
