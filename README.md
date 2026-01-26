# investigatingGravityTrends
This repository contains the original code developed for the research presented in: 
Investigating gravity trends of Martian mantle dynamics from realistic simulated satellite orbits. (Alkahal, et al., 2026)
The repository only includes code written by the author. All third-party software must be obtained separately and clearly cited below.
# 1. Overview
The paper discussed two different methodologies and used three main software, TU Delft Astrodynamics Toolbox (TUDAT), FLexible Axisymmetric Planet Solver (FLAPS), and Global Spherical Harmonic package (GSH).
This repository contains the functions that were part of, or used to, running the corresponding software. 
# 2. Software dependencies
## Mandatory
* tudat-bundle
    *  repository: https://github.com/tudat-team/tudat-bundle
    *  branch that belongs to the sub-repository: https://github.com/tudat-team/tudat/tree/feature/mars_dtm
    * Tudat version: 2.14.0.dev18
    * Tested with CMake version: cmake version 3.22.1
    * Tested with GCC compiler 11.4.0
* FLAPS
    * repository: https://github.com/cedrict/flaps
    * Tested with python3 version: Python 3.11.6
* GSH 
    * repository: https://github.com/bartroot/GSH
    * The code runs from Matlab 2016a

# 3. Installing TUDAT
This repository does not include the Tudat source code. 
We recommend installing tudat following the instructions in https://github.com/tudat-team/tudat-bundle
Ensure that the tudat version is 2.14.0.dev18 and checkout to the branch: feature/mars_dtm using:
git checkout feature/mars_dtm
Other Tudat versions may not be compatible with the scripts provided in this repository.

