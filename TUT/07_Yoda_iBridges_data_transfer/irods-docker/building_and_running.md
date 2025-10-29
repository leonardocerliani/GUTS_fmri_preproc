

## Build the Docker image. 
```bash
# docker rmi yoda-irods
docker build -t yoda-irods .
```

## Run the container and mount the local volumes inside it.

```bash
docker run -it \
  --name yoda \
  -v $(pwd)/.irods:/root/.irods \
  -v $(pwd)/data:/data \
  --network host \
  yoda-irods /bin/bash
```

## For the next times:
```bash
# docker rm yoda
docker start -ai yoda
```