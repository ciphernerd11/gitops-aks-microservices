# ── Stage 1: Build ──
FROM golang:1.22-alpine AS build
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /notification-worker .

# ── Stage 2: Runtime ──
FROM alpine:3.19
RUN apk --no-cache add ca-certificates && \
    adduser -D -g '' appuser
USER appuser
COPY --from=build /notification-worker /notification-worker

ENTRYPOINT ["/notification-worker"]
