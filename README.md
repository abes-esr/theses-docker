# theses-docker

Configuration docker pour déployer theses.fr (travail en cours de refonte de theses.fr)


## Architecture

- theses-rp : conteneur servant de reverse proxy dédié à l'authentification des utilisateurs (sur la fédération d'identités RENATER) souhaitant accéder à des thèses en accès restreint.
- theses-web : conteneur chargé de l'API (en Java Spring) de theses.fr (travail en cours)
- theses-front : conteneur chargé du front (en VueJS) de theses.fr (travail en cours)
- TODO compléter


