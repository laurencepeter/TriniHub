# --- Build (Flutter) ---
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# 👇 Add Supabase build args (optional, if you use dart-define)
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY

COPY pubspec.* ./
RUN flutter config --enable-web && flutter pub get

COPY . .
RUN flutter build web --release \
  --no-tree-shake-icons \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}

# --- Serve (NGINX) ---
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx","-g","daemon off;"]
