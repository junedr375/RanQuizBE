# Use an official Go runtime as a parent image
FROM golang:1.20-slim

# Set the working directory inside the container
WORKDIR /app

# Install Python, pip, and venv
RUN apt-get update && apt-get install -y python3 python3-pip python3-venv

# Copy Go module and dependency files
COPY go.mod go.sum ./
# Download Go dependencies
RUN go mod download

# Copy Python dependency file
COPY requirements.txt .
# Create a virtual environment and install Python dependencies
RUN python3 -m venv venv
# Debugging: List the contents of the /app directory to verify venv creation
RUN ls -la /app
RUN ./venv/bin/pip install -r requirements.txt

# Copy the rest of the application's source code
COPY . .

# Build the Go application
RUN go build -o ranquiz-backend main.go

# Make the binary executable
RUN chmod +x ranquiz-backend

# Expose port 8080 to the outside world
EXPOSE 8080

# Command to run the executable
CMD ["./ranquiz-backend"]
