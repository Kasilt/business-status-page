#!/bin/bash

# Configuration Supabase (extraite du code source main.dart)
SUPABASE_URL="https://wezpklpmaqrufoxczaeg.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlenBrbHBtYXFydWZveGN6YWVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NjU2NTcsImV4cCI6MjA4NjI0MTY1N30.Y4Yqca1SQDVlP5Yo67yrtOv7a1tMQbSJEiS61lL40KE"

echo "Test de l'API Supabase pour la table journey_maps..."

# Tentative de lecture de la table journey_maps
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \\
  -X GET "${SUPABASE_URL}/rest/v1/journey_maps?select=*" \\
  -H "apikey: ${SUPABASE_KEY}" \\
  -H "Authorization: Bearer ${SUPABASE_KEY}")

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "✅ OK: La table 'journey_maps' existe (HTTP $HTTP_STATUS)."
  echo "La migration PostgreSQL a déjà été exécutée !"
else
  echo "❌ ERREUR: La table 'journey_maps' est introuvable (HTTP $HTTP_STATUS)."
  echo "La migration PostgreSQL n'a PAS encore été exécutée."
fi

echo "Test de l'API Supabase pour la table cis..."

HTTP_STATUS_CIS=$(curl -s -o /dev/null -w "%{http_code}" \\
  -X GET "${SUPABASE_URL}/rest/v1/cis?select=*" \\
  -H "apikey: ${SUPABASE_KEY}" \\
  -H "Authorization: Bearer ${SUPABASE_KEY}")

echo "Statut requête cis: $HTTP_STATUS_CIS"

# Afficher un document CIS pour vérifier le format de l'ID (UUID vs TEXT)
curl -s -X GET "${SUPABASE_URL}/rest/v1/cis?select=*&limit=1" \\
  -H "apikey: ${SUPABASE_KEY}" \\
  -H "Authorization: Bearer ${SUPABASE_KEY}" | grep -o '"id":"[^"]*"'
