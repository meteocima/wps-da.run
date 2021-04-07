#!/bin/bash

DEPS=/BUILD/deps/out;
PATH+=:/opt/intel/oneapi/lib/intel64/bin
export LD_LIBRARY_PATH=$DEPS/lib:/opt/intel/oneapi/lib/intel64:/opt/intel/oneapi/lib/intel64/libfabric

# This command execute WPS to pre-process data needed
# by the various workflow at LEXIS.
#
# It require three arguments, specified as environment variables
# or otherwise as command line arguments. when specified as command line arguments,
# the order of them should be WPS_START_DATE WPS_END_DATE WPS_MODE
#
# Arguments:
#
# - WPS_START_DATE: initial date/time of the simulation, in format YYYYMMDDHHNN
# - WPS_END_DATE: final date/time of the simulation, in format YYYYMMDDHHNN
# - WPS_MODE: kind of simulation to preprocess. accepts these values: 'WARMUP' 'WRF' 'WRFDA'
#   * WRF mode - preprocess the data needed to run a WRF simulation without data assimilation.
#               It's actually used by Continuum and numtech simulation.
#   * WRFDA mode - preprocess the data needed to run a WRFDA simulation with data assimilation.
#               It includes inthe preprocessed data instant WPS_START_DATE-3HOUR and WPS_START_DATE-6HOUR, that are
#               used during data assimilation. It will be used by Continuum and numtech simulations when
#               data assimilation will be used.
#   * WARMUP mode - preprocess the data needed to run three WRF simulation, without data assimilation.
#               Two of this WPS execution preprocess the data to run two WRF simulation for days WPS_START_DATE-1 and WPS_START_DATE-2.
#               These two set of data are the "warmup" data.
#               The other WPS execution prepares the normal WRF simulation from $WPS_START_DATE to $WPS_END_DATE
#               Warmup data it's actually used by Risico simulation.
#   * WARMUPDA mode - preprocess the data needed to run three WRF simulation, with data assimilation.
#               Two of this WPS execution preprocess the data to run two WRF simulation (with no assimilation) for days WPS_START_DATE-1
#               and WPS_START_DATE-2.
#               These two set of data are the "warmup" data.
#               The other WPS execution prepares the normal WRF simulation (with assimilation) from $WPS_START_DATE to $WPS_END_DATE
#               Warmup data it's actually used by Risico simulation.

# read arguments from command line
# or from environment.
if [ "$#" -eq 4 ]; then
  export wps_start=$1
  export wps_end=$2
  export wps_mode=$3
  export wps_input=$4
else
  export wps_start=$WPS_START_DATE
  export wps_end=$WPS_END_DATE
  export wps_mode=$WPS_MODE
  export wps_input=$WPS_INPUT
fi


# check wps_input validity
if [[ $wps_input != "GFS" && $wps_input != "IFS" ]]; then
    echo "WPS_INPUT argument must be IFS or GFS"
    exit 1
fi

# check wps_mode validity
if [[ $wps_mode != 'WARMUPDA' && $wps_mode != 'WRFDA' && $wps_mode != 'WARMUP'  && $wps_mode != 'WRF' ]]; then
    echo WPS_MODE argument must be one of these values: WARMUP, WRF, WARMUPDA, WRFDA
    exit 1
fi


# check input and environment validity
if [ ! -d /input ]; then
    echo "This container expect a volume mounted on /input containing input grib files"
    exit 1
fi

if [ ! -d /geogrid ]; then
    echo "This container expect a volume mounted on /geogrid containing geogrid static data files"
    exit 1
fi

if [ -z "$(ls -A /output)" ]; then
   echo;
else
   echo "This container expect a volume mounted on /output that must be empty"
   exit 1
fi

# stop on first error
set -e


# number of processor cores availables
export cores=`nproc`


# run_wps prepares the environment to run
# WPS processes for a range of hours specified
# and then run them.
# the function requires in input start and end
# of the date range to run, in format YYYYMMDDHH
# the function search input files in folder /input/<startdate>
# and save output in folder /output/<startdate>
function run_wps() {
  start=$1
  end=$2
  mode=$3

  ./wrfda-runner -outargs arguments.txt -i $wps_input -p WPS . $start $end

  # publish output files
  cp -vr /wpswd/inputs/* /output/
  cp -v arguments.txt /output/
}

function dateadd() {
  dt=$1
  amount=$2
  date -u '+%Y%m%d%H' -d "${dt:0:4}-${dt:4:2}-${dt:6:2} ${dt:8:2}:00 UTC ${amount}"
}



if [[ $wps_mode == 'WARMUP' ]]; then
  echo "PREPROCESS DATA FOR A WRF SIMULATION WITH WARMUP DATA"

  # include warmup data
  warmup1_start=`dateadd ${wps_start} "-2 day"`
  warmup2_start=`dateadd ${wps_start} "-1 day"`
  wrfrun_start=${wps_start}

  warmup1_end=$warmup2_start
  warmup2_end=$wrfrun_start
  wrfrun_end=$wps_end

  run_wps $warmup1_start $warmup1_end OL
  run_wps $warmup2_start $warmup2_end OL
  run_wps $wrfrun_start $wrfrun_end OL
  exit 0
fi

if [[ $wps_mode == 'WRF' ]]; then
  echo "PREPROCESS DATA FOR A WRF SIMULATION"
  run_wps $wps_start $wps_end OL
  exit 0
fi

if [[ $wps_mode == 'WRFDA' ]]; then
  echo "PREPROCESS DATA FOR A WRFDA SIMULATION"
  run_wps $wps_start $wps_end DA
  exit 0
fi

if [[ $wps_mode == 'WARMUPDA' ]]; then
  echo "PREPROCESS DATA FOR A WRFDA SIMULATION WITH WARMUP DATA"
  # include warmup data
  warmup1_start=`dateadd ${wps_start} "-2 day"`
  warmup2_start=`dateadd ${wps_start} "-1 day"`
  wrfrun_start=${wps_start}

  warmup1_end=$warmup2_start
  warmup2_end=$wrfrun_start
  wrfrun_end=$wps_end

  run_wps $warmup1_start $warmup1_end DA
  run_wps $warmup2_start $warmup2_end DA
  run_wps $wrfrun_start $wrfrun_end DA
  exit 0
fi


