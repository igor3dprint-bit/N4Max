#!/bin/bash
# Verificacao (SOMENTE LEITURA - nao altera nada na impressora)

REPO="https://github.com/sandmmakers/klipper.git"

echo "=========================================================="
echo "  VERIFICACAO DA IMPRESSORA"
echo "=========================================================="
echo

# --- Modelo / firmware Elegoo instalado ---
FW=$(grep -rhoE "1\.[0-9]+\.[0-9]+\.[0-9]+" /home/mks/Desktop/myfile/ 2>/dev/null \
     | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')

if [ -z "$FW" ]; then
    echo "!! Nao consegui identificar a versao do firmware Elegoo."
    echo "   Veja no painel da impressora: Settings > About Machine"
    echo "   e anote a versao antes de continuar."
    exit 1
fi
echo "Firmware Elegoo instalado .... $FW"

# --- Klipper atual ---
ATUAL="(desconhecido)"
if [ -d ~/klipper/.git ]; then
    cd ~/klipper
    ATUAL=$(git describe --tags 2>/dev/null)
    [ -z "$ATUAL" ] && ATUAL=$(git log -1 --format="%h de %ad" --date=short)
    cd ~
fi
echo "Klipper rodando agora ........ $ATUAL"

# --- Ja instalado? ---
if [ -L ~/klipper ] && [ -d ~/klipper.sandmmakers ]; then
    echo "Status ....................... JA TEM o Klipper novo instalado"
else
    echo "Status ....................... Klipper ORIGINAL de fabrica"
fi

# --- Espaco em disco ---
LIVRE=$(df -m / | tail -1 | awk '{print $4}')
echo "Espaco livre ................. ${LIVRE} MB"
if [ "$LIVRE" -lt 800 ]; then
    echo "  !! Pouco espaco. O ideal e ter pelo menos 800 MB livres."
fi

# --- Internet na impressora ---
echo
echo "Procurando versoes disponiveis na internet..."
TAGS=$(git ls-remote --tags "$REPO" 2>/dev/null \
       | grep -oE "sandmmakers-ElegooNeptune4Max-v${FW}-[A-Za-z0-9.-]+" \
       | grep -v '\^{}' | sort -u)

if [ -z "$TAGS" ]; then
    echo
    if ! git ls-remote --tags "$REPO" >/dev/null 2>&1; then
        echo "!! A impressora nao conseguiu acessar a internet."
        echo "   Ela precisa de internet para baixar o Klipper novo."
        echo "   Verifique o wifi/cabo da impressora e tente de novo."
    else
        echo "!! NAO EXISTE versao do Klipper novo para o seu firmware ($FW)."
        echo
        echo "   Isso significa que voce precisa primeiro ATUALIZAR o firmware"
        echo "   da Elegoo para uma versao compatível. Esse processo e manual"
        echo "   (pendrive + cartao SD) e esta explicado no LEIA-ME.md,"
        echo "   na secao 'E se aparecer que meu firmware nao tem versao?'."
    fi
    exit 2
fi

# escolhe a tag mais recente (maior numero de commits)
ESCOLHIDA=$(echo "$TAGS" | sort -t- -k5 -V | tail -1)

echo
echo "Versoes compativeis encontradas:"
echo "$TAGS" | sed 's/^/   - /'
echo
echo "Sera instalada a mais nova:"
echo "   $ESCOLHIDA"
echo
echo "=========================================================="
echo "  TUDO CERTO. Pode rodar o 3-Instalar-Klipper.bat"
echo "=========================================================="
exit 0
