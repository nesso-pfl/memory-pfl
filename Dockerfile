# Stage 1: Frontend build
FROM node:24-slim AS frontend-build
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*
WORKDIR /app/frontend
COPY frontend/package.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

# Stage 2: Backend build
FROM rust:1-bookworm AS backend-build
RUN apt-get update && apt-get install -y --no-install-recommends openssh-client && rm -rf /var/lib/apt/lists/*
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
WORKDIR /app/backend
COPY .cargo/ ../.cargo/
COPY backend/ .
COPY --from=frontend-build /app/frontend/dist/ ../frontend/dist/
RUN --mount=type=ssh cargo build --release

# Stage 3: Runtime
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends libpq5 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=backend-build /app/backend/target/release/backend /usr/local/bin/backend
EXPOSE 1230
CMD ["backend"]
