#!/bin/bash

# Shutdown installation and clean environment 
./actions/prepare-environment.sh || exit 1
./actions/stop-previous-installation.sh || exit 1
