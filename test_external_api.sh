#!/bin/bash

# Configuration
SUPABASE_URL="https://wezpklpmaqrufoxczaeg.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlenBrbHBtYXFydWZveGN6YWVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NjU2NTcsImV4cCI6MjA4NjI0MTY1N30.Y4Yqca1SQDVlP5Yo67yrtOv7a1tMQbSJEiS61lL40KE"

# 1. Obtenir un ID de CI valide pour y lier un événement
echo "1. Obtention d'un CI affecté (API Gateway)..."
APP_CHECKOUT_ID="tech-api-01"

if [ -z "$APP_CHECKOUT_ID" ]; then
    echo "❌ Erreur: Ajout d'événement impossible. CI 'API Gateway' non trouvé."
    exit 1
fi
echo "🔹 CI API Gateway ID: $APP_CHECKOUT_ID"

# 2. Créer l'événement (Incident)
echo "2. Création de l'événement (Incident via un outil tiers - Datadog/Nagios)"
CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
RANDOM_REF="INC-$RANDOM"

EVENT_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/events" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"title\": \"Alerte Automatique: Lenteur Paiement\",
    \"description\": \"Timeout API Paiement > 5s remonté par la sonde externe.\",
    \"status\": \"degraded\",
    \"affected_ci_id\": \"$APP_CHECKOUT_ID\",
    \"start_time\": \"$CURRENT_DATE\",
    \"stage\": \"detection\",
    \"impacted_bus\": [\"WEB\"],
    \"external_ref\": \"$RANDOM_REF\",
    \"external_link\": \"https://monitoring.company.com/alerts/$RANDOM_REF\"
  }")

EVENT_ID=$(echo $EVENT_RESPONSE | grep -o -E '"id":"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"' | head -n 1 | cut -d '"' -f 4)

if [ -z "$EVENT_ID" ]; then
    echo "❌ Erreur de création de l'événement."
    echo "Réponse Supabase: $EVENT_RESPONSE"
    exit 1
fi
echo "✅ Événement créé avec succès sous l'ID: $EVENT_ID (Ref externe: $RANDOM_REF)"

# 3. Créer un message (Event_post) dans la Timeline
echo "3. Ajout d'une entrée dans la Timeline de l'incident..."
POST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$SUPABASE_URL/rest/v1/event_posts" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"event_id\": \"$EVENT_ID\",
    \"message\": \"Investigation en cours. Analyse des métriques réseau par le robot d'astreinte.\",
    \"author\": \"Monitoring Bot\",
    \"type\": \"investigation\"
  }")

if [ "$POST_RESPONSE" == "201" ]; then
    echo "✅ Message ajouté à la Timeline."
else
    echo "❌ Échec de l'ajout du post. Code HTTP: $POST_RESPONSE"
fi

echo "---🚀 TEST TERMINÉ 🚀 ---"
echo "Ouvrez l'application Flutter pour voir le nouvel incident '$RANDOM_REF' apparaître."
