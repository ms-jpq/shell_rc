#!/usr/bin/env bash

#################### ########### ####################
#################### Node Region ####################
#################### ########### ####################

export NPM_GLOBAL_HOME="$XDG_DATA_HOME/npm_global"
pathprepend "$NPM_GLOBAL_HOME/node_modules/.bin"
