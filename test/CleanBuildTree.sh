#!/bin/sh
ROOTDIR=$(dirname $0)/..
rm -r $ROOTDIR/build
[ ! -d "$ROOTDIR/build/fob/cmake/retrievers" ] && mkdir -p $ROOTDIR/build/fob/cmake/retrievers
ln $ROOTDIR/cmake/*.cmake build/fob/cmake/
ln $ROOTDIR/cmake/retrievers/*.cmake build/fob/cmake/retrievers/
for ModuleName in "$@"
do
    [ ! -d "$ROOTDIR/build/fob/ExtProj/$ModuleName/build/fob/compatibility" ] && mkdir -p $ROOTDIR/build/fob/ExtProj/$ModuleName/build/fob/compatibility
    ln $ROOTDIR/compatibility/Generic.in.cmake $ROOTDIR/compatibility/$ModuleName.in.cmake $ROOTDIR/build/fob/ExtProj/$ModuleName/build/fob/compatibility
done
