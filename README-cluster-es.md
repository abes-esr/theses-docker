# Installation de theses-docker avec un cluster elasticsearch

Pour déployer theses.fr sur les serveurs de dev, test et prod, il est préférable (obligatoire pour la prod) de passer par un cluster elasticsearch à trois noeuds sur 3 serveurs distincts. Voici la marche à suivre :

On suppose dout d'abord un déploiement sur les serveurs suivants (remplacer le nom du serveur pour les autres environnements) :
- diplotaxis1-test
- diplotaxis2-test
- diplotaxis3-test

## Noeud 1 : toute l'appli theses.fr + le premier noeud elasticsearch

Sur le premier noeud on va installer la pile logicielle complète de theses.fr qui contient tous les modules de theses.fr ainsi que le premier noeud du cluster elasticsearch et kibana. Pour cela il faut se reporter à la [section installation](README.md#installation).

Sur ce premier noeud, les réglages particuliers à réaliser dans le .env sont les suivants :
```env
ELK_DISCOVER_SEED_HOSTS=diplotaxis1-test:10302,diplotaxis2-test:10302,diplotaxis3-test:10302
ELK_CLUSTER_INITIAL_MASTER_NODES=theses-elasticsearch-es01,theses-elasticsearch-es02,theses-elasticsearch-es03
```

Vous devez ensuite lancer l'application avec ``docker-compose up -d`` puis récupérer les certificats générés par le conteneur ``theses-elasticsearch-setupcerts`` qui sont générés uniquement sur ce premier noeud. Ce sont ces certificats qui permettront aux 3 noeuds elasticsearch de communiquer de façon sécurisée au sein du cluster elasticsearch. Voici comment procéder pour les récupérer et les transmettre aux 2 autres noeuds elasticsearch (qui sont sur deux serveurs différents) :
```bash
cd /opt/pod/theses-docker/
docker cp theses-elasticsearch-setupcerts:/usr/share/elasticsearch/config/certs/ca.zip .
docker cp theses-elasticsearch-setupcerts:/usr/share/elasticsearch/config/certs/certs.zip .

# ensuite il faut les copier sur les deux autres noeuds (mais cela pré-suppose que les répertoires de destination existent) :
scp certs.zip ca.zip diplotaxis2-test:/opt/pod/theses-docker/volumes/theses-elasticsearch-setupcerts/
scp ca.zip ca.zip diplotaxis3-test:/opt/pod/theses-docker/volumes/theses-elasticsearch-setupcerts/
```

## Noeud 2 & 3 : les deux autres noeuds elasticsearch de theses.fr

Le second et le troisième noeud elasticsearch de theses.fr sont respectivement déployés sur ``diplotaxis2-test`` et ``diplotaxis2-test``.

```bash
# Ces opérations sont à reproduire sur diplotaxis3-test
# remplacer pour cela "diplotaxis2-test" par "diplotaxis3-test"
#                   et "theses-elasticsearch-es02" par "theses-elasticsearch-es03"
ssh diplotaxis2-test
cd /opt/pod/
git clone https://github.com/abes-esr/theses-docker.git
cd /opt/pod/theses-docker/
chmod 777 volumes/theses-elasticsearch-setupcerts/ # cette étape est nécessaire pour que la copie de certs.zip et ca.zip puisse se faire (cf section au dessus)
chmod 777 volumes/theses-elasticsearch-es02/
```

Ensuite il faut créer un fichier ``/opt/pod/theses-docker/.env`` épuré qui est nécessaire au fonctionnement des noeuds elasticsearch indépendants (adapter le mot de passe ELASTIC_PASSWORD pour être identique sur les 3 noeuds) :
```
ELK_ELASTIC_PORT=10302
ELK_STACK_VERSION=8.3.0
ELASTIC_PASSWORD=xxxxxxxxxxxxx
ELK_CLUSTER_NAME=theses-cluster
ELK_LICENSE=basic
ELK_MEM_LIMIT=1073741824
ELK_DISCOVER_SEED_HOSTS=diplotaxis1-test:10302,diplotaxis2-test:10302,diplotaxis3-test:10302
ELK_CLUSTER_INITIAL_MASTER_NODES=theses-elasticsearch-es01,theses-elasticsearch-es02,theses-elasticsearch-es03
```

Et finalement on peut démarrer le noeud elasticsearch :
```bash
docker-compose -f docker-compose.theses-elasticsearch-es02.yml up -d
```

