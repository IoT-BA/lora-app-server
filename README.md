## LoRa App Server
Docker image of [lora-app-server](https://github.com/brocaar/lora-app-server). LoRa App Server is an open-source LoRaWAN application-server, compatible with [LoRa Server](https://github.com/brocaar/loraserver).
All configurable parameters are set through enviroment variables in docker-compose.yml, more info can be found in [lora-app-server docs](https://docs.loraserver.io/lora-app-server/)

### Build image
    sudo docker build -t iotba/lora-app-server .
