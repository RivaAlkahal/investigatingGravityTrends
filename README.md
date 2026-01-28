# investigatingGravityTrends
This repository contains the original code developed for the research presented in: 
Investigating gravity trends of Martian mantle dynamics from realistic simulated satellite orbits. (Alkahal, et al., 2026)
The repository includes scripts that are written by the author. Third-party software must be obtained separately and clearly cited below.
# 1. Overview
The paper discussed two different methodologies and used three main software, TU Delft Astrodynamics Toolbox (TUDAT), FLexible Axisymmetric Planet Solver (FLAPS), and Global Spherical Harmonic package (GSH).
This repository contains the functions that were part of, or used to, running the corresponding software. 
# 2. Software dependencies
### tudat
 This repository relies on a forked version of Tudat that contains only the minimal modifications required for the paper
- The fork is included as a Git submodule under:  
    `external/tudat-forked/tudat`
- The submodule points to a fixed commit corresponding to the version used in the paper.
- A tag (vPaper-1.0) is provided in the Tudat fork to identify the exact version.
- Tested with CMake version: cmake version 3.22.1
- Tested with GCC compiler 11.4.0

To clone the repository with the correct Tudat version, use:
```bash 
git clone --recurse-submodules https://github.com/RivaAlkahal/investigatingGravityTrends.git
```
If you already cloned without submodules write:
```bash
git submodule update --init --recursive
```  

Note: The Tudat code itself is not developed here. For general installation instructions, refer to the official Tudat documentation in https://github.com/tudat-team/tudat-bundle
for further details, see below.
### FLAPS
This repository relies on a forked version of FLAPS that contains only the minimal modifications required for the paper
- The fork is included as a Git submodule under:  
    `external/flaps-forked/flaps`
- The `git clone` message above does include the referred flaps version.

- Original repository: https://github.com/cedrict/flaps
- Tested with python3 version: Python 3.11.6
### GSH 
- repository: https://github.com/bartroot/GSH
- The code runs from Matlab 2016a

# 3. Running the Tudat simulations
## Link to tudat-bundle
As indicated above, we include a direct link to the forked repository of the tudat source code. 
To build tudat the correct way, after cloning this repository with the instructions above, go to the directory of the repository
```bash
cd investigatingGravityTrends
cd external/tudat-forked/tudat
git checkout vPaper-1.0
```
This ensures landing to the same branch as the functions useful for this paper are available.
### Clone the correct tudat-bundle version
In the terminal (outside the directory of this repo) write:
 ```bash
 git clone https://github.com/tudat-team/tudat-bundle.git
 cd tudat-bundle
 git submodule update --init --recursive
 ```
Since the functions developed to run the simulations on tudat developed at a specific tudat-bundle commit, the user is advised to checkout to that commit with:
 ```bash 
 git checkout 9d349ad9d349adfb4295d99f51e2a5c56d6d094648732e3
 ```
### Add required external dependency (nlohmann/json)
The paper-specific tudat functions rely on the nlohmann/json library to read arc configurations, therefore from the root of tudat-bundle:
```bash
cd external
git submodule add https://github.com/nlohmann/json.git
git submodule update --init --recursive
```
The code was tested with the commit: e00484f8 therefore:
```bash 
cd json
git checkout e00484f8
```
### Replace Tudat inside the tudat-bundle with the paper fork
Next, inside the tudat-bundle folder, replace the original tudat/ folder with the tudat provided with this repo:
```bash
cp -r /path/to/investigatingGravityTrends/external/tudat-forked/tudat ./tudat
```

### Build tudat-bundle
From the root of tudat-bundle:
```bash
-DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build . -j4
```
Run the build.sh script
```bash
bash build.sh
```

## Run the paper scripts
The functions that are relevant to reproduce the results in the paper live under:

   `external/tudat-forked/tudat/tests_riva`

Therefore, after building tudat, ensure that these scripts are compiled in ```path/to/tudat-bundle/build/tudat/bin```:
```bash
computeCovariance_TestMultiSat
computeCovariances_ForEmps
computeCovariances_test_skipping
computeCovariances
generate_configs
generate_configs_VO1
parallelArcProcess
parallelArcProcessEmpiricals
parallelArcProcessMultiSat
parallelArcProcessVikings
```
#### Generate arc configurations
The compiled ```generate_configs(*)``` need to be run, inside the functions, line 31 change the configDir to the desired directory, then run:
```bash 
./generate_configs #for the period from J2000 0.0 epoch to +50 years later
./generate_configs_VO1 #for the Viking Orbiter 1 time-span 
```
### Running the simulations
After compiling the functions, to run the desired simulations go to the directory of the repo:
```bash
cd path/to/investigatingGravityTrends
cd run-tudat
```
the following bash functions should be used for the respective settings:
#### MGS-only case
To run the simulations and obtain arc-wise results as well as the covariance matrix of the combined arcs of the MGS-only case:
```bash
./runArcs_MGSOnly.sh 
```
##### Note: the following lines should be modified with the links to their corresponding directories:
```bash
CONFIG_DIR="path/to/configs"                 # where config_arc_*.json live
BASE_OUTPUT="path/to/output_test_MGSOnly"     # base dir for per-arc outputs
EXEC_RUN_ARC="path/to/build/tudat/bin/parallelArcProcess"      # <<< compiled single-arc executable
EXEC_COMBINE="path/to/build/tudat/bin/computeCovariance_test_skipping"  # <<< compiled combiner
```

#### Viking orbiter 1 case
To run the simulations and obtain arc-wise results as well as the covariance matrix of the combined arcs of the VO1-only case:
```bash
./runArcs_selectedVikings.sh 
```
##### Note: the following lines should be modified with the links to their corresponding directories:
```bash
CONFIG_DIR="path/to/configs_test"                 # where config_arc_*.json live
BASE_OUTPUT="path/to/output_test_Vikings"     # base dir for per-arc outputs
EXEC_RUN_ARC="path/to/build/tudat/bin/parallelArcProcessVikings"      # <<< compiled single-arc executable
EXEC_COMBINE="path/to/build/tudat/bin/computeCovariances_test_skipping"  # <<< compiled combiner
```
#### Empirical accelerations (MGS-only) case:
To run the simulations and obtain arc-wise results as well as the covariance matrix of the combined arcs of the empirical accelerations case:
```bash
./runArcs_Emps.sh 
```
##### Note: the following lines should be modified with the links to their corresponding directories:
```bash
CONFIG_DIR="path/to/configs"                 # where config_arc_*.json live
BASE_OUTPUT="path/to/output_test_MGSOnlyEmpiricals"     # base dir for per-arc outputs
EXEC_RUN_ARC="path/to/build/tudat/bin/parallelArcProcessEmpiricals"      # <<< compiled single-arc executable
EXEC_COMBINE="path/to/build/tudat/bin/computeCovariances_ForEmps"  # <<< compiled combiner
```
#### Multi-satellite case:
To run the simulations and obtain arc-wise results *without* the combined-arcs covariance matrix of the multi-satellite case:
```bash
./runArcs_MultiSats.sh
```
##### Note: the following lines should be modified with the links to their corresponding directories:
```bash
CONFIG_DIR="path/to/configs"                 # where config_arc_*.json live
BASE_OUTPUT="path/to/output_test_MultiSats"     # base dir for per-arc outputs
EXEC_RUN_ARC="path/to/build/tudat/bin/parallelArcProcessMultiSat"      # <<< compiled single-arc executable
```
In order to obtain the covariance matrix of all the arcs of the multi-satellite case (and if desired, the other cases), first merge the results of (different) simulation settings into one single directory (e.g. VO1 + multi-satellite) this is done after generating the arcs with runArcs functions, then:
```bash
./mergeFiles.sh 
```
##### Note: the following lines should be modified with the links to their corresponding directories, for example:
```bash
SRC1="path/to/output_test_MultiSats"
SRC2="path/to/output_test_Vikings"
DEST="/path/to/merged_6_12"
```
##### Note: make sure that these lines are not commented at the end of the script, and for example comment SRC2 if only SRC1 is needed
```bash 
add_set_range_take_skip "$SRC1" "$OFF1" "$SRC_START1" "$SRC_END1" "$TAKE1" "$SKIP1"
add_set_range_take_skip "$SRC2" "$OFF2" "$SRC_START2" "$SRC_END2" "$TAKE2" "$SKIP2"
```
Finally, to obtain the covariance matrix of all the arcs that are merged:

```
./combineOnly_selected.sh 
```

# 4. Installing and running FLAPS
As mentioned above, this repository does include the forked version of FLAPS with minor modification from the original version. 
To run the runner script go to the directory:
```
cd run-flaps
```
then run the script:
```
./script_MarsModelViscosityRun
```
##### Note: make sure to modify the link to flaps.py function in:
```
SCRIPT_DIR="path/to/flaps"
```
The user is free to modify the settings in the runner script to the desired viscosity and density model, as well as, the number of elements. The settings in their current form include the viscosity profiles used for the results of the paper, with the settings of depths-related changes of the plume. 

# 5. Installing and running GSH and its relevant functions
This repository does not include the GSH source code. 
The user can install the script by writing in the desired location:
```
git clone https://github.com/bartroot/GSH
```
Following cloning the GSH tools, go to the run-makeRate folder of this repo:
```
cd investigatingGravityTrends/run-makeRate
```
Inside this directory you will find the file MakeRate.m, which transforms the outputs from flaps to the gravity anomaly rate signal (e.g. Figure 5 of the paper). Therefore it is important to provide the directory to the results from flaps, as well as to the GSH tools, in:
```
addpath('path/to/GSH/GSH-main/Tools/')
basedir = "/path/to/flaps/50years_blobetas/";
``` 

# Notes on reproducibility
- Exact commits of tudat-bundle, Tudat, FLAPS, and nlohmann/json are pinned.
- Only paper-relevant modifications are included in the provided forks.

# References
- Tudat project: https://github.com/tudat-team
