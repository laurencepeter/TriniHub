# syntax=docker/dockerfile:1.7

# Build stage
#
# Pin the Flutter version instead of tracking the floating `:stable` tag.
# The project targets Dart `^3.7.2` (pubspec.yaml), which corresponds to
# Flutter 3.29.3. Newer `stable` releases (3.32+) run an additional
# "Wasm dry run" compilation on every `flutter build web`, which roughly
# doubles the peak memory of the release compile (~1 GB -> ~2 GB) and was
# OOM-killing the deploy build container during "Compiling lib/main.dart
# for the Web...". Pinning keeps builds reproducible and within memory.
FROM ghcr.io/cirruslabs/flutter:3.29.3 AS build
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
# SPA fallback config so deep links / refreshes / auth redirects don't 404.
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
