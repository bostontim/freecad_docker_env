This is a docker container intended to act as a build and run environment for
FreeCAD within a Debian docker container, because I am too lazy to track down
the Solus OS `eopkg` packages for FreeCAD's buildtime dependencies.

The directories containing FreeCAD's source code and build, are not included
inside the docker image. Instead, they are attached to the docker container
when you run the container. This allows the built code to have continuity
across different docker containers, reducing the time for a build to occur.

# Build docker image

```
docker build -t freecad_env .
```

# Run docker image

Please keep in mind, to get permission to access your host's xserver from
inside the Docker container, we use the `xhost +` command. This is very
insecure, but simple. If you'd prefer to use a more secure way to give
permissions, you can find [further examples
here](https://wiki.ros.org/docker/Tutorials/GUI). 

```
xhost +
fc_source=~/code/freecad_source
fc_build=~/code/freecad_build

docker run -it \
-v $fc_source:/mnt/source -v $fc_build:/mnt/build \
-e "DISPLAY" -e "QT_X11_NO_MITSHM=1" -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
freecad_env
```

# Run build script

```
/root/build_script.sh
```

# Run FreeCAD
```
FreeCAD
```
