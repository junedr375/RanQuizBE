FROM golang:1.24-bookworm AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o ranquiz-backend ./main.go

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends     python3     python3-pip     python3-venv     && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/ranquiz-backend ./ranquiz-backend

RUN ls -la .
COPY generate_questions.py ./generate_questions.py
COPY requirements.txt ./requirements.txt

RUN ls -la /app

RUN python3 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

RUN /app/venv/bin/pip install --no-cache-dir -r requirements.txt
RUN echo "Python packages in venv:" && /app/venv/bin/pip list

EXPOSE 8080

CMD ["./ranquiz-backend"]

