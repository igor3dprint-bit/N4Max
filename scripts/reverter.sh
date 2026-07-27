#!/bin/bash
# Volta a impressora para o Klipper original de fabrica.
set -e

SENHA="${SENHA:-makerbase}"
SU() { echo "$SENHA" | sudo -S "$@" 2>/dev/null; }

echo "=========================================================="
echo "  VOLTANDO PARA O KLIPPER ORIGINAL"
echo "=========================================================="
echo

SU true || { echo "!! Senha errada. Abortando."; exit 1; }

BKP=$(ls -d ~/klipper.stock.v* 2>/dev/null | head -1)
if [ -z "$BKP" ]; then
    echo "!! Nao encontrei a copia de seguranca do Klipper original."
    echo "   Sem ela nao da para reverter automaticamente."
    exit 1
fi
FW=$(basename "$BKP" | sed 's/klipper.stock.v//')
echo "Restaurando o firmware original $FW"
echo

echo "[1/5] Parando servicos..."
SU systemctl stop klipper || true
SU systemctl stop klipper_mcu || true
SU systemctl stop makerbase-client || true

echo "[2/5] Restaurando o arquivo de configuracao..."
if [ -f ~/klipper_config/printer.cfg.stock.v$FW ]; then
    mv ~/klipper_config/printer.cfg ~/klipper_config/printer.cfg.novo.$(date -I) 2>/dev/null || true
    cp ~/klipper_config/printer.cfg.stock.v$FW ~/klipper_config/printer.cfg
else
    echo "  (sem backup do printer.cfg, mantendo o atual)"
fi

echo "[3/5] Restaurando o Klipper original..."
[ -L ~/klipper ] && rm ~/klipper
mv "$BKP" ~/klipper

echo "[4/5] Restaurando o programa do MCU..."
[ -L /usr/local/bin/klipper_mcu ] && SU rm /usr/local/bin/klipper_mcu
if [ -f /usr/local/bin/klipper_mcu.stock.v$FW ]; then
    SU mv /usr/local/bin/klipper_mcu.stock.v$FW /usr/local/bin/klipper_mcu
fi
SU rm -f /usr/local/bin/klipper_mcu.sandmmakers

echo "[5/5] Reiniciando..."
echo
echo "Obs: a pasta ~/klipper.sandmmakers foi mantida, caso queira reinstalar."
echo "     Se quiser liberar espaco, apague ela depois."
echo
SU reboot now || true
exit 0
