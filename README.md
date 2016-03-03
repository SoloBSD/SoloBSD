SoloBSD
=========

Copyright (c) 2015-2016 Guillermo García Rojas C. <garciarojas at gmail.com>

## Description

This is a set of scripts that generates a bootable image, ISO file or boot 
files only, that create a working minimal installation of HardenedBSD. This
minimal installation gets completely loaded into memory.

The image may be written directly using dd(1) onto any bootable block device,
e.g. a hard disk or a USB stick e.g. /dev/da0, or a bootable slice only, 
e.g. /dev/ada0s1

## Build-time requirements
 - HardenedBSD 10 or higher installed, tested on amd64
 - Base and kernel from a HardendedBSD 10 or higher distribution
   (release or snapshots, e.g mounted CDROM disc1 or ISO file)

## Runtime requirements
 - a minimum of 512MB system memory

## Other information

See BUILD and INSTALL files for building and installation instructions.

This project is based on the ideas of the mfsbsd project:
http://mfsbsd.vx.sk