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

# TODO: logguer les header HTTP retournés par la fédé RENATER


# RUN sed -i \
# 		-e 's/^#\(Include .*httpd-ssl.conf\)/\1/' \
# 		-e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
# 		-e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
# 		conf/httpd.conf
