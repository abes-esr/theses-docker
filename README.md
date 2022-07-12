# theses-docker

(travail en cours)

Configuration docker 🐳 permettant de déployer le portail national des thèses dont le but est de donner accès à toutes les theses de theses.fr à l'ensemble de l'enseignement supérieur et recherche. Ces configurations visent à permettre un déploiement uniforme en local sur la machine d'un développeur, et sur les serveurs de dev, test, et prod.

<img src="https://docs.google.com/drawings/d/e/2PACX-1vSh7awYvbYr54GU3F7hsmcbvK25QKixZ1I_a8-mg_X2nimit9SbllmdkXA_n-MaQQBR0KsgrX0dQvga/pub?w=200">

Les URLs temporaires du futur theses.fr sont les suivantes :
- en dev : https://apollo-dev.theses.fr
- en test : https://apollo-test.theses.fr 
- en préprod : https://apollo-prod.theses.fr (pas encore dispo)

A noter que les images docker de theses.fr sont générées à partir des codes open sources disponibles ici :
- https://github.com/abes-esr/docker-shibboleth-renater-sp (pour l'authentification avec la fédération d'identités)
- https://github.com/abes-esr/theses-api-diffusion (à créer)
- https://github.com/abes-esr/theses-api-recherche (à créer)
- https://github.com/abes-esr/theses-api-indexation (à créer)
- https://github.com/abes-esr/theses-front (à créer)
- https://github.com/abes-esr/theses-batch (à ajuster)

## Prérequis

- docker
- docker-compose
- réglages ``vm.max_map_count`` pour elasticsearch (cf [FAQ pour les détails du réglage](https://github.com/abes-esr/theses-docker/blob/develop/README-FAQ.md#comment-r%C3%A9gler-vmmax_map_count-pour-elasticsearch-))

## Installation

Cette procédure est adaptée pour installer theses.fr en local ou sur un serveur avec un mono noeud elasticsearch. Pour une configuration avec un cluster elasticsearch, voir un peu plus bas.

On commence par récupérer la configuration du déploiement depuis le github :
```bash
cd /opt/pod/ # à adapter en local car vous pouvez cloner le dépôt dans votre homedir
git clone https://github.com/abes-esr/theses-docker.git
```

Ensuite on configure notre déploiement en prenant exemple sur le fichier [``.env-dist``](https://github.com/abes-esr/theses-docker/blob/develop/.env-dist) qui contient toutes la variables utilisables avec les explications :
```
cd /opt/pod/theses-docker/
cp .env-dist .env
# personnalisez alors le .env en partant des valeurs exemple présentes dans le .env-dist
# pour un déploiement en local, vous n'avez pas besoin de personnaliser le .env
```

Finalement on règle quelques droits sur les répertoire et on peut démarrer l'application :
```bash
# forcer les droits max pour les volumes déportés sur le système de fichier local
cd /opt/pod/theses-docker/
chmod 777 volumes/theses-elasticsearch-es01/
chmod 777 volumes/theses-elasticsearch-setupcerts/
chmod 777 volumes/theses-kibana/

# puis démarrer l'application
cd /opt/pod/theses-docker/
docker-compose up -d
```

A partir de cet instant l'application écoutera sur l'IP du serveur et par défaut sur les ports suivants (remplacer 127.0.0.1 par le nom du serveur) :
- https://127.0.0.1:10300 : pour le theses-rp en https (il faudra accepter l'erreur de sécurité car c'est un certificat autosigné qui est utilisé en standard)
- https://127.0.0.1:10301 : pour le theses-rp en http 
- http://127.0.0.1:10303 : pour theses-kibana

Spécificité en local pour simuler le vrai nom de domaine (sans cette modification theses-rp ne fonctionnera pas avec la fédération d'identités) :
```
# ajouter ces lignes 
# dans votre fichier /etc/hosts (sous linux - besoin de droits admin)
# ou dans C:\Windows\System32\drivers\etc\hosts (sous windows - besoin de droits admin)
127.0.0.1 apollo-dev.theses.fr
127.0.0.1 apollo-test.theses.fr
127.0.0.1 apollo-prod.theses.fr
```

Une fois ces modifications réalisées, vous alors naviguer sur l'URL suivante qui pointera en fait vers https://127.0.0.1 (adapter le -dev en -test ou -prod en fonction de votre paramétrage dans le .env) :
- https://apollo-dev.theses.fr (il faudra accepter l'erreur de sécurité car c'est un certificat autosigné qui est utilisé en standard)

## Installation avec un cluster elasticsearch

Pour déployer theses.fr sur les serveurs de dev, test et prod, il est préférable (obligatoire pour la prod) de passer par un cluster elasticsearch à trois noeuds sur 3 serveurs distincts. Voici la marche à suivre :

On suppose dout d'abord un déploiement sur les serveurs suivants (remplacer le nom du serveur pour les autres environnements) :
- diplotaxis1-test
- diplotaxis2-test
- diplotaxis3-test

### Noeud 1 : Toute l'appli theses.fr + le premier noeud elasticsearch

Sur le premier noeud on va installer la pile logicielle complète de theses.fr qui contient tous les modules de theses.fr ainsi que le premier noeud du cluster elasticsearch et kibana. Pour cela il faut se reporter à la [section installation](#installation) juste au dessus.

Les réglages particuliers à réaliser dans le .env sont les suivants :
```env
ELK_DISCOVER_SEED_HOSTS="diplotaxis1-test:10302,diplotaxis2-test:10302,diplotaxis3-test:10302"
ELK_CLUSTER_INITIAL_MASTER_NODES="theses-elasticsearch-es01,theses-elasticsearch-es02,theses-elasticsearch-es03"
```

Vous devez ensuite lancer l'application avec ``docker-compose up -d`` (cf section au dessus) puis récupérer les certificats générés par ``theses-elasticsearch-setupcerts`` qui sont générés uniquement sur ce premier noeud. Ce sont les certificats qui permettront aux 3 noeuds de communiquer de façon sécurisée au sein du cluster elasticsearch. Voici comment procéder :
```bash
cd /opt/pod/theses-docker/
docker cp theses-elasticsearch-setupcerts:/usr/share/elasticsearch/config/certs/ca.zip .
docker cp theses-elasticsearch-setupcerts:/usr/share/elasticsearch/config/certs/certs.zip .

# ensuite il faut les copier sur les deux autres noeuds (mais cela pré-suppose que les répertoires de destination existent) :
scp certs.zip ca.zip diplotaxis2-test:/opt/pod/theses-docker/volumes/theses-elasticsearch-setupcerts/
scp ca.zip ca.zip diplotaxis3-test:/opt/pod/theses-docker/volumes/theses-elasticsearch-setupcerts/
```

### Noeud 2 & 3 : les deux autres noeuds elasticsearch de theses.fr

Le second et le troisième noeud elasticsearch de theses.fr sont respectivement déployés sur diplotaxis2-test et diplotaxis2-test.

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
ELK_ELASTIC_PORT="10302"
ELK_STACK_VERSION="8.3.0"
ELASTIC_PASSWORD="xxxxxxxxxxxxx"
ELK_CLUSTER_NAME="theses-cluster"
ELK_LICENSE="basic"
ELK_MEM_LIMIT="1073741824"
ELK_DISCOVER_SEED_HOSTS="diplotaxis1-test:10302,diplotaxis2-test:10302,diplotaxis3-test:10302"
ELK_CLUSTER_INITIAL_MASTER_NODES="theses-elasticsearch-es01,theses-elasticsearch-es02,theses-elasticsearch-es03"
```

Et finalement on peut démarrer le noeud elasticsearch :
```bash
docker-compose -f docker-compose.theses-elasticsearch-es02.yml up -d
```


## Démarrage et arret

Pour démarrer l'application :
```bash
cd /opt/pod/theses-docker/
docker-compose up
# ajouter -d si vous souhaitez démarrer l'application en tache de fond
# dans le cas contraire, utilisez CTRL+C pour ensuite quitter l'application
```

L'application va alors écouter sur les ports 443 (port par défaut du https) et vous pourrez la consultez en suivant ce lien :
- https://apollo-dev.theses.fr/ (racine publique de l'application => affiche normalement "It Works !")
- https://apollo-dev.theses.fr/ (PDF sous contrôle d'accès => affiche normalement le PDF une fois la phase d'authentification terminée)

Pour arrêter l'application :
```bash
cd /opt/pod/theses-docker/
docker-compose stop
```

## Configuration

Pour configurer l'application, il est nécessaire de créer un fichier ``.env`` au même niveau que le fichier ``docker-compose.yml`` de ce dépôt. Le contenu du ``.env`` est une liste de paramètres (clés/valeurs) dont la documentation et des exemples de valeurs sont présent dans le fichier [``.env-dist``](https://github.com/abes-esr/theses-docker/blob/develop/.env-dist).


TODO : expliquer comment configurer les certificats SSL nécessaires à la fédé de ``theses-rp`` pour la production (à placer dans un volume monté sur ``theses-rp``)

TODO: compléter pour le déploiement sur dev,test,prod avec la couche du reverse proxy raiponce



## Supervision

Pour vérifier que l'application est démarrée, on peut consulter l'état des conteneurs :
```bash
cd /opt/pod/theses-docker/
docker-compose ps
# doit retourner quelque chose comme ceci :
#19:12 $ docker-compose ps
#                Name                       Command        State                      Ports                    
#--------------------------------------------------------------------------------------------------------------
#theses-docker_theses-api-diffusion_1   httpd-foreground   Up      80/tcp                                      
#theses-docker_theses-rp_1              httpd-foreground   Up      0.0.0.0:443->443/tcp,:::443->443/tcp, 80/tcp
```

Pour vérifier que l'application est bien lancée, on peut aussi consulter ses logs :
```bash
cd /opt/pod/theses-docker/
docker-compose logs --tail=50 -f
```

TODO : ajouter remarque pour le versement des logs dans le puits de log (quand ce sera fait)


## Mise à jour de l'application


(TODO : compléter et adapter si on déporte les numéro de version dans le ``.env``)

En suposant qu'une nouvelle version de https://github.com/abes-esr/docker-shibboleth-renater-sp est diponible, on peut mettre à jour ``theses-rp`` en spécifiant le nouveau numéro de version dans le docker-compose.yml [à la ligne qui pointe vers l'image docker abesesr/docker-shibboleth-renater-sp:x.x.x](https://github.com/abes-esr/theses-docker/blob/develop/docker-compose.yml#L15). Ensuite il suffit de récupérer l'image docker en question et de relancer l'application comme ceci :
```bash
cd /opt/pod/theses-docker/
docker-compose pull # facultatif car le "docker-compose up" va faire le téléchargement si besoin
docker-compose up -d
```

## Sauvegardes et restauration

Pour sauvegarder l'application, il faut :
- Sauvegarder la base de données (base Oracle sur les serveurs orpin) : todo préciser de quel schéma et de quelles tables on parle
- Sauvegarder le fichier ``.env`` qui est le seul fichier non versionné et qui permet de configurer tous les conteneurs docker de l'appli

Pour restaurer l'application, il faut :
- restaurer la base de données
- réinstaller l'application (cf plus haut la section installation) en réutilisant le ``.env`` précédement sauvegardé.

## Développements


### Pour charger un échantillon de données

Pour indexer 11 thèses exemple dans elasticsearch, voici comment procéder :
```bash
cd /opt/pod/theses-docker/
docker-compose up --build theses-batch-11theses
```

Cette commande aura pour effet de lancer le batch ``images/theses-batch/theses-sample-load.sh`` qui va faire 3 choses :
- supprimer l'index ``theses-sample``
- créer l'index ``theses-sample`` avec son mapping elasticsearch
- charger 11 thèses exemple dans l'index ``theses-sample`` 


## Architecture

Voici la liste et la description des conteneurs déployés par le [docker-compose.yml](https://github.com/abes-esr/theses-docker/blob/develop/docker-compose.yml)
- ``theses-rp`` : conteneur servant de reverse proxy dédié à l'authentification des utilisateurs souhaitant accéder à des thèses en accès restreint. Cette authentification est déléguée à la fédération d'identités Education-Recherche. Ce conteneur est l'instanciation de l'image docker [docker-shibboleth-renater-sp](https://github.com/abes-esr/docker-shibboleth-renater-sp).
- ``theses-api-diffusion`` : conteneur qui sera chargé de l'API (en Java Spring) de theses.fr (travail en cours). Dans le cadre du PoC fédé, ce conteneur est chargé de mettre à disposition un PDF en passant par la fédé.
- ``theses-api-recherche`` : conteneur qui sera chargé de mettre à disposition l'API de recherche qui sera utilisée par le ``theses-front``. Cette API fait le passe plat avec le conteneur ``theses-elasticsearch`` qui contient les données indexée et recherchables dans le langage de requêtage d'elasticsearch.
- ``theses-api-indexation`` : conteneur qui sera chargé de proposer une API pour pouvoir indexer une thèses à l'unité dans ``theses-elasticsearch``
- ``theses-front`` : conteneur qui sera chargé du front (en VueJS) de theses.fr (travail en cours)
- ``theses-batch`` : conteneur qui sera chargé des batchs ponctuels ou périodiques de theses.fr et en particulier d'un batch qui permettra d'indexer  en masse les 500 000 thèses dans ``theses-elasticsearch``
- ``theses-elasticsearch`` : conteneur qui sera chargé d'instancier le moteur de recherche elasticsearch qui contiendra l'indexation des TEF de theses.fr et qui mettra à disposition le langage de requêtage d'elasticsearch avec l'API d'elasticsearch (non exposé sur internet)
- ``theses-kibana`` : conteneur qui sera chargé du backoffice de ``theses-elasticsearch`` en proposant des tableaux visuels


