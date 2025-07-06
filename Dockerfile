FROM golang:1.20-slim AS go_builder

WORKDIR /app/go

COPY backend/go.mod backend/go.sum ./
RUN go mod download

COPY backend/main.go ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o ranquiz-backend main.go

FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=go_builder /app/go/ranquiz-backend ./ranquiz-backend

COPY backend/requirements.txt ./

RUN python3 -m venv venv
RUN ./venv/bin/pip install --no-cache-dir -r requirements.txt

COPY backend/generate_questions.py ./generate_questions.py

RUN chmod +x ranquiz-backend

EXPOSE 8080

CMD ["./ranquiz-backend"]

