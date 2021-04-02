# wps-da.run

Docker container that serves as base container for GFS WPS and IFS WPS containers.

This container is based on 
[cimafoundation/deps-deploy](https://hub.docker.com/repository/docker/cimafoundation/deps-deploy) that
provides a prebuilt environment containing WPS 4.1 and WRF 4.1.5 (both built with intel compilers)
and various Intel runtime libraries and dependencies needed to run simulations.

This is the 
parent container of the two that will run
WRF simulation with IFS and GFS inputs: 
[wps-da.ifs](https://github.com/meteocima/wps-da.ifs) 
and [wps-da.gfs](https://github.com/meteocima/wps-da.gfs)

## Repo contents

### wrfda-runner.cfg

Configuration file for wrfda-runner. Contains path of all 
directories used by the simulation.

### wrfda-runner

Binary for wrfda-runner. If needed, it can be rebuilt from
https://github.com/meteocima/wrfda-runner.

Prebuilt binaries should be downloaded from
https://github.com/meteocima/wrfda-runner/releases/latest

You can check the version currently used with `./wrfda-runner -v`.

### common-start.sh

A script that parse arguments and start wrfda-runner
accordingly.