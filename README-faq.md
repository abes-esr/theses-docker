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

Ensuite vous devez faire pointer le nom de domaine ``apollo-local.theses.fr`` sur votre IP local, pour cela voici une astuce en modifiant votre fichier ``hosts`` :
```
# ajouter ces lignes 
# dans votre fichier /etc/hosts (sous linux - besoin de droits admin)
# ou dans C:\Windows\System32\drivers\etc\hosts (sous windows - besoin de droits admin)
127.0.0.1 apollo-local.theses.fr
```

Une fois ces modifications réalisées, vous pourrez accéder à votre theses.fr local sur l'URL suivante (en acceptant au passage l'erreur de sécurité liée au certificat auto-signé) : https://apollo-local.theses.fr

## Comment activer le monitoring du cluster elasticsearch ?

Pour pouvoir suivre l'état du cluster ElasticSearch depuis le Kibana sans installer les outils préconisés du type MetricBeats (qui nécessite une architecture plus complexe), voici comme procéder :

Se rendre dans le kibana et dans l'onglet dev-tools, exemple https://apollo-dev.theses.fr/kibana/, puis taper ceci :
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
https://apollo-dev.theses.fr/kibana/app/monitoring#/elasticsearch

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
   