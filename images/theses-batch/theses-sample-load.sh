#!/bin/bash

echo "-> Suppression de l'eventuel ancien index theses-sample dans elasticsearch"
curl -s -k --request DELETE \
  -u elastic:thesessecret2 \
  --url 'https://theses-elasticsearch-es01:9200/theses-sample?pretty=true'

echo "-> Création du mapping de l'index theses-sample dans elasticsearch"
cat theses-sample-mapping.json | curl -s -k --request PUT \
  -u elastic:thesessecret2 \
  --url 'https://theses-elasticsearch-es01:9200/theses-sample?pretty=true' \
  --header 'Content-Type: application/json' \
  --data-binary @-

echo "-> Chargement des documents dans l'index theses-sample d'elasticsearch"
cat theses-sample-data.json | jq -c '.[]' | curl -s -k --request POST \
  -u elastic:thesessecret2 \
  --url 'https://theses-elasticsearch-es01:9200/_bulk/?pretty=true' \
  --header 'Content-Type: application/x-ndjson' \
  --data-binary @-
