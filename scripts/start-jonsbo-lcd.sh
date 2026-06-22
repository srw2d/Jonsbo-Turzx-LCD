#!/usr/bin/env bash
# Start the Jonsbo / TURZX LCD via turing-smart-screen-python.
# Adjust the paths below if you cloned the project somewhere else.

cd /home/dokuro/Downloads/turing-smart-screen-python || exit 1
exec /home/dokuro/Downloads/turing-smart-screen-python/.venv/bin/python \
     /home/dokuro/Downloads/turing-smart-screen-python/main.py
