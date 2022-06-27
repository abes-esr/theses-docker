# Cette image est utile uniquement pour les tests du POC fédé
# et sera remplacée à terme par le code java dédié à l'API 
# de diffusion des thèses qui sera hébergée sur https://github.com/abes-esr/theses-api-diffusion/
#
# Elle permet de tester qu'on arrive à bien diffuser en accès restreint
# une thèses PDF en enclenchant de bout en bout le mécanisme de fédération d'identités
# un PDF d'une thèse exemple est embarqué dans cette image,
# il est déposé à la racine du serveur web :
# 74979_GERARDIN_2018_archivage.pdf
#
FROM httpd:2.4.54

# pour éviter l'erreur "Bad Request - The number of request header fields exceeds this server's limit."
# lié au fait que shibboleth envoi de très nombreux header
RUN echo "LimitRequestFieldSize 200000" >> conf/httpd.conf
RUN echo "LimitRequestFields 250" >> conf/httpd.conf

# le PDF d'une these pour les tests
COPY ./74979_GERARDIN_2018_archivage.pdf /usr/local/apache2/htdocs/
# et une page d'accueil
COPY ./index.html /usr/local/apache2/htdocs/
RUN chmod a+rw /usr/local/apache2/htdocs/index.html

# pour logguer les header HTTP retournés par la fédé RENATER
# https://stackoverflow.com/questions/9948064/is-it-possible-to-log-all-http-request-headers-with-apache
# en réaliter les forensic log vont TOUT logguer dans la requête HTTP donc y compris ses header
# voici un extrait de ce à quoi une ligne de log peut ressembler (juste en prenant un attribut de la fédé en exemple)
# on remarque que les attributs clés/valeurs sont séparés par des "|"
# [...]|eppn:etudiant1@test-renater.fr|supannEtablissement:{ILN}1-341725201;{AUTRE}formation.renater.fr|mail:jean.dupont@formation.renater.fr|[...]
RUN sed -i \
		-e 's/^#\(LoadModule .*mod_log_forensic.so\)/\1/' \
		conf/httpd.conf
RUN echo "ForensicLog /proc/self/fd/1" >> conf/httpd.conf
