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

# Debugging: List contents after apt-get install
RUN echo "--- Contents of /app after apt-get install ---" && ls -la /app

COPY --from=go_builder /app/go/ranquiz-backend ./ranquiz-backend

# Debugging: List contents after copying Go binary
RUN echo "--- Contents of /app after copying Go binary ---" && ls -la /app

COPY backend/requirements.txt ./

# Debugging: List contents after copying requirements.txt
RUN echo "--- Contents of /app after copying requirements.txt ---" && ls -la /app

RUN python3 -m venv venv

# Debugging: List contents after creating venv
RUN echo "--- Contents of /app after creating venv ---" && ls -la /app

RUN ./venv/bin/pip install --no-cache-dir -r requirements.txt

# Debugging: List contents after pip install
RUN echo "--- Contents of /app after pip install ---" && ls -la /app

COPY backend/generate_questions.py ./generate_questions.py

# Debugging: List contents after copying Python script
RUN echo "--- Contents of /app after copying Python script ---" && ls -la /app

RUN chmod +x ranquiz-backend

EXPOSE 8080

CMD ["./ranquiz-backend"]