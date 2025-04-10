#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <ADMIN_USERNAME> <ADMIN_PASSWORD> [GRAFANA_URL] [NUM_ORGS]"
  exit 1
fi

ADMIN_USER="$1"
ADMIN_PASS="$2"
GRAFANA_URL="${3:-http://localhost:3000}"
NUM_ORGS="${4:-100}"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "❗ 'jq' is required but not installed. Install it with: sudo apt install jq"
  exit 1
fi

for i in $(seq 1 $NUM_ORGS); do
  ORG_NAME=$(printf "Org%03d" $i)
  USER_NAME="user$i"
  PASSWORD="pwd$i"
  EMAIL="user$i@example.com"

  echo "🔧 Creating organization: $ORG_NAME"
  # Check if org already exists
  ORG_ID=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" "$GRAFANA_URL/api/orgs/name/$ORG_NAME" | jq -r .id)
  if [[ "$ORG_ID" != "null" ]]; then
    printf "\rℹ️  Org already exists: $ORG_NAME (ID $ORG_ID)\n"
  else
    ORG_ID=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" \
        -H "Content-Type: application/json" \
        -X POST "$GRAFANA_URL/api/orgs" \
        -d "{\"name\":\"$ORG_NAME\"}" | jq -r .orgId)

    if [[ "$ORG_ID" == "null" ]]; then
        echo "❌ Failed to create org $ORG_NAME"
        continue
    fi

    echo "✅ Created org '$ORG_NAME' with ID $ORG_ID"
  fi
  
  # Check if user already exists
  USER_ID=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" \
   "$GRAFANA_URL/api/orgs/$ORG_ID/users" | jq -r ".[] | select(.login == \"$USER_NAME\") | .userId")

  if [[ "$USER_ID" == "" ]]; then
    echo "👤 Creating user: $USER_NAME"
    USER_ID=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" \
    -H "Content-Type: application/json" \
    -X POST "$GRAFANA_URL/api/admin/users" \
    -d "{
          \"name\": \"$USER_NAME\",
          \"email\": \"$EMAIL\",
          \"login\": \"$USER_NAME\",
          \"password\": \"$PASSWORD\"
        }" | jq -r ".id")
  fi
  
  curl -s -u "$ADMIN_USER:$ADMIN_PASS" \
    -H "Content-Type: application/json" \
    -X POST "$GRAFANA_URL/api/orgs/$ORG_ID/users" \
    -d "{
          \"loginOrEmail\": \"$USER_NAME\",
          \"role\": \"Admin\"
        }" > /dev/null

  curl -s -u "$ADMIN_USER:$ADMIN_PASS" \
      -H "Content-Type: application/json" \
      -X DELETE "$GRAFANA_URL/api/orgs/1/users/$USER_ID" > /dev/null

  echo "✔️ User '$USER_NAME ($USER_ID)' added to '$ORG_NAME'"
done


#for i in $(seq 200 400); do
# curl "http://localhost:3000/api/orgs/$i" -X DELETE -H "Content-Type: application/json" -u "$ADMIN_USER:$ADMIN_PASS"
# curl "http://localhost:3000/api/admin/users/$i" -X DELETE -H "Content-Type: application/json" -u "$ADMIN_USER:$ADMIN_PASS"
#done