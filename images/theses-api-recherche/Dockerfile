# Cette image est utile uniquement le temps que la version java soit en place
# Elle permet de faire le passe plat avec elasticsearch en
# - positionnant des CORS très ouverts
# - ignorant le certificat auto-signé d'elasticsearch
# - embarquant l'authentification elasticsearch automatique (à voir si on peut paramétrer ES en mode lecture seule pour éviter ceci) 
# Dans le but de pouvoir travailler sur theses-front sans attendre d'avoir 
# un theses-api-recherche fonctionnel en java
#
FROM httpd:2.4.54

RUN apt-get update \
  && apt-get -y install apache2 \
  && apt-get clean \
  && apt-get -y autoremove

RUN sed -i \
  -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
  -e '/LoadModule proxy_module/s/^#//g' \
  -e '/LoadModule proxy_http_module/s/^#//g' \
  -e '/LoadModule rewrite_module/s/^#//g' \
  -e '/LoadModule headers_module/s/^#//g' \
  -e '/httpd-vhosts.conf/s/^#//g' \
  /usr/local/apache2/conf/httpd.conf
COPY ./httpd-vhosts.conf /usr/local/apache2/conf/extra/httpd-vhosts.conf

# redirect apache logs to docker stdout/stderr
RUN ln -sf /proc/1/fd/1 /var/log/apache2/access.log
RUN ln -sf /proc/1/fd/2 /var/log/apache2/error.log

# creates the entrypoint of this container
COPY ./httpd-foreground /usr/local/bin/
CMD [ "httpd-foreground" ]
