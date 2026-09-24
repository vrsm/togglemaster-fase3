FROM golang:1.21-alpine AS builder
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -mod=mod -trimpath -ldflags="-s -w" -o /out/evaluation-service .

FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /app
COPY --from=builder /out/evaluation-service /app/evaluation-service
EXPOSE 8004
USER nonroot:nonroot
ENTRYPOINT ["/app/evaluation-service"]
