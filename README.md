# theses-docker

(travail en cours)

Configuration docker 🐳 pour déployer le portail national des thèses dont le but est de donner accès à toutes les theses de theses.fr à l'ensemble de l'enseignement supérieur et de la recherche. Ces configurations visent à permettre un déploiement uniforme en local sur la machine d'un développeur, et sur les serveurs de dev, test, et prod.

<img src="https://docs.google.com/drawings/d/e/2PACX-1vSh7awYvbYr54GU3F7hsmcbvK25QKixZ1I_a8-mg_X2nimit9SbllmdkXA_n-MaQQBR0KsgrX0dQvga/pub?w=200">

Les URLs temporaires du futur theses.fr sont les suivantes :
- en local : https://apollo-local.theses.fr (fonctionne uniquement si vous avez une intallation de theses.fr déployée en local)
- en dev : https://apollo-dev.theses.fr
- en test : https://apollo-test.theses.fr 
- en préprod : https://apollo-prod.theses.fr

## Prérequis

- docker
- docker-compose
- réglages ``vm.max_map_count`` pour elasticsearch (cf [FAQ pour les détails du réglage](README-faq.md#comment-r%C3%A9gler-vmmax_map_count-pour-elasticsearch-))

## Installation

Cette procédure est adaptée pour installer theses.fr en local ou sur un serveur avec un mono noeud elasticsearch.
Pour une configuration avec un cluster elasticsearch, voir [la documentation dédiée ici](README-cluster-es.md).

On commence par récupérer la configuration du déploiement depuis le github :
```bash
cd /opt/pod/ # à adapter en local car vous pouvez cloner le dépôt dans votre homedir
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
# forcer les droits max pour les volumes déportés sur le système de fichier local
cd /opt/pod/theses-docker/
mkdir -p volumes/theses-elasticsearch-es01/       && chmod 777 volumes/theses-elasticsearch-es01/
mkdir -p volumes/theses-elasticsearch-setupcerts/ && chmod 777 volumes/theses-elasticsearch-setupcerts/
mkdir -p volumes/theses-kibana/                   && chmod 777 volumes/theses-kibana/

# puis démarrer l'application
cd /opt/pod/theses-docker/
docker-compose up -d
```

A partir de cet instant l'application écoutera sur l'IP du serveur et par défaut sur les ports suivants (remplacer 127.0.0.1 par le nom du serveur) :
- https://127.0.0.1:10300 : pour theses-rp en https (il faudra accepter l'erreur de sécurité car c'est un certificat autosigné qui est utilisé en standard)
- http://127.0.0.1:10301 : pour theses-rp en http 
- https://127.0.0.1:10302 : pour theses-elasticsearch-es01 en https (attention il faut utiliser le user 'elastic' avec le mot de passe correspondant réglé dans ``.env`` et il faudra ignorer l'erreur de certificat HTTPS car lui aussi est auto-signé)
- http://127.0.0.1:10303 : pour theses-kibana

Voici une astuce en local pour simuler le vrai nom de domaine (sans cette modification theses-rp ne fonctionnera pas avec la fédération d'identités) :
```
# ajouter ces lignes 
# dans votre fichier /etc/hosts (sous linux - besoin de droits admin)
# ou dans C:\Windows\System32\drivers\etc\hosts (sous windows - besoin de droits admin)
127.0.0.1 apollo-local.theses.fr
```

Une fois ces modifications réalisées, vous pouvez naviguer sur l'URL suivante qui sera en fait équivalent à https://127.0.0.1 :
- https://apollo-local.theses.fr (il faudra accepter l'erreur de sécurité car c'est un certificat autosigné qui est utilisé en standard)


## Installation pour la production

A noter pour la prod: il est nécessaire de [générer des certificats auto-signés](./README-faq.md) pour enregistrer theses.fr comme fournisseur de service dans la fédération d'identités Education-Recherche.


## Démarrage et arret

Pour démarrer l'application :
```bash
cd /opt/pod/theses-docker/
docker-compose up
# ajouter -d si vous souhaitez démarrer l'application en tache de fond
# dans le cas contraire, utilisez CTRL+C pour ensuite quitter l'application
```

Pour arrêter l'application :
```bash
cd /opt/pod/theses-docker/
docker-compose stop
```


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

Les logs de tous les conteneurs de theses-docker sont reversés dans le puits de log de l'Abes. Voici un exemple de ces logs :
![image](https://user-images.githubusercontent.com/328244/179546231-229fa6ba-53bf-4d5a-a5f9-45a4ac17c883.png)


## Déploiement continu

Les objectifs des déploiements continus de theses-docker sont les suivants (cf [poldev](https://github.com/abes-esr/abes-politique-developpement/blob/main/01-Gestion%20du%20code%20source.md#utilisation-des-branches)) :
- git push sur la branche ``develop`` provoque un déploiement automatique sur le serveur ``diplotaxis2-dev``
- git push (le plus couramment merge) sur la branche ``main`` provoque un déploiement automatique sur le serveur ``diplotaxis2-test``
- git tag X.X.X (associé à une release) sur la branche ``main`` permet un déploiement (non automatique) sur le serveur ``diplotaxis2-prod``

Pour un déploiement continu de theses-docker, il est prévu (non implémenté à la date de juillet 2022), d'utiliser des playbook Ansible branchés sur les webhook des Github Action pour pouvoir savoir quand déployer quoi.

En attendant la mise en place d'Ansible pour theses-docker, il a été décidé de déployer automatiquement theses-docker en utilisant l'outil watchtower. Pour permettre ce déploiement automatique avec watchtower, il suffit de lancer le conteneur watchtower de cette manière :
```bash
cd /opt/pod/theses-docker/
docker-compose -f docker-compose.watchtower.yml up -d
```

Le fonctionnement de watchtower est de surveiller régulièrement l'éventuelle présence d'une nouvelle image docker de ``theses-front`` et ``theses-...``, si oui, de récupérer l'image en question, de stopper le ou les les vieux conteneurs et de créer le ou les conteneurs correspondants en réutilisant les mêmes paramètres que ceux des vieux conteneurs. Pour le développeur, il lui suffit de faire un git commit+push par exemple sur la branche ``develop`` d'attendre que la github action build et publie l'image, puis que watchtower prenne la main pour que la modification soit disponible sur l'environnement cible, par exemple sur la machine ``diplotaxis2-dev``.


## Configuration avancées

Pour configurer l'application, il est nécessaire de créer un fichier ``.env`` au même niveau que le fichier ``docker-compose.yml`` de ce dépôt. Le contenu du ``.env`` est une liste de paramètres (clés/valeurs) dont la documentation et des exemples de valeurs sont présents dans le fichier [``.env-dist``](https://github.com/abes-esr/theses-docker/blob/develop/.env-dist).

TODO : expliquer comment configurer les certificats SSL nécessaires à la fédé de ``theses-rp`` pour la production (à placer dans un volume monté sur ``theses-rp``)

Pour créer une URL publique de theses.fr il est nécessaire de configurer une entrée DNS et un reverse proxy (à l'Abes nous utilisons Apache). Voici un extrait de cette configuration apache (à adapter en fonction des environnements) :
```apache
# redirection automatique http vers https
<VirtualHost *:80>
        ServerName apollo-test.theses.fr
        ServerAdmin admin@theses.fr
        RewriteEngine On
        RewriteCond %{HTTPS} !=on
        RewriteRule ^/(.*|$) https://%{HTTP_HOST}/$1 [L,R]
</VirtualHost>

<VirtualHost *:443>
        ServerName apollo-test.theses.fr
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
        # et dans cet exemple qui est hébergé sur le serveur diplotaxis2-test
        ProxyPreserveHost On
        ProxyPass "/" "https://diplotaxis2-test.v202.abes.fr:10300/"
        ProxyPassReverse "/" "https://diplotaxis2-test.v202.abes.fr:10300/"
</VirtualHost>
```

## Mise à jour de l'application

Il est possible de mettre à jour les images docker utilisées par ``theses-docker`` en passant par les variables suivantes dans le ``.env`` :
- ...

Une fois les versions modifiées dans le .env, il suffit de relancer l'application theses.fr comme ceci :
```bash
cd /opt/pod/theses-docker/
docker-compose pull # facultatif car le "docker-compose up" va faire le téléchargement si besoin
docker-compose up -d
```

Pour ``theses-rp`` il n'est pas prévu une mise à jour externalisée en passant par le ``.env`` car ce module n'est pas sensé être mis à jour. Si le besoin de mise à jour se présente, cela signifierait qu'une nouvelle version de https://github.com/abes-esr/docker-shibboleth-renater-sp serait diponible. On peut alors mettre à jour ``theses-rp`` en spécifiant le nouveau numéro de version dans le ``docker-compose.yml`` [à la ligne qui pointe vers l'image docker ``abesesr/docker-shibboleth-renater-sp:x.x.x``](https://github.com/abes-esr/theses-docker/blob/develop/docker-compose.yml#L15). Ensuite il faut adapter les éventuels nouveaux paramètres attendus par la nouvelle version de l'image ``abesesr/docker-shibboleth-renater-sp:x.x.x`` et relancer l'application theses.fr comme ceci :
```bash
cd /opt/pod/theses-docker/
docker-compose pull # facultatif car le "docker-compose up" va faire le téléchargement si besoin
docker-compose up -d
```

## Sauvegardes et restauration

Pour sauvegarder l'application, il faut :
- Sauvegarder la base de données (base Oracle sur les serveurs orpin) : todo préciser de quel schéma et de quelles tables on parle
- Sauvegarder le fichier ``/opt/pod/theses-docker/.env`` qui est un fichier non versionné et qui permet de configurer tous les conteneurs docker de l'appli
- Sauvegarder les certificats auto-signés présents dans le répertoire ``/opt/pod/theses-docker/volumes/theses-rp/shibboleth/ssl/`` (ces certificats permettent à theses.fr d'être reconnu par la fédération d'identités Education-Recherche)
- Sauvegarder le dump elasticsearch : todo vraiement nécessaire ? et todo expliquer comment faire ?
- Sauvegarder le paramétrage kibana : todo vraiement nécessaire ? et todo expliquer comment faire ?
- Sauvegarder les certificats elasticsearch : todo vraiement nécessaire ? et todo expliquer comment faire ?

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


Les images docker de theses.fr sont générées à partir des codes open sources disponibles ici :
- https://github.com/abes-esr/docker-shibboleth-renater-sp (pour l'authentification avec la fédération d'identités)
- https://github.com/abes-esr/theses-api-diffusion
- https://github.com/abes-esr/theses-api-recherche
- https://github.com/abes-esr/theses-api-indexation
- https://github.com/abes-esr/theses-front
- https://github.com/abes-esr/theses-batch
