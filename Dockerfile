FROM golang:1.20-slim AS go_builder

WORKDIR /app

COPY backend/go.mod backend/go.sum ./go/
WORKDIR /app/go
RUN go mod download

COPY backend/main.go backend/generate_questions.py ./go/
WORKDIR /app/go
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o ranquiz-backend main.go

FROM python:3.10-slim AS python_builder

WORKDIR /app

COPY backend/requirements.txt ./python/
WORKDIR /app/python
RUN python3 -m venv venv
RUN ./venv/bin/pip install --no-cache-dir -r requirements.txt

FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=go_builder /app/go/ranquiz-backend ./ranquiz-backend
COPY --from=python_builder /app/python/venv ./venv
COPY backend/generate_questions.py ./generate_questions.py

RUN chmod +x ranquiz-backend

EXPOSE 8080

CMD ["./ranquiz-backend"]