#!/bin/sh
# Uso: ./build.sh linux | win64
cd "$(dirname "$0")" || exit 1
LAZ=$HOME/fpcupdeluxe/lazarus
case "$1" in
  linux) BM=Linux ;;
  win64) BM=Windows64 ;;
  *) echo "uso: $0 linux|win64"; exit 1 ;;
esac
$LAZ/lazbuild --primary-config-path=$HOME/fpcupdeluxe/config_lazarus --bm=$BM CG.lpi
