FROM python:3.11-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app
RUN addgroup --system app && adduser --system --ingroup app app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN chown -R app:app /app
USER app
EXPOSE 8005
ENV OTEL_SERVICE_NAME=analytics-service \
    OTEL_EXPORTER_OTLP_ENDPOINT=http://togglemaster-otel-collector.observability.svc.cluster.local:4318 \
    OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf \
    OTEL_TRACES_EXPORTER=otlp \
    OTEL_METRICS_EXPORTER=none \
    OTEL_LOGS_EXPORTER=none

CMD ["opentelemetry-instrument","gunicorn","--bind","0.0.0.0:8005","app:app"]
