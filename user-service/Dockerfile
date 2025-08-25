# ---- Base Stage ----
# Start with a standard Go image to build the application
FROM golang:1.21-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Go module files and download dependencies
# This caches the dependencies for faster builds
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the application source code
COPY . .

# Build the Go application, creating a static binary.
# CGO_ENABLED=0 is important for creating a truly static binary
# that can run in a minimal container.
RUN CGO_ENABLED=0 go build -o /user-service ./cmd

# ---- Final Stage ----
# Start from a minimal "scratch" image, which is completely empty.
# This makes the final container extremely small and secure.
FROM scratch

# Set the working directory
WORKDIR /

# Copy the compiled binary from the 'builder' stage
COPY --from=builder /user-service /user-service

# Expose the port that the application will listen on
EXPOSE 8000

# Set the entrypoint for the container. This is the command that will
# be run when the container starts.
ENTRYPOINT ["/user-service"]
