#!/bin/bash
# Lee el .env y lanza flutter con --dart-define por cada variable
# Uso: bash scripts/run_with_env.sh run
#      bash scripts/run_with_env.sh build apk

ENV_FILE="$(dirname "$0")/../.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ No se encontró .env. Copia .env.example como .env y configura tus valores."
  exit 1
fi

DART_DEFINES=""
while IFS= read -r line || [ -n "$line" ]; do
  # Ignorar comentarios y líneas vacías
  [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
  DART_DEFINES="$DART_DEFINES --dart-define=$line"
done < "$ENV_FILE"

echo "🚀 Ejecutando: flutter $@ $DART_DEFINES"
flutter "$@" $DART_DEFINES
