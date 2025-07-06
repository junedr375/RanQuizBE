FROM golang:1.22-bookworm AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o ranquiz-backend ./main.go

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/ranquiz-backend ./ranquiz-backend

COPY generate_questions.py ./generate_questions.py
COPY requirements.txt ./requirements.txt

RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 8080

CMD ["./ranquiz-backend"]

