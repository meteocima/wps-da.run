# wps-da.run

Docker container that serves as base container for GFS WPS and IFS WPS containers.

This container is based on [cimafoundation/deps-deploy](https://hub.docker.com/repository/docker/cimafoundation/deps-deploy) that
provides a prebuilt environment containing WPS 4.1 and WRF 4.1.5 (both built with intel compilers)
and various Intel runtime libraries and dependencies needed to run simulations.

* wps-da.run: base container to run WPS (inherited by wps.gfs and wps.ifs)


### Build base wps image

These commands will build the `wps-da.run` image, that
is the command parent of the two containers that will run:
`wps-da.ifs` and `wps-da.gfs`

```bash
cd wps-da.run
docker build .
docker tag <resulting image id> cimafoundation/wps-da.run
```