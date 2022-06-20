#!/usr/bin/env bash

(trap 'kill 0' SIGINT; watchexec -- gleam run & (cd assets && npm run watch))
