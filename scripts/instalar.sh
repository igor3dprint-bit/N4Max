#!/bin/bash
# Instala o Klipper da S&M Makers. Precisa da variavel SENHA (senha do usuario mks).
set -e

REPO="https://github.com/sandmmakers/klipper.git"
SENHA="${SENHA:-makerbase}"
SU() { echo "$SENHA" | sudo -S "$@" 2>/dev/null; }

echo "=========================================================="
echo "  INSTALANDO O KLIPPER NOVO"
echo "=========================================================="
echo

# ---------- 0. Checagens de seguranca ----------
if ! SU true; then
    echo "!! A senha da impressora esta errada. Nao posso continuar."
    exit 1
fi

FW=$(grep -rhoE "1\.[0-9]+\.[0-9]+\.[0-9]+" /home/mks/Desktop/myfile/ 2>/dev/null \
     | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
[ -z "$FW" ] && { echo "!! Nao identifiquei o firmware Elegoo. Abortando."; exit 1; }

TAG=$(git ls-remote --tags "$REPO" 2>/dev/null \
      | grep -oE "sandmmakers-ElegooNeptune4Max-v${FW}-[A-Za-z0-9.-]+" \
      | grep -v '\^{}' | sort -t- -k5 -V | tail -1)
[ -z "$TAG" ] && { echo "!! Nenhuma versao compativel com o firmware $FW. Abortando."; exit 1; }

if [ -e /tmp/printer ] && grep -q "printing" <(curl -s http://localhost:7125/printer/objects/query?print_stats 2>/dev/null); then
    echo "!! A impressora parece estar IMPRIMINDO. Espere terminar."
    exit 1
fi

echo "Firmware Elegoo .. $FW"
echo "Versao a instalar. $TAG"
echo

# ---------- 1. Parar servicos ----------
echo "[1/7] Parando os servicos da impressora..."
SU systemctl stop klipper || true
SU systemctl stop klipper_mcu || true
SU systemctl stop makerbase-client || true

# ---------- 2. Backups ----------
echo "[2/7] Fazendo copias de seguranca..."
if [ ! -e ~/klipper_config/printer.cfg.stock.v$FW ]; then
    cp ~/klipper_config/printer.cfg ~/klipper_config/printer.cfg.stock.v$FW
fi
if [ -d ~/klipper ] && [ ! -L ~/klipper ]; then
    mv ~/klipper ~/klipper.stock.v$FW
fi
if [ -f /usr/local/bin/klipper_mcu ] && [ ! -L /usr/local/bin/klipper_mcu ]; then
    SU mv /usr/local/bin/klipper_mcu /usr/local/bin/klipper_mcu.stock.v$FW
fi

# ---------- 3. Ajustar printer.cfg ----------
# O Klipper novo removeu o "max_accel_to_decel". Se ficar no arquivo, nao liga.
echo "[3/7] Ajustando o arquivo de configuracao..."
sed -i "s/^max_accel_to_decel:/#max_accel_to_decel:/" ~/klipper_config/printer.cfg
sed -i "/{% set RUN_DECEL/d" ~/klipper_config/printer.cfg
sed -i "s/ ACCEL_TO_DECEL={RUN_DECEL}//" ~/klipper_config/printer.cfg

# ---------- 4. Baixar o Klipper novo ----------
echo "[4/7] Baixando o Klipper novo (pode demorar alguns minutos)..."
if [ ! -d ~/klipper.sandmmakers/.git ]; then
    rm -rf ~/klipper.sandmmakers
    git clone --quiet "$REPO" ~/klipper.sandmmakers
else
    (cd ~/klipper.sandmmakers && git fetch --quiet --tags)
fi
ln -sfn ~/klipper.sandmmakers ~/klipper
cd ~/klipper
git checkout --quiet "$TAG"

# ---------- 5. Compilar o c_helper ----------
# Tem que apagar antes: se o arquivo nao existir no boot, o programa da tela
# copia uma versao errada por cima e o Klipper nao liga.
echo "[5/7] Compilando parte 1 de 2..."
SU rm -f klippy/chelper/c_helper.so
~/klippy-env/bin/python2 klippy/chelper/__init__.py
~/klippy-env/bin/python2 -m compileall klippy >/dev/null 2>&1 || true

# ---------- 6. Compilar o MCU Linux ----------
echo "[6/7] Compilando parte 2 de 2 (a mais demorada)..."
make clean >/dev/null 2>&1
echo "CONFIG_MACH_LINUX=y" > .config
make olddefconfig >/dev/null 2>&1
grep -q '^CONFIG_MACH_LINUX=y' .config || { echo "!! Configuracao falhou. Abortando."; exit 1; }
make clean >/dev/null 2>&1
make >/dev/null 2>&1
[ -f out/klipper.elf ] || { echo "!! A compilacao falhou. Abortando."; exit 1; }

SU mv out/klipper.elf /usr/local/bin/klipper_mcu.sandmmakers
SU ln -sfn /usr/local/bin/klipper_mcu.sandmmakers /usr/local/bin/klipper_mcu

# ---------- 7. Reiniciar ----------
echo "[7/7] Tudo pronto. Reiniciando a impressora..."
echo
echo "VERSAO INSTALADA: $TAG"
echo
SU reboot now || true
exit 0
