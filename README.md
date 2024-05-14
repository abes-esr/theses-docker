# theses-docker

[![Docker Pulls](https://img.shields.io/docker/pulls/abesesr/theses.svg)](https://hub.docker.com/r/abesesr/theses/)

Configuration docker pour déployer le portail national des thèses dont le but est de donner accàs à toutes les theses de theses.fr à l'ensemble de l'enseignement supérieur et de la recherche. Ces configurations visent à permettre un déploiement uniforme en local sur la machine d'un développeur, et sur les serveurs de dev, test, et prod.

<img src="https://docs.google.com/drawings/d/e/2PACX-1vSh7awYvbYr54GU3F7hsmcbvK25QKixZ1I_a8-mg_X2nimit9SbllmdkXA_n-MaQQBR0KsgrX0dQvga/pub?w=200">

## URLs de theses.fr

Les URLs temporaires du futur theses.fr sont les suivantes :
- en préprod :
  - https://v2-prod.theses.fr : la homepage de theses.fr
  - https://v2-prod.theses.fr/api/v1/recherche-java/completion/?q=n%C3%A9olithique : l'API de recherche par les theses de theses.fr
  - https://v2-prod.theses.fr/api/v1/personnes/completion/?q=erwann : l'API de recherche par les personnes de theses.fr
  - https://v2-prod.theses.fr/poc-fede/ : le PoC de fédération d'identités
  - https://v2-prod.theses.fr/kibana/ : le kibana backoffice de theses.fr
- en test :
  - https://v2-test.theses.fr : la homepage de theses.fr
  - https://v2-test.theses.fr/api/v1/recherche-java/completion/?q=n%C3%A9olithique : l'API de recherche par les theses de theses.fr
  - https://v2-test.theses.fr/api/v1/personnes/completion/?q=erwann : l'API de recherche par les personnes de theses.fr
  - https://v2-test.theses.fr/kibana/ : le kibana backoffice de theses.fr
- en dev :
  - https://v2-dev.theses.fr : la homepage de theses.fr
  - https://v2-dev.theses.fr/api/v1/recherche-java/completion/?q=n%C3%A9olithique : l'API de recherche par les theses de theses.fr
  - https://v2-dev.theses.fr/api/v1/personnes/completion/?q=erwann : l'API de recherche par les personnes de theses.fr
  - https://v2-dev.theses.fr/kibana/ : le kibana backoffice de theses.fr
- en local : (fonctionne uniquement si vous avez une intallation de theses.fr avec [cette configuration](./README-faq.md))
  - https://v2-local.theses.fr : la homepage de theses.fr
  - https://v2-local.theses.fr/api/v1/recherche-java/completion/?q=n%C3%A9olithique : l'API de recherche par les theses de theses.fr
  - https://v2-local.theses.fr/api/v1/personnes/completion/?q=erwann : l'API de recherche par les personnes de theses.fr
  - https://v2-local.theses.fr/poc-fede/ : le PoC de fédération d'identités
  - https://v2-local.theses.fr/kibana/ : le kibana backoffice de theses.fr

## Prérequis

- docker
- docker compose
- réglages ``vm.max_map_count`` pour elasticsearch (cf [FAQ pour les détails du réglage](README-faq.md#comment-r%C3%A9gler-vmmax_map_count-pour-elasticsearch-))

## Installation

On commence par récupérer la configuration du déploiement depuis le github :
```bash
cd /opt/pod/ # à adapter en local car vous pouvez cloner le dépàt dans votre homedir
git clone https://github.com/abes-esr/theses-docker.git
```

Ensuite on configure notre déploiement en prenant exemple sur le fichier [``.env-dist``](https://github.com/abes-esr/theses-docker/blob/develop/.env-dist) qui contient toutes les variables utilisables avec les explications :
```bash
cd /opt/pod/theses-docker/
cp .env-dist .env
# personnalisez alors le .env en partant des valeurs exemple présentes dans le .env-dist
# pour un déploiement en local, vous n'avez pas besoin de personnaliser le .env
```

Finalement on règle quelques droits sur les répertoires et on peut démarrer l'application :
```bash
# forcer les droits max pour les volumes déportés sur le systàme de fichier local
cd /opt/pod/theses-docker/
mkdir -p volumes/theses-elasticsearch/            && chmod 777 volumes/theses-elasticsearch/
mkdir -p volumes/theses-elasticsearch-tmp/        && chmod 777 volumes/theses-elasticsearch-tmp/
mkdir -p volumes/theses-elasticsearch-setupcerts/ && chmod 777 volumes/theses-elasticsearch-setupcerts/
mkdir -p volumes/theses-kibana/                   && chmod 777 volumes/theses-kibana/

# puis démarrer l'application
cd /opt/pod/theses-docker/
docker compose up -d
```
A partir de cet instant l'application écoutera sur l'IP du serveur et sera accessible sur les URL suivantes (remplacer 127.0.0.1 par le nom du serveur) :
- http://127.0.0.1:10301/ : pour la homepage de theses.fr (``theses-front``)
- http://127.0.0.1:10301/api/v1/recherche/_search : pour l'api de recherche de theses.fr (``theses-api-recherche``)
- http://127.0.0.1:10301/poc-fede/ : pour le PoC de fédération d'identités (attention, suivre [cette doc]](./README.faq.md) pour un fonctionnement en local)
- http://127.0.0.1:10301/kibana/ : le kibana backoffice de theses.fr

Voir aussi :
- la [doc pour configurer la fédération d'identités de theses.fr sur votre environement local](./README.faq.md#comment-configurer-la-f%C3%A9d%C3%A9ration-didentit%C3%A9s-de-thesesfr-en-local-)

## Installation pour la production

Pour la prod il est nécessaire de dérouler une [installation classique (cf section au dessus)](./README.md#installation) puis de réaliser quelques opérations listées ci-dessous :
- Il est nécessaire de [générer des certificats auto-signés](./README-faq.md#comment-générer-mes-propres-certificats-pour-la-fédération-didentités-en-prod-) pour enregistrer theses.fr comme fournisseur de service dans la fédération d'identités Education-Recherche.
- Et il est nécessaire de configurer elasticsearch de theses.fr avec 3 noeuds minimum, cf la [doc pour configurer theses.fr avec un cluster elasticsearch à plusieurs noeuds](https://github.com/abes-esr/theses-es-cluster-docker/#readme)

## Démarrage et arrêt

Pour démarrer l'application :
```bash
cd /opt/pod/theses-docker/
docker compose up
# ajouter -d si vous souhaitez démarrer l'application en tache de fond
# dans le cas contraire, utilisez CTRL+C pour ensuite quitter l'application
```

Pour arrêter l'application PROPREMENT voir chapitre Mise à Jour ci après
Sinon dans l'urgence ou s'il n'y a pas d'activité:
```bash
cd /opt/pod/theses-docker/
docker compose stop
```


## Supervision

Pour vérifier que l'application est démarrée, on peut consulter l'état des conteneurs :
```bash
cd /opt/pod/theses-docker/
docker compose ps
# doit retourner quelque chose comme ceci :
#19:12 $ docker compose ps
#                Name                       Command        State                      Ports                    
#--------------------------------------------------------------------------------------------------------------
#theses-docker_theses-api-diffusion_1   httpd-foreground   Up      80/tcp                                      
#theses-docker_theses-rp_1              httpd-foreground   Up      0.0.0.0:443->443/tcp,:::443->443/tcp, 80/tcp
```

Pour vérifier que l'application est bien lancée, on peut aussi consulter ses logs :
```bash
cd /opt/pod/theses-docker/
docker compose logs --tail=50 -f
```

Les logs de tous les conteneurs de theses-docker sont reversés dans le puits de log de l'Abes. Voici un exemple de ces logs :
![image](https://user-images.githubusercontent.com/328244/179546231-229fa6ba-53bf-4d5a-a5f9-45a4ac17c883.png)


## Déploiement continu

Les objectifs des déploiements continus de theses-docker sont les suivants (cf [poldev](https://github.com/abes-esr/abes-politique-developpement/blob/main/01-Gestion%20du%20code%20source.md#utilisation-des-branches)) :
- git push sur la branche ``develop`` provoque un déploiement automatique sur le serveur ``diplotaxis1-dev``
- git push (le plus couramment merge) sur la branche ``main`` provoque un déploiement automatique sur le serveur ``diplotaxis1-test``
- git tag X.X.X (associé à une release) sur la branche ``main`` permet un déploiement (non automatique) sur le serveur ``diplotaxis1-prod``

Le déploiement automatiquement de ``theses-docker`` utilise l'outil [watchtower](https://containrrr.dev/watchtower/). Pour permettre ce déploiement automatique avec watchtower, il suffit de positionner à ``false`` la variable suivante dans le fichier ``/opt/pod/theses-docker/.env`` :
```env
THESES_WATCHTOWER_RUN_ONCE=false
```

Le fonctionnement de watchtower est de surveiller régulièrement l'éventuelle présence d'une nouvelle image docker de ``theses-front`` et ``theses-...``, si oui, de récupérer l'image en question, de stopper le ou les les vieux conteneurs et de créer le ou les conteneurs correspondants en réutilisant les mêmes paramètres que ceux des vieux conteneurs. Pour le développeur, il lui suffit de faire un git commit+push par exemple sur la branche ``develop`` d'attendre que la github action build et publie l'image, puis que watchtower prenne la main pour que la modification soit disponible sur l'environnement cible, par exemple sur la machine ``diplotaxis1-dev``.

Le fait de passer ``THESES_WATCHTOWER_RUN_ONCE`` à ``false`` va faire en sorte d'exécuter périodiquement watchtower. Par défaut cette variable est à ``true`` car ce n'est pas utile voir cela peut générer du bruit dans le cas d'un déploiement sur un PC en local.

## Configuration dans un reverse proxy d'entreprise

Cette section explique comment préparer la belle URL publique https://theses.fr finale ou aussi les URL temporaires de type https://v2-dev.theses.fr/ au niveau de l'infra Abes.

Il est nécessaire de configurer une entrée DNS pointant associant ``theses.fr`` ou ``v2-dev.theses.fr`` (pour ne prendre que cet exemple) à l'IP (ou au CNAME) du reverse proxy de l'Abes.

Ensuite il faut ajouter un VirtualHost au niveau du reverse proxy (à adapter en fonction des noms de domaines à gérer) :
```apache
# redirection automatique http vers https
<VirtualHost *:80>
        ServerName v2-dev.theses.fr
        ServerAdmin admin@theses.fr
        RewriteEngine On
        RewriteCond %{HTTPS} !=on
        RewriteRule ^/(.*|$) https://%{HTTP_HOST}/$1 [L,R]
</VirtualHost>

<VirtualHost *:443>
        ServerName v2-dev.theses.fr
        ServerAdmin admin@theses.fr
        RewriteEngine on
        
        ErrorLog logs/theses-docker-test-error_log
        CustomLog logs/theses-docker-test-access_log common
        TransferLog logs/ssl_access_log
        LogLevel warn rewrite:trace3

        SSLEngine on
        SSLProxyEngine on
        SSLCertificateFile /etc/pki/tls/certs/__abes_fr_cert.cer
        SSLCertificateKeyFile /etc/pki/tls/private/abes.fr.key
        SSLCertificateChainFile /etc/pki/tls/certs/__abes_fr_interm.cer

        # ne vérifie pas le certificat interne de theses-rp 
        # car ce dernier est auto-signé
        # https://httpd.apache.org/docs/2.4/fr/mod/mod_ssl.html#sslproxyverify
        SSLProxyVerify none
        SSLProxyCheckPeerCN off
        SSLProxyCheckPeerName off
        SSLProxyCheckPeerExpire off

        # proxification de theses-rp qui écoute par défaut sur le port 10300
        # et dans cet exemple qui est hébergé sur le serveur diplotaxis2-dev
        ProxyPreserveHost On
        ProxyPass "/" "https://diplotaxis2-dev.v212.abes.fr:10300/"
        ProxyPassReverse "/" "https://diplotaxis2-dev.v212.abes.fr:10300/"
</VirtualHost>
```

## Sauvegardes et restauration

Pour sauvegarder l'application, il faut :
- Sauvegarder la base de données (base Oracle sur les serveurs orpin) : TODO préciser de quel schéma et de quelles tables on parle
- Sauvegarder le fichier ``/opt/pod/theses-docker/.env`` qui est un fichier non versionné et qui permet de configurer tous les conteneurs docker de l'appli
- Sauvegarder les certificats auto-signés présents dans le répertoire ``/opt/pod/theses-docker/volumes/theses-rp/shibboleth/ssl/`` (ces certificats permettent à theses.fr d'être reconnu par la fédération d'identités Education-Recherche)
- Sauvegarder le dump elasticsearch et/ou le paramétrage kibana : Il faut, via Kibana, programmer des sauvegardes (appellées 'snapshots') sur un volume externe NFS par ex. préalablement configuré et monté dans un volume local à l'application.
On passe par le menu Management -> snapshot and restore et on choisit les données et la fréquence des sauvegardes.
- Sauvegarder les certificats elasticsearch : todo vraiement nécessaire ? et todo expliquer comment faire ?

Les chemins volumineux à d'exclure des sauvegardes sont les suivants :
- ``/opt/pod/theses-docker/volumes/theses-elasticsearch/*`` : car il contient les données binaires d'elasticsearch

Pour restaurer l'application, il faut selon la gravité de la situation :
- Simple restauration d'index depuis un snapshot :
  Dans le menu Kibana de gestion des index il faut cloturer l'index  a restaurer.
  Puis aller sur Management -> snapshot and restore et choisir (cocher à gauche) le snapshot à la bonne date.
  Lancer la restauration (icone en fin de ligne) : une suite de pages permets ensuite de choisir quels paramètres seront restaurés.
  Pour un index seul décocher tout et garder seulement l'index voulu.
- Restauration complète depuis un snapshot : même principe mais choisir tous les index et bien vérifier les paramètres globaux a restaurer - ou pas.
- Restaureration de la base de données : procédure de restauration propre à Oracle DB (rman)
- Réinstallation de l'application : Cf. plus haut la section 'Installation' en réutilisant le ``.env`` précédement sauvegardé.

## Développements


### Pour charger un échantillon de données

Se référer au code de https://github.com/abes-esr/theses-batch-indexation/tree/11theses (branche 11theses)

Ce batch s'exécute au démarrage de theses-docker et va charger des thèses et des personnes dans les indexes suivants :
- theses-sample
- personnes-sample

Cet échantillon de données permet de démarrer theses-docker et de le tester en étant totalement indépendant du SI de l'Abes.

Remarque : l'index sample des personnes n'est pas encore fonctionnel à la date du 03/07/2023

## Procedure de Mise à jour ou pour un arrêt redémarrage PROPRE d'elasticsearch

1) Arret propre du cluster

* Soit via la console Devtool dans Kibana :
```bash
PUT _cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.enable": "primaries"
  }
}

POST /_flush
```
* Soit avec Curl si la console n'est pas disponible :

```bash
curl -k -v -u elastic:<snip> -XPUT "http://diplotaxis1-dev.v212.abes.fr:10302/_cluster/settings" -H "kbn-xsrf: reporting" -H "Content-Type: application/json" -d'
{
  "persistent": {
    "cluster.routing.allocation.enable": "primaries"
  }
}'

# Flush
curl -XPOST "http://diplotaxis1-dev.v212.abes.fr:10302/_flush" -H "kbn-xsrf: reporting"
```

2) Stopper un par un les noeuds data puis finir par les master.

3) Pour une mise à jour des produits elastic.co : modifier la version de l'image dans le .env

5) Redémarrer le cluster elasticsearch noeud après noeud en commencant par les noeux data et en finissant par le(s) master
   ATTENTION de bien vérifier que le cluster est en statut green ou yellow avant de redémarrer un autre noeud
   cela peut prendre plusieurs minutes par noeud selon la quantité de données présentes

7) Remettre le cluster en mode actif (uniquement s'il est en statut 'yellow' ou 'green')

- Si Kibana est actif (normalement non après une mise à jour) par la console Devtool :
```bash
GET _cat/nodes

PUT _cluster/settings
{
  "persistent": {
    "cluster.routing.allocation.enable": null
  }
}

# check cluster health
GET _cat/health
```

 - Si Kibana n'est pas démarré (ou ne migre pas suite à une mise à jour - voir les logs) avec Curl : 

```bash
[.kibana] Action failed with '[incompatible_cluster_routing_allocation] Incompatible Elasticsearch cluster settings detected. Remove the persistent and transient Elasticsearch cluster setting 'cluster.routing.allocation.enable' or set it to a value of 'all' to allow migrations to proceed. Refer to https://www.elastic.co/guide/en/kibana/8.7/resolve-migrations-failures.html#routing-allocation-disabled for more information on how to resolve the issue.
```
```bash
curl -k -v -u elastic:<snip> -XPUT "https://diplotaxis1-dev.v212.abes.fr:10302/_cluster/settings" -d -H 'Content-Type: application/json' '{
  "transient": {
    "cluster.routing.allocation.enable": null
  },
  "persistent": {
    "cluster.routing.allocation.enable": null
  }
}'
```

### Pour charger un echantillon de données

Se référer au code de https://github.com/abes-esr/theses-batch-indexation

Le batch peu être utilisé pour :
- Indexer toutes les thèses depuis la base de données (base oracle THESES) (3h)
- Indexer toutes les personnes présentes dans toutes les thèses (idem, depuis la base de données oracle) (5h)

Il faut choisir le job en l'indiquant dans spring.batch.job.names:
- indexationThesesDansES
- indexationPersonnesDansES

Puis lancer en ligne de commande :
En changeant la valeur de -Dspring.batch.job.names si besoin.
```bash 
docker exec -it theses-batch-indexation ./jdk-11.0.2/bin/java -Dspring.batch.job.names=indexationThesesDansES -jar theses-batch-indexation-0.0.1-SNAPSHOT.jar > log.txt
```

Pour le job qui indexe les personnes (indexationPersonnesDansES), il y a une première étape qui construit le json en base de données, dans la table PERSONNE_CACHE.
Cette table n'est pas créée par le batch, si elle n'existe pas les informations pour créer la créer sont dans src/main/resources/personne_cache_table.
Dans une seconde étape, on va envoyer le contenu de PERSONNE_CACHE dans Elastic Search.

Il y a un job qui peut faire uniquement cette dernière étape (1h): 
- indexationPersonnesDeBddVersES

```bash 
docker exec -it theses-batch-indexation ./jdk-11.0.2/bin/java -Dspring.batch.job.names=indexationPersonnesDeBddVersES -jar theses-batch-indexation-0.0.1-SNAPSHOT.jar > log.txt
```

Il est judicieux de l'utiliser quand on vient d'indexer toutes les personnes dans un environnement, et qu'on souhaite indexer sur un ou plusieurs autres environnements.

## Architecture

Voici la liste et la description des conteneurs déployés par le [docker compose.yml](https://github.com/abes-esr/theses-docker/blob/develop/docker compose.yml)
- ``theses-rp`` : conteneur servant de reverse proxy dédié à l'authentification des utilisateurs souhaitant accéder à des thèses en accès restreint. Cette authentification est déléguée à la fédération d'identités Education-Recherche. Ce conteneur est l'instanciation de l'image docker [docker-shibboleth-renater-sp](https://github.com/abes-esr/docker-shibboleth-renater-sp).
- ``theses-api-diffusion`` : conteneur qui sera chargé de l'API (en Java Spring) de theses.fr (travail en cours). Dans le cadre du PoC fédé, ce conteneur est chargé de mettre à disposition un PDF en passant par la fédé.
- ``theses-api-recherche`` : conteneur qui sera chargé de mettre à disposition l'API de recherche qui sera utilisée par le ``theses-front``. Cette API fait le passe plat avec le conteneur ``theses-elasticsearch`` qui contient les données indexée et recherchables dans le langage de requêtage d'elasticsearch.
- ``theses-api-indexation`` : conteneur qui sera chargé de proposer une API pour pouvoir indexer une thèses à l'unité dans ``theses-elasticsearch``
- ``theses-front`` : conteneur qui sera chargé du front (en VueJS) de theses.fr (travail en cours)
- ``theses-batch`` : conteneur qui sera chargé des batchs ponctuels ou périodiques de theses.fr et en particulier d'un batch qui permettra d'indexer  en masse les 500 000 thèses dans ``theses-elasticsearch``
- ``theses-elasticsearch`` : conteneur qui sera chargé d'instancier le moteur de recherche elasticsearch qui contiendra l'indexation des TEF de theses.fr et qui mettra à disposition le langage de requêtage d'elasticsearch avec l'API d'elasticsearch (non exposé sur internet)
- ``theses-kibana`` : conteneur qui sera chargé du backoffice de ``theses-elasticsearch`` en proposant des tableaux visuels


Les images docker de theses.fr sont générées à partir des codes open sources disponibles ici :
- https://github.com/abes-esr/docker-shibboleth-renater-sp (pour l'authentification avec la fédération d'identités)
- https://github.com/abes-esr/theses-api-diffusion
- https://github.com/abes-esr/theses-api-recherche
- https://github.com/abes-esr/theses-api-indexation
- https://github.com/abes-esr/theses-front
- https://github.com/abes-esr/theses-batch

## Schéma global de l'application : 

![image](https://user-images.githubusercontent.com/3686902/223732169-6daccf99-f86b-40aa-9289-40b626128a8d.png)


