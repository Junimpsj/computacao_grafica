#!/bin/sh
# Compila e roda os testes (Linux). Usa o fpc do fpcupdeluxe se existir.
cd "$(dirname "$0")/.." || exit 1
FPC=$HOME/fpcupdeluxe/fpc/bin/x86_64-linux/fpc
[ -x "$FPC" ] || FPC=fpc
mkdir -p testes/lib
$FPC -FUtestes/lib -Fualgo -FEtestes -vewn testes/TestesCG.lpr >/dev/null || exit 1
testes/TestesCG
