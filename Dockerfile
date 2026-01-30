# syntax=docker/dockerfile:1.7

# Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .

ARG SUPABASE_URL=""
ARG SUPABASE_ANON_KEY=""

RUN flutter pub get
RUN --mount=type=secret,id=supabase_url,required=false \
  --mount=type=secret,id=supabase_anon_key,required=false \
  sh -c ' \
    if [ -f /run/secrets/supabase_url ]; then \
      SUPABASE_URL="$(cat /run/secrets/supabase_url)"; \
    fi; \
    if [ -f /run/secrets/supabase_anon_key ]; then \
      SUPABASE_ANON_KEY="$(cat /run/secrets/supabase_anon_key)"; \
    fi; \
    flutter build web --release \
      --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
      --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"; \
  '

# Serve stage
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
