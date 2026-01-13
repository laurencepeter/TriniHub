# syntax=docker/dockerfile:1.7

# Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .

RUN flutter pub get
RUN --mount=type=secret,id=supabase_url \
  --mount=type=secret,id=supabase_anon_key \
  SUPABASE_URL="$(cat /run/secrets/supabase_url)" \
  SUPABASE_ANON_KEY="$(cat /run/secrets/supabase_anon_key)" \
  flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

# Serve stage
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
