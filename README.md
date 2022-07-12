# theses-docker

(travail en cours)

Configuration docker 🐳 pour déployer le portail national des thèses dont le but est de donner accès à toutes les theses de theses.fr à l'ensemble de l'enseignement supérieur et recherche. Ces configurations visent à permettre un déploiement uniforme en local sur la machine d'un développeur, et sur les serveurs de dev, test, et prod.

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
- https://127.0.0.1:10300 : pour theses-rp en https (il faudra accepter l'erreur de sécurité car c'est un certificat autosigné qui est utilisé en standard)
- http://127.0.0.1:10301 : pour theses-rp en http 
- https://127.0.0.1:10302 : pour theses-elasticsearch-es01 en https (attention il faut utiliser le user 'elastic' avec le mot de passe correspondant réglé dans ``.env`` et il faudra ignorer l'erreur de certificat HTTPS car lui aussi est auto-signé)
- http://127.0.0.1:10303 : pour theses-kibana

Voici une astuce en local pour simuler le vrai nom de domaine (sans cette modification theses-rp ne fonctionnera pas avec la fédération d'identités) :
```
# ajouter ces lignes 
# dans votre fichier /etc/hosts (sous linux - besoin de droits admin)
# ou dans C:\Windows\System32\drivers\etc\hosts (sous windows - besoin de droits admin)
127.0.0.1 apollo-dev.theses.fr
127.0.0.1 apollo-test.theses.fr
127.0.0.1 apollo-prod.theses.fr
```

Une fois ces modifications réalisées, vous pouvez naviguer sur l'URL suivante qui sera en fait équivalent à https://127.0.0.1 (adapter le -dev en -test ou -prod en fonction de votre paramétrage dans le .env) :
- https://apollo-dev.theses.fr (il faudra accepter l'erreur de sécurité car c'est un certificat autosigné qui est utilisé en standard)

Pour installer theses.fr avec un cluster elasticsearch de plusieurs noeuds, il faut se référer à la [documentation dédiée ici](README-cluster-es.md).

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

## Configuration avancées

Pour configurer l'application, il est nécessaire de créer un fichier ``.env`` au même niveau que le fichier ``docker-compose.yml`` de ce dépôt. Le contenu du ``.env`` est une liste de paramètres (clés/valeurs) dont la documentation et des exemples de valeurs sont présent dans le fichier [``.env-dist``](https://github.com/abes-esr/theses-docker/blob/develop/.env-dist).

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


