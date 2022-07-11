# FAQ theses-docker

## Comment régler vm.max_map_count pour Elasticsearch ?

Le réglage de ``vm.max_map_count`` est nécessaire pour que [ElasticSearch puisse fonctionner](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html) 

Sans ce réglage vous obtiendrez l'erreur suivante au démarrage :
```
theses-elasticsearch-es01        | bootstrap check failure [1] of [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
theses-elasticsearch-es01        | ERROR: Elasticsearch did not exit normally - check the logs at /usr/share/elasticsearch/logs/theses-cluster.log
```


### Régler vm.max_map_count sur un serveur linux classique

```
  echo "vm.max_map_count = 262144" > /etc/sysctl.d/99-elasticsearch.conf
  sysctl -w vm.max_map_count=262144
```

### Régler vm.max_map_count dans un environnement WSL2 sous Windows 10

Pré-requis : WSL2 + Docker Desktop doivent être installés sur votre machine.

1) lancer un terminal PowerShell  
   ![image](https://user-images.githubusercontent.com/328244/178310894-f93c76bc-a85f-45e9-97ab-d5256bc3166b.png)

2) Editer le profil PowerShell par défaut de l'utilisateur courant, tapez :
   ```
   notepad $PROFILE
   ```  
3) Entrez la commande suivante dans le profil PowerShell et sauver puis fermer le fichier :
   ```
   wsl -d docker-desktop sh -c "sysctl -w vm.max_map_count=262147"
   ```  
   ![image](https://user-images.githubusercontent.com/328244/178311027-9f83e6b1-d48e-4442-94c3-7724e2974e45.png)
   
4) Lancer un nouveau terminal PowerSell, vous devriez voir s'afficher "vm.max_map_count = 262147" au démarrage du terminal ce qui montre que la commande a été executée.  
   ![image](https://user-images.githubusercontent.com/328244/178311186-4b2422b2-ebd6-4b20-98c7-6c42250cdb34.png)

5) Lancer une distribution Linux WSL et constatez que la valeur est bien réglée en tapant :
   ```
   sysctl vm.max_map_count
   ```
   ![image](https://user-images.githubusercontent.com/328244/178311271-c160df19-1af3-41ce-bc7a-681af9e81185.png)
