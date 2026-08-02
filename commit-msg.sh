#!/bin/sh
echo + exec cog verify --file "$1"
exec cog verify --file "$1"
