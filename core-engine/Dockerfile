# ── Stage 1: Build ──────────────────────────────────────────────
FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod ./
COPY main.go ./
COPY pkg/ ./pkg

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o p2p-engine main.go

# ── Stage 2: Runner ──────────────────────────────────────────────
FROM alpine:3.19 AS runner

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY --from=builder /app/p2p-engine .

EXPOSE 9000
EXPOSE 8443

CMD ["./p2p-engine", "-port=9000"]
