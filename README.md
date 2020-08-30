# busybox chown

In Kubernetes deployments one often needs to adjust the UNIX permissions of a persistent volume, so that a container that runs without root permission can write into it. This usually handled as an init container that runs once, before the actual service container gets launched. Using a fully populated userland from a Linux distibution or even just busybox instead of the single binary that is really needed for this seems wasteful and can slow the initialization of your deployment.

This image contains a busybox binary that provides just the chown function, making it tiny 51 KiB, more secure and fast.

## Running the image

Assuming you have docker installed and internet access, you can fetch and run the image from the docker hub like this:

```shell
docker run -t --rm --read-only -v $PWD/some-volume:/mnt privatebin/chown 65534:65534 /mnt
```

The parameters in detail:

- `-v $PWD/some-volume:/mnt` - Replace `$PWD/some-volume` with the path to the folder on your system, that you want to change ownership of.
- `-t` - Returns the STDOUT/STDERR of the chown command.
- `--rm` - Remove the container after usage.
- `--read-only` - This image supports running in read-only mode. Using this reduces the attack surface slightly, since an exploit can't overwrite arbitrary files in the container. Only the attached volumens may be written into.

### Kubernetes deployment

Below is an example deployment for Kubernetes, making use of this image as an init container.

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-deployment
  labels:
    app: example
spec:
  replicas: 3
  selector:
    matchLabels:
      app: example
  template:
    metadata:
      labels:
        app: example
    spec:
      initContainers:
      - name: example-volume-permissions
        image: privatebin/chown
        command: ['65534:65534', '/mnt']
        securityContext:
          runAsUser: 0
          readOnlyRootFilesystem: True
        volumeMounts:
        - mountPath: /mnt
          name: example-data
          readOnly: False
      containers:
      - name: your-application
        image: [...]
        securityContext:
          runAsUser: 65534
          runAsGroup: 65534
          readOnlyRootFilesystem: True
        volumeMounts:
        - mountPath: /srv/data
          name: example-data
          readOnly: False
```

## Rolling your own image

To reproduce the image, run:

```bash
docker build -t privatebin/chown .
```
