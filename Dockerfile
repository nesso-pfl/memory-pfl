# Stage 1: Frontend build
FROM node:24-slim AS frontend-build
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app/frontend
COPY frontend/package.json ./
RUN npm install
ENV PATH="/app/frontend/node_modules/.bin:$PATH"
COPY frontend/spago.yaml frontend/spago.lock ./
RUN spago install
COPY frontend/ .
RUN npm run build

# Stage 2: Backend dependency build
FROM rust:1-bookworm AS backend-deps
WORKDIR /app/backend
COPY .cargo/ ../.cargo/
COPY backend/Cargo.toml backend/Cargo.lock ./
RUN mkdir src && echo "" > src/lib.rs && echo "fn main(){}" > src/main.rs && mkdir -p src/bin && echo "fn main(){}" > src/bin/mcp.rs
RUN --mount=type=secret,id=github_token \
    git config --global url."https://x-access-token:$(cat /run/secrets/github_token)@github.com/".insteadOf "ssh://git@github.com/" && \
    cargo build --release

# Stage 3: Backend build
FROM backend-deps AS backend-build
COPY backend/src ./src
COPY --from=frontend-build /app/frontend/dist/ ../frontend/dist/
RUN touch src/lib.rs src/main.rs src/bin/mcp.rs && cargo build --release

# Stage 4: Runtime
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends libpq5 ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=backend-build /app/backend/target/release/backend /usr/local/bin/backend
EXPOSE 1230
CMD ["backend"]
