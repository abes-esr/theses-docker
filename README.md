# theses-docker

[![Docker Pulls](https://img.shields.io/docker/pulls/abesesr/theses.svg)](https://hub.docker.com/r/abesesr/theses/)

Configuration docker pour déployer le portail national des thÃ¨ses dont le but est de donner accÃ¨s Ã  toutes les theses de theses.fr Ã  l'ensemble de l'enseignement supÃ©rieur et de la recherche. Ces configurations visent Ã  permettre un dÃ©ploiement uniforme en local sur la machine d'un dÃ©veloppeur, et sur les serveurs de dev, test, et prod.

<img src="https://docs.google.com/drawings/d/e/2PACX-1vSh7awYvbYr54GU3F7hsmcbvK25QKixZ1I_a8-mg_X2nimit9SbllmdkXA_n-MaQQBR0KsgrX0dQvga/pub?w=200">

## URLs de theses.fr

Les URLs temporaires du futur theses.fr sont les suivantes :
- en prÃ©prod :
  - https://v2-prod.theses.fr : la homepage de theses.fr
  - https://v2-prod.theses.fr/api/v1/recherche-java/completion/?q=n%C3%A9olithique : l'API de recherche par les theses de theses.fr
  - https://v2-prod.theses.fr/api/v1/personnes/completion/?q=erwann : l'API de recherche par les personnes de theses.fr
  - https://v2-prod.theses.fr/poc-fede/ : le PoC de fÃ©dÃ©ration d'identitÃ©s
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
  - https://v2-local.theses.fr/poc-fede/ : le PoC de fÃ©dÃ©ration d'identitÃ©s
  - https://v2-local.theses.fr/kibana/ : le kibana backoffice de theses.fr

## PrÃ©requis

- docker
- docker compose
- rÃ©glages ``vm.max_map_count`` pour elasticsearch (cf [FAQ pour les dÃ©tails du rÃ©glage](README-faq.md#comment-r%C3%A9gler-vmmax_map_count-pour-elasticsearch-))

## Installation

On commence par rÃ©cupÃ©rer la configuration du dÃ©ploiement depuis le github :
```bash
cd /opt/pod/ # Ã  adapter en local car vous pouvez cloner le dÃ©pÃ´t dans votre homedir
git clone https://github.com/abes-esr/theses-docker.git
```

Ensuite on configure notre dÃ©ploiement en prenant exemple sur le fichier [``.env-dist``](https://github.com/abes-esr/theses-docker/blob/develop/.env-dist) qui contient toutes les variables utilisables avec les explications :
```bash
cd /opt/pod/theses-docker/
cp .env-dist .env
# personnalisez alors le .env en partant des valeurs exemple prÃ©sentes dans le .env-dist
# pour un dÃ©ploiement en local, vous n'avez pas besoin de personnaliser le .env
```

Finalement on rÃ¨gle quelques droits sur les rÃ©pertoires et on peut dÃ©marrer l'application :
```bash
# forcer les droits max pour les volumes dÃ©portÃ©s sur le systÃ¨me de fichier local
cd /opt/pod/theses-docker/
mkdir -p volumes/theses-elasticsearch/            && chmod 777 volumes/theses-elasticsearch/
mkdir -p volumes/theses-elasticsearch-tmp/        && chmod 777 volumes/theses-elasticsearch-tmp/
mkdir -p volumes/theses-elasticsearch-setupcerts/ && chmod 777 volumes/theses-elasticsearch-setupcerts/
mkdir -p volumes/theses-kibana/                   && chmod 777 volumes/theses-kibana/

# puis dÃ©marrer l'application
cd /opt/pod/theses-docker/
docker compose up -d
```
A partir de cet instant l'application Ã©coutera sur l'IP du serveur et sera accessible sur les URL suivantes (remplacer 127.0.0.1 par le nom du serveur) :
- http://127.0.0.1:10301/ : pour la homepage de theses.fr (``theses-front``)
- http://127.0.0.1:10301/api/v1/recherche/_search : pour l'api de recherche de theses.fr (``theses-api-recherche``)
- http://127.0.0.1:10301/poc-fede/ : pour le PoC de fÃ©dÃ©ration d'identitÃ©s (attention, suivre [cette doc]](./README.faq.md) pour un fonctionnement en local)
- http://127.0.0.1:10301/kibana/ : le kibana backoffice de theses.fr

Voir aussi :
- la [doc pour configurer la fÃ©dÃ©ration d'identitÃ©s de theses.fr sur votre environement local](./README.faq.md#comment-configurer-la-f%C3%A9d%C3%A9ration-didentit%C3%A9s-de-thesesfr-en-local-)

## Installation pour la production

Pour la prod il est nÃ©cessaire de dÃ©rouler une [installation classique (cf section au dessus)](./README.md#installation) puis de rÃ©aliser quelques opÃ©rations listÃ©es ci-dessous :
- Il est nÃ©cessaire de [gÃ©nÃ©rer des certificats auto-signÃ©s](./README-faq.md#comment-gÃ©nÃ©rer-mes-propres-certificats-pour-la-fÃ©dÃ©ration-didentitÃ©s-en-prod-) pour enregistrer theses.fr comme fournisseur de service dans la fÃ©dÃ©ration d'identitÃ©s Education-Recherche.
- Et il est nÃ©cessaire de configurer elasticsearch de theses.fr avec 3 noeuds minimum, cf la [doc pour configurer theses.fr avec un cluster elasticsearch Ã  plusieurs noeuds](https://github.com/abes-esr/theses-es-cluster-docker/#readme)

## DÃ©marrage et arret

Pour dÃ©marrer l'application :
```bash
cd /opt/pod/theses-docker/
docker compose up
# ajouter -d si vous souhaitez dÃ©marrer l'application en tache de fond
# dans le cas contraire, utilisez CTRL+C pour ensuite quitter l'application
```

Pour arrÃªter l'applicationPROPREMENT voir chapitre Mise Ã  Jour ci aprÃs sinon dans l'urgence ou s'il n'y a pas d'activitÃ©:
```bash
cd /opt/pod/theses-docker/
docker compose stop
```


## Supervision

Pour vÃ©rifier que l'application est dÃ©marrÃ©e, on peut consulter l'Ã©tat des conteneurs :
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

Pour vÃ©rifier que l'application est bien lancÃ©e, on peut aussi consulter ses logs :
```bash
cd /opt/pod/theses-docker/
docker compose logs --tail=50 -f
```

Les logs de tous les conteneurs de theses-docker sont reversÃ©s dans le puits de log de l'Abes. Voici un exemple de ces logs :
![image](https://user-images.githubusercontent.com/328244/179546231-229fa6ba-53bf-4d5a-a5f9-45a4ac17c883.png)


## DÃ©ploiement continu

Les objectifs des dÃ©ploiements continus de theses-docker sont les suivants (cf [poldev](https://github.com/abes-esr/abes-politique-developpement/blob/main/01-Gestion%20du%20code%20source.md#utilisation-des-branches)) :
- git push sur la branche ``develop`` provoque un dÃ©ploiement automatique sur le serveur ``diplotaxis1-dev``
- git push (le plus couramment merge) sur la branche ``main`` provoque un dÃ©ploiement automatique sur le serveur ``diplotaxis1-test``
- git tag X.X.X (associÃ© Ã  une release) sur la branche ``main`` permet un dÃ©ploiement (non automatique) sur le serveur ``diplotaxis1-prod``

Le dÃ©ploiement automatiquement de ``theses-docker`` utilise l'outil [watchtower](https://containrrr.dev/watchtower/). Pour permettre ce dÃ©ploiement automatique avec watchtower, il suffit de positionner Ã  ``false`` la variable suivante dans le fichier ``/opt/pod/theses-docker/.env`` :
```env
THESES_WATCHTOWER_RUN_ONCE=false
```

Le fonctionnement de watchtower est de surveiller rÃ©guliÃ¨rement l'Ã©ventuelle prÃ©sence d'une nouvelle image docker de ``theses-front`` et ``theses-...``, si oui, de rÃ©cupÃ©rer l'image en question, de stopper le ou les les vieux conteneurs et de crÃ©er le ou les conteneurs correspondants en rÃ©utilisant les mÃªmes paramÃ¨tres que ceux des vieux conteneurs. Pour le dÃ©veloppeur, il lui suffit de faire un git commit+push par exemple sur la branche ``develop`` d'attendre que la github action build et publie l'image, puis que watchtower prenne la main pour que la modification soit disponible sur l'environnement cible, par exemple sur la machine ``diplotaxis1-dev``.

Le fait de passer ``THESES_WATCHTOWER_RUN_ONCE`` Ã  ``false`` va faire en sorte d'exÃ©cuter pÃ©riodiquement watchtower. Par dÃ©faut cette variable est Ã  ``true`` car ce n'est pas utile voir cela peut gÃ©nÃ©rer du bruit dans le cas d'un dÃ©ploiement sur un PC en local.

## Configuration dans un reverse proxy d'entreprise

Cette section explique comment prÃ©parer la belle URL publique https://theses.fr finale ou aussi les URL temporaires de type https://v2-dev.theses.fr/ au niveau de l'infra Abes.

Il est nÃ©cessaire de configurer une entrÃ©e DNS pointant associant ``theses.fr`` ou ``v2-dev.theses.fr`` (pour ne prendre que cet exemple) Ã  l'IP (ou au CNAME) du reverse proxy de l'Abes.

Ensuite il faut ajouter un VirtualHost au niveau du reverse proxy (Ã  adapter en fonction des noms de domaines Ã  gÃ©rer) :
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

        # ne vÃ©rifie pas le certificat interne de theses-rp 
        # car ce dernier est auto-signÃ©
        # https://httpd.apache.org/docs/2.4/fr/mod/mod_ssl.html#sslproxyverify
        SSLProxyVerify none
        SSLProxyCheckPeerCN off
        SSLProxyCheckPeerName off
        SSLProxyCheckPeerExpire off

        # proxification de theses-rp qui Ã©coute par dÃ©faut sur le port 10300
        # et dans cet exemple qui est hÃ©bergÃ© sur le serveur diplotaxis2-dev
        ProxyPreserveHost On
        ProxyPass "/" "https://diplotaxis2-dev.v212.abes.fr:10300/"
        ProxyPassReverse "/" "https://diplotaxis2-dev.v212.abes.fr:10300/"
</VirtualHost>
```

## Sauvegardes et restauration

Pour sauvegarder l'application, il faut :
- Sauvegarder la base de donnÃ©es (base Oracle sur les serveurs orpin) : todo prÃ©ciser de quel schÃ©ma et de quelles tables on parle
- Sauvegarder le fichier ``/opt/pod/theses-docker/.env`` qui est un fichier non versionnÃ© et qui permet de configurer tous les conteneurs docker de l'appli
- Sauvegarder les certificats auto-signÃ©s prÃ©sents dans le rÃ©pertoire ``/opt/pod/theses-docker/volumes/theses-rp/shibboleth/ssl/`` (ces certificats permettent Ã  theses.fr d'Ãªtre reconnu par la fÃ©dÃ©ration d'identitÃ©s Education-Recherche)
- Sauvegarder le dump elasticsearch : todo vraiement nÃ©cessaire ? et todo expliquer comment faire ?
- Sauvegarder le paramÃ©trage kibana : todo vraiement nÃ©cessaire ? et todo expliquer comment faire ?
- Sauvegarder les certificats elasticsearch : todo vraiement nÃ©cessaire ? et todo expliquer comment faire ?

Les chemins volumineux Ã  d'exclure des sauvegardes sont les suivants :
- ``/opt/pod/theses-docker/volumes/theses-elasticsearch/*`` : car il contient les donnÃ©es binaires d'elasticsearch

Pour restaurer l'application, il faut :
- restaurer la base de donnÃ©es
- rÃ©installer l'application (cf plus haut la section installation) en rÃ©utilisant le ``.env`` prÃ©cÃ©dement sauvegardÃ©.

## DÃ©veloppements


### Pour charger un Ã©chantillon de donnÃ©es

Se rÃ©fÃ©rer au code de https://github.com/abes-esr/theses-batch-indexation/tree/11theses (branche 11theses)

Ce batch s'exÃ©cute au dÃ©marrage de theses-docker et va charger des thÃ¨ses et des personnes dans les indexes suivants :
- theses-sample
- personnes-sample

Cet Ã©chantillon de donnÃ©es permet de dÃ©marrer theses-docker et de le tester en Ã©tant totalement indÃ©pendant du SI de l'Abes.

Remarque : l'index sample des personnes n'est pas encore fonctionnel Ã  la date du 03/07/2023

## Procedure de mise a jour ou pour un arret rdemarrage PROPRE d'elasticsearch

1) Arret propre du cluster

* Soit via la console DevTool dans Kibana :
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

3) Si MISE a jour : Modifier la version de l'image dans le .env

5) Redemarrer le cluster elasticsearch noeud apres noeud en commencant par les noeux data

Si Kibana est demarre :
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

4) Si Kibana ne migre pas ou n'est pas demarre (voir les logs) : 

```bash
[.kibana] Action failed with '[incompatible_cluster_routing_allocation] Incompatible Elasticsearch cluster settings detected. Remove the persistent and transient Elasticsearch cluster setting 'cluster.routing.allocation.enable' or set it to a value of 'all' to allow migrations to proceed. Refer to https://www.elastic.co/guide/en/kibana/8.7/resolve-migrations-failures.html#routing-allocation-disabled for more information on how to resolve the issue.

curl -k -v -u elastic:<snip> -XPUT "https://diplotaxis1-dev.v212.abes.fr:10302/_cluster/settings" -d -H 'Content-Type: application/json' '{
  "transient": {
    "cluster.routing.allocation.enable": null
  },
  "persistent": {
    "cluster.routing.allocation.enable": null
  }
}'
```

### Pour charger un echantillon de donnees

Se rÃ©fÃ©rer au code de https://github.com/abes-esr/theses-batch-indexation

Le batch peu Ãªtre utilisÃ© pour :
- Indexer toutes les thÃ¨ses depuis la base de donnÃ©es (base oracle THESES) (3h)
- Indexer toutes les personnes prÃ©sentes dans toutes les thÃ¨ses (idem, depuis la base de donnÃ©es oracle) (5h)

Il faut choisir le job en l'indiquant dans spring.batch.job.names:
- indexationThesesDansES
- indexationPersonnesDansES

Puis lancer en ligne de commande :
En changeant la valeur de -Dspring.batch.job.names si besoin.
```bash 
docker exec -it theses-batch-indexation ./jdk-11.0.2/bin/java -Dspring.batch.job.names=indexationThesesDansES -jar theses-batch-indexation-0.0.1-SNAPSHOT.jar > log.txt
```

Pour le job qui indexe les personnes (indexationPersonnesDansES), il y a une premiÃ¨re Ã©tape qui construit le json en base de donnÃ©es, dans la table PERSONNE_CACHE.
Cette table n'est pas crÃ©Ã©e par le batch, si elle n'existe pas les informations pour crÃ©er la crÃ©er sont dans src/main/resources/personne_cache_table.
Dans une seconde Ã©tape, on va envoyer le contenu de PERSONNE_CACHE dans Elastic Search.

Il y a un job qui peut faire uniquement cette derniÃ¨re Ã©tape (1h): 
- indexationPersonnesDeBddVersES

```bash 
docker exec -it theses-batch-indexation ./jdk-11.0.2/bin/java -Dspring.batch.job.names=indexationPersonnesDeBddVersES -jar theses-batch-indexation-0.0.1-SNAPSHOT.jar > log.txt
```

Il est judicieux de l'utiliser quand on vient d'indexer toutes les personnes dans un environnement, et qu'on souhaite indexer sur un ou plusieurs autres environnements.

## Architecture

Voici la liste et la description des conteneurs dÃ©ployÃ©s par le [docker compose.yml](https://github.com/abes-esr/theses-docker/blob/develop/docker compose.yml)
- ``theses-rp`` : conteneur servant de reverse proxy dÃ©diÃ© Ã  l'authentification des utilisateurs souhaitant accÃ©der Ã  des thÃ¨ses en accÃ¨s restreint. Cette authentification est dÃ©lÃ©guÃ©e Ã  la fÃ©dÃ©ration d'identitÃ©s Education-Recherche. Ce conteneur est l'instanciation de l'image docker [docker-shibboleth-renater-sp](https://github.com/abes-esr/docker-shibboleth-renater-sp).
- ``theses-api-diffusion`` : conteneur qui sera chargÃ© de l'API (en Java Spring) de theses.fr (travail en cours). Dans le cadre du PoC fÃ©dÃ©, ce conteneur est chargÃ© de mettre Ã  disposition un PDF en passant par la fÃ©dÃ©.
- ``theses-api-recherche`` : conteneur qui sera chargÃ© de mettre Ã  disposition l'API de recherche qui sera utilisÃ©e par le ``theses-front``. Cette API fait le passe plat avec le conteneur ``theses-elasticsearch`` qui contient les donnÃ©es indexÃ©e et recherchables dans le langage de requÃªtage d'elasticsearch.
- ``theses-api-indexation`` : conteneur qui sera chargÃ© de proposer une API pour pouvoir indexer une thÃ¨ses Ã  l'unitÃ© dans ``theses-elasticsearch``
- ``theses-front`` : conteneur qui sera chargÃ© du front (en VueJS) de theses.fr (travail en cours)
- ``theses-batch`` : conteneur qui sera chargÃ© des batchs ponctuels ou pÃ©riodiques de theses.fr et en particulier d'un batch qui permettra d'indexer  en masse les 500 000 thÃ¨ses dans ``theses-elasticsearch``
- ``theses-elasticsearch`` : conteneur qui sera chargÃ© d'instancier le moteur de recherche elasticsearch qui contiendra l'indexation des TEF de theses.fr et qui mettra Ã  disposition le langage de requÃªtage d'elasticsearch avec l'API d'elasticsearch (non exposÃ© sur internet)
- ``theses-kibana`` : conteneur qui sera chargÃ© du backoffice de ``theses-elasticsearch`` en proposant des tableaux visuels


Les images docker de theses.fr sont gÃ©nÃ©rÃ©es Ã  partir des codes open sources disponibles ici :
- https://github.com/abes-esr/docker-shibboleth-renater-sp (pour l'authentification avec la fÃ©dÃ©ration d'identitÃ©s)
- https://github.com/abes-esr/theses-api-diffusion
- https://github.com/abes-esr/theses-api-recherche
- https://github.com/abes-esr/theses-api-indexation
- https://github.com/abes-esr/theses-front
- https://github.com/abes-esr/theses-batch

## SchÃ©ma global de l'application : 

![image](https://user-images.githubusercontent.com/3686902/223732169-6daccf99-f86b-40aa-9289-40b626128a8d.png)


