FROM debian:bullseye

RUN apt update && apt install -y jq curl

WORKDIR /app
COPY ./theses-sample-data.json /app/
COPY ./theses-sample-mapping.json /app/
COPY ./theses-sample-load.sh /app/
RUN chmod a+x /app/theses-sample-load.sh


