# FAQ theses-docker

## Comment régler vm.max_map_count pour Elasticsearch ?

Le réglage de ``vm.max_map_count`` est nécessaire pour que [ElasticSearch puisse fonctionner](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html) 

Sans ce réglage vous obtiendrez l'erreur suivante au démarrage :
```
theses-elasticsearch-es01        | bootstrap check failure [1] of [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
theses-elasticsearch-es01        | ERROR: Elasticsearch did not exit normally - check the logs at /usr/share/elasticsearch/logs/theses-cluster.log
```


### Régler vm.max_map_count sur un serveur linux classique

```
  echo "vm.max_map_count = 262144" > /etc/sysctl.d/99-elasticsearch.conf
  sysctl -w vm.max_map_count=262144
```

### Régler vm.max_map_count dans un environnement WSL2 sous Windows 10

Pré-requis : WSL2 + Docker Desktop doivent être installés sur votre machine.

1) lancer un terminal PowerShell  
   ![image](https://user-images.githubusercontent.com/328244/178310894-f93c76bc-a85f-45e9-97ab-d5256bc3166b.png)

2) Editer le profil PowerShell par défaut de l'utilisateur courant, tapez :
   ```
   notepad $PROFILE
   ```  
3) Entrez la commande suivante dans le profil PowerShell et sauver puis fermer le fichier :
   ```
   wsl -d docker-desktop sh -c "sysctl -w vm.max_map_count=262147"
   ```  
   ![image](https://user-images.githubusercontent.com/328244/178311027-9f83e6b1-d48e-4442-94c3-7724e2974e45.png)
   
4) Lancer un nouveau terminal PowerSell, vous devriez voir s'afficher "vm.max_map_count = 262147" au démarrage du terminal ce qui montre que la commande a été executée.  
   ![image](https://user-images.githubusercontent.com/328244/178311186-4b2422b2-ebd6-4b20-98c7-6c42250cdb34.png)

5) Lancer une distribution Linux WSL et constatez que la valeur est bien réglée en tapant :
   ```
   sysctl vm.max_map_count
   ```
   ![image](https://user-images.githubusercontent.com/328244/178311271-c160df19-1af3-41ce-bc7a-681af9e81185.png)

## Comment générer mes propres certificats pour la fédération d'identités en prod ?

Tout est expliqué ici : https://github.com/abes-esr/docker-shibboleth-renater-sp#configuration-en-prod

En résumé pour ``theses-rp``, il faut faire ceci :
1) se rendre sur la machine de prod et rentrer dans le répertoire des certificats :
   ```bash
   cd /opt/pod/theses-docker/volumes/theses-rp/shibboleth/ssl/
   ```
2) générer des certificats auto-signées dédiés pour la prod :
   ```bash
   openssl genrsa -out server-prod.key 2048
   openssl req -new -key server-prod.key -out server-prod.csr
   openssl x509 -req -days 7300 -in server-prod.csr -signkey server-prod.key -out server-prod.crt
   ```
3) positionner les variables suivante dans le fichier ``.env`` :
   ```env
   RENATER_SP_CERTIFICATE_CRT=ssl/server-prod.crt
   RENATER_SP_CERTIFICATE_KEY=ssl/server-prod.key
   ```
4) enregistrer theses-rp de prod comme service provider dans la [fédération d'identités Education-Recherche de prod](https://registry.federation.renater.fr/?action=get_all)

Attention : ne jamais commiter ces certificats (surtout le fichier ``server-prod.key`` qui est un secret) sur le github !

## Comment configurer la fédération d'identités de theses.fr en local ?

Si vous désirez tester la fédération d'identités en local, vous devez configurer votre environnement local comme expliqué dans la FAQ.

Tout d'abord, positionnez au niveau de votre fichier ``.env`` le port HTTPS par défaut (443) comme port d'écoute de ``theses-rp`` (c'est le point d'entrée de tout votre déploiement local theses.fr) :
```env
THESES_RP_HTTPS_PORT=443
```

Ensuite vous devez faire pointer le nom de domaine ``v2-local.theses.fr`` sur votre IP local, pour cela voici une astuce en modifiant votre fichier ``hosts`` :
```
# ajouter ces lignes 
# dans votre fichier /etc/hosts (sous linux - besoin de droits admin)
# ou dans C:\Windows\System32\drivers\etc\hosts (sous windows - besoin de droits admin)
127.0.0.1 v2-local.theses.fr
```

Une fois ces modifications réalisées, vous pourrez accéder à votre theses.fr local sur l'URL suivante (en acceptant au passage l'erreur de sécurité liée au certificat auto-signé) : https://v2-local.theses.fr

## Comment activer le monitoring du cluster elasticsearch ?

Pour pouvoir suivre l'état du cluster ElasticSearch depuis le Kibana sans installer les outils préconisés du type MetricBeats (qui nécessite une architecture plus complexe), voici comme procéder :

Se rendre dans le kibana et dans l'onglet dev-tools, exemple https://v2-dev.theses.fr/kibana/, puis taper ceci :
```json
PUT _cluster/settings
{
  "persistent": {
    "xpack.monitoring.collection.enabled": true
  }
}
```

Pour consulter l'état de cette variable :
```json
GET _cluster/settings
```

Ensuite rendez vous dans l'onglet "Stack monitoring de kibana", par exemple :  
https://v2-dev.theses.fr/kibana/app/monitoring#/elasticsearch

On obtiendra alors ce type d'écran :  
TODO placer une copie d'écran


## Comment ajouter un noeud au cluster elasticsearch de theses.fr ?

Si vous devez ajouter un Nieme noeud au cluster elasticsearch de theses.fr et que ce Nieme noeud n'est pas encore géré dans la phase de setupcerts, alors vous devez procéder comme ceci :

1) Stopper tous les noeuds :
   ```bash
   # noeud 1
   cd /opt/pod/theses-docker/
   docker-compose stop theses-elasticsearch

   # noeud 2, 3, 4 ...
   cd /opt/theses-es-cluster-docker/
   docker-compose stop theses-elasticsearch
   ```
2) Modifiez la configuration du conteneur ``theses-elastisearch-setupcerts`` pour lui ajouter la prise en compte d'un nouveau noeud, exemple sur le noeud 4 : https://github.com/abes-esr/theses-docker/blob/d770ecb4b029d56e23f6f0968327d25489d9bdc2/docker-compose.yml#L210-L215
3) Ensuite placez vous sur le noeud numéro 1 et supprimez les certificats d'elasticsearch de manière à pouvoir les régénérer à l'aide du conteneur ``theses-elastisearch-setupcerts`` (cf étape suivante) car le fait d'ajouter un noeud signifie qu'il faut lui dédier un certificat :
   ```bash
   cd /opt/pod/theses-docker
   docker run --rm -it -v $(pwd)/volumes/theses-elasticsearch-setupcerts/:/tmp/ debian:bullseye bash -c 'rm -rf /tmp/*.zip'
   ```
4) Détruire et recréer le conteneur ``theses-elastisearch-setupcerts`` de manière à regénérer les certificats (fichiers ``ca.zip`` et ``certs.zip``) :
   ```bash
   cd /opt/pod/theses-docker
   docker-compose rm -f theses-elasticsearch-setupcerts
   docker-composeup -d theses-elasticsearch-setupcerts
   # on regarde les logs pour vérifier que le certificat du nouveau noeud est bien généré
   docker-compose logs --tail=100 theses-elasticsearch-setupcerts
   ```
5) Redéployez finalement les fichiers ``ca.zip`` et ``certs.zip`` sur les N noeuds en suivant la procédure d'installation d'un nouveau noeud: https://github.com/abes-esr/theses-es-cluster-docker/#installation--serveurs-2--3--noeuds-2--3 


## Comment tester les performances du cluster elasticsearch

Avec l'outil siege on peut simuler un grand nombre de requêtes simultanées. Voici un exemple de benchmark des perf du cluster elasticsearch en appelant directement l'API d'ES sans passer par l'API Java de theses.fr 

Constituer le fichier des URL à appeler (dans cette exemple on va appeler les 4 noeuds du cluster à tours de rôle) :
```
$ cat siege-urls.txt
https://diplotaxis1-prod.v102.abes.fr:10302/theses_test/_search POST {"query":{"query_string":{"default_operator": "and","fields": ["resumes.*^30","titres.*^30","nnt^15","discipline^15","sujetsRameauPpn^15","sujetsRameauLibelle^15","sujets^15","auteursNP^12","directeursNP^2","ecolesDoctoralesN^5","etabSoutenanceN^5","oaiSets^5","etabsCotutelleN^1","membresJuryNP^1","partenairesRechercheN^1","presidentJuryNP^1","rapporteurs^1"],"query": "science","quote_field_suffix": ".exact"}}}
https://diplotaxis2-prod.v102.abes.fr:10302/theses_test/_search POST {"query":{"query_string":{"default_operator": "and","fields": ["resumes.*^30","titres.*^30","nnt^15","discipline^15","sujetsRameauPpn^15","sujetsRameauLibelle^15","sujets^15","auteursNP^12","directeursNP^2","ecolesDoctoralesN^5","etabSoutenanceN^5","oaiSets^5","etabsCotutelleN^1","membresJuryNP^1","partenairesRechercheN^1","presidentJuryNP^1","rapporteurs^1"],"query": "science","quote_field_suffix": ".exact"}}}
https://diplotaxis3-prod.v102.abes.fr:10302/theses_test/_search POST {"query":{"query_string":{"default_operator": "and","fields": ["resumes.*^30","titres.*^30","nnt^15","discipline^15","sujetsRameauPpn^15","sujetsRameauLibelle^15","sujets^15","auteursNP^12","directeursNP^2","ecolesDoctoralesN^5","etabSoutenanceN^5","oaiSets^5","etabsCotutelleN^1","membresJuryNP^1","partenairesRechercheN^1","presidentJuryNP^1","rapporteurs^1"],"query": "science","quote_field_suffix": ".exact"}}}
https://diplotaxis4-prod.v102.abes.fr:10302/theses_test/_search POST {"query":{"query_string":{"default_operator": "and","fields": ["resumes.*^30","titres.*^30","nnt^15","discipline^15","sujetsRameauPpn^15","sujetsRameauLibelle^15","sujets^15","auteursNP^12","directeursNP^2","ecolesDoctoralesN^5","etabSoutenanceN^5","oaiSets^5","etabsCotutelleN^1","membresJuryNP^1","partenairesRechercheN^1","presidentJuryNP^1","rapporteurs^1"],"query": "science","quote_field_suffix": ".exact"}}} 
```

Ensuite lancer la commande suivante (remplacer "xxxxxxxxxxxxxxxxxxx" par le mot de passe correpsondant au login "theses-api-recherche" issu du .env) :
```
auth=$(echo -n 'theses-api-recherche:xxxxxxxxxxxxxxxxxxx' | openssl base64)

siege -c200 -t 5S --content-type "application/json" --header="Authorization:Basic $auth" -f ./siege-urls.txt
```

Ensuite CTRL+C pour stopper le test, un rapport s'affichera :
```
Transactions:                   2948 hits
Availability:                 100.00 %
Elapsed time:                  24.05 secs
Data transferred:             133.76 MB
Response time:                  1.55 secs
Transaction rate:             122.58 trans/sec
Throughput:                     5.56 MB/sec
Concurrency:                  190.15
Successful transactions:        2948
Failed transactions:               0
Longest transaction:            6.91
Shortest transaction:           0.23
```

Pour tester via l'API Java theses-api-recherche :
```
# sur des recherches de thèses 
siege -c 100 -t 5S "https://v2-prod.theses.fr/api/v1/theses/recherche/?q=science&debut=0&nombre=10&tri=pertinence"
# sur des recherches de personnes
siege -c 100 -t 5S "https://v2-prod.theses.fr/api/v1/personnes/recherche/?q=science&debut=0&nombre=10&tri=pertinence"
```

Pour mémo pour tester des requêtes sur le solr de theses.fr actuel :
```
siege -c100 -t 5S "http://denim.v102.abes.fr:8080/solr2/select/?q=*%3A*&version=2.2&start=0&rows=10&indent=on&wt=json&fl=*"
```

## Comment requêter (GET ou PUT) le cluster elasticsearch directement avec cURL ?

Voici un exemple de requête pour attaquer directement le cluster elasticsearch de dev (remplacer xxxxxxx par le mot de passe correspondant au login "elastic")
```bash
curl -k -v -u elastic:xxxxxxxx -XGET https://diplotaxis1-dev.v212.abes.fr:10302/_search
```

- `-k` permet d'ignorer les warning du certificat autosigné du cluster
- `-u` permet de passer les login/mdp
- `-XGET` permet de lancer une requête GET sur le cluster mais à adapter avec -XPUT par exemple si on veut passer du PUT

Exemple avec un PUT et une grande structure JSON dont on peut avoir besoin pour les migrations : 
```
curl -k -v -u elastic:xxxxxxxx -XPUT -H 'Content-Type: application/json' https://diplotaxis1-dev.v212.abes.fr:10302/_cluster/settings -d '{
  "transient": {
    "cluster.routing.allocation.enable": null
  },
  "persistent": {
    "cluster.routing.allocation.enable": null
  }
}'
```

## Comment générer un fichier de benchmark à partir de recherches réelles sur le theses.fr actuel ?

Voici une commande permettant de récupérer les mots recherchés sur theses.fr de plus de 5 caractères dédoublonnés depuis son fichier de log apache (serveur raiponce) :
```
cat /var/log/httpd/theses-access_log | \
  grep -E "(GET \/fr\/\?q=)|(GET \/\?q=)" | \
  sed 's#^.*?q=##g' | sed 's# HTTP.*$##g' | sed 's#\([a-z-]*\).*#\1#g' | \
  grep -v ppn | grep -v '^$' | grep -v -E '^.{1,4}$' | \
  sort | uniq > /tmp/mots-recherche-theses.log
```

Voici un exemple de mots clés recherchés à la date du 23/06/2023 : [mots-recherche-theses.log](https://github.com/abes-esr/theses-docker/files/11847315/mots-recherche-theses.log)

Ensuite on peut préparer un fichier en y ajoutant les URL de l'API de prod qui soit prêt pour être utilisé par siege comme ceci :
```
sed 's#^.*$#https://v2-prod.theses.fr/api/v1/theses/recherche/?q=&\&debut=0\&nombre=10\&tri=pertinence#g' mots-recherche-theses.log > siege-urls.txt
```

Voici le résultat à la date du 32/06/2023 : [siege-urls.txt](https://github.com/abes-esr/theses-docker/files/11847438/siege-urls.txt)


Et lancer siege avec ce fichier pendant par exemple 5 secondes (option `-t 5S`) et une concurrence de 100 requêtes (option `-c 100`) en prenant aléatoirement les URL (option `-i`) :
```
$ siege -c 100 -t 5S -i -f siege-urls.txt
** SIEGE 4.0.4
** Preparing 100 concurrent users for battle.
The server is now under siege...
Lifting the server siege...
Transactions:                   1352 hits
Availability:                 100.00 %
Elapsed time:                   4.39 secs
Data transferred:               4.88 MB
Response time:                  0.30 secs
Transaction rate:             307.97 trans/sec
Throughput:                     1.11 MB/sec
Concurrency:                   93.57
Successful transactions:        1352
Failed transactions:               0
Longest transaction:            2.82
Shortest transaction:           0.18
```

## Quelles sont les requêtes réèles envoyées depuis l'API vers elasticsearch ?

Pour une recherche sur les personnes de ce style :  
https://v2-prod.theses.fr/api/v1/personnes/recherche/?q=*&debut=0&nombre=10&tri=pertinence

Voici ce que cela va générer coté ES :
```
GET /personnes/_search/
{
  "query": {
    "function_score": {
      "boost_mode": "multiply",
      "functions": [
        {
          "filter": {
            "term": {
              "has_idref": {
                "value": true
              }
            }
          },
          "weight": 10
        },
        {
          "filter": {
            "term": {
              "roles": {
                "value": "directeur de thèse"
              }
            }
          },
          "weight": 1
        },
        {
          "filter": {
            "term": {
              "roles": {
                "value": "rapporteur"
              }
            }
          },
          "weight": 1
        },
        {
          "script_score": {
            "script": {
              "source": "doc['theses_id'].length"
            }
          }
        },
        {
          "filter": {
            "range": {
              "theses_date": {
                "gte": "now-5y",
                "lte": "now"
              }
            }
          },
          "weight": 0.1
        }
      ],
      "query": {
        "bool": {
          "should": [
            {
              "query_string": {
                "default_operator": "and",
                "fields": [
                  "nom",
                  "prenom",
                  "nom_complet",
                  "nom_complet.exact"
                ],
                "query": "*",
                "quote_field_suffix": ".exact"
              }
            },
            {
              "nested": {
                "path": "theses",
                "query": {
                  "query_string": {
                    "default_operator": "and",
                    "fields": [
                      "theses.sujets.*",
                      "theses.sujets_rameau",
                      "theses.resumes.*",
                      "theses.discipline"
                    ],
                    "query": "*",
                    "quote_field_suffix": ".exact"
                  }
                }
              }
            }
          ]
        }
      },
      "score_mode": "sum"
    }
  }
}
```

Et pour une recherche de ce type sur les thèses :  
https://v2-prod.theses.fr/api/v1/personnes/recherche/?q=*&debut=0&nombre=10&tri=pertinence

Voici ce que cela génère coté ES :
```
GET /theses_test/_search
{
  "query": {
    "query_string": {
      "default_operator": "and",
      "fields": [
        "resumes.*^30",
        "titres.*^30",
        "nnt^15",
        "discipline^15",
        "sujetsRameauPpn^15",
        "sujetsRameauLibelle^15",
        "sujets^15",
        "auteursNP^12",
        "directeursNP^2",
        "ecolesDoctoralesN^5",
        "etabSoutenanceN^5",
        "oaiSets^5",
        "etabsCotutelleN^1",
        "membresJuryNP^1",
        "partenairesRechercheN^1",
        "presidentJuryNP^1",
        "rapporteurs^1"
      ],
      "query": "*",
      "quote_field_suffix": ".exact"
    }
  }
}
```
