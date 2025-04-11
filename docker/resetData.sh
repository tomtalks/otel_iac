#!/bin/bash

docker compose rm -s -v -f 

docker volume rm docker_grafana_data docker_pg_data docker_tempo_data 