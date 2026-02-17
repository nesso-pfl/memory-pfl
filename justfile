set dotenv-load

# Start frontend watch and backend watch in parallel
start:
    npm --prefix frontend run watch:purs &
    npm --prefix frontend run watch:css &
    cargo watch -C backend -x run

# Build production Docker image
build-image:
    docker build -t memory-pfl .
