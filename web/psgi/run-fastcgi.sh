#!/bin/bash
plackup -s FCGI -E deployment --listen :4003 --nproc 11 ./app.psgi
