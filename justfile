set dotenv-load

# Start frontend watch and backend watch in parallel
start:
    cargo watch -w frontend/src -s 'npm --prefix frontend run build:purs' & npm --prefix frontend run watch:css & cargo watch -C backend -x run

# Build production Docker image
build-image:
    docker build -t memory-pfl .
