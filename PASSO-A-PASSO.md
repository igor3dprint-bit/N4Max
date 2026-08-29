# Klipper novo na Elegoo Neptune 4 Max, passo a passo

> [English version](STEP-BY-STEP.md) · [O Z-offset que não obedece](Z-OFFSET.md)

A Neptune 4 Max sai de fábrica com um Klipper de **2022**. Dá para colocar a versão de **2025**
(a 0.13.0), e este guia mostra exatamente como, comando por comando, com o que cada um faz e o que
você deve ver na tela.

> **Sem a S&M Makers nada disto existiria.** Todo o trabalho de portar o Klipper moderno para esta
> máquina é dele. Este guia é a tradução do processo dele para o português, com as armadilhas que
> encontramos na prática. Assista o vídeo do **[@SandMMakers](https://www.youtube.com/watch?v=Aoy3sI1lv1g)**
> e leia o [tutorial original](https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html).

**Não precisa** de pendrive, cartão SD, chave de fenda, nem abrir a impressora. Tudo é feito pela rede.

---

## Índice

1. [Antes de começar](#1-antes-de-começar)
2. [Descobrir o IP da impressora](#2-descobrir-o-ip-da-impressora)
3. [Conectar na impressora](#3-conectar-na-impressora)
4. [Reconhecimento (só olha, não muda nada)](#4-reconhecimento-só-olha-não-muda-nada)
5. [Fazer backup](#5-fazer-backup-não-pule-este-passo)
6. [Instalar](#6-instalar)
7. [Conferir se deu certo](#7-conferir-se-deu-certo)
8. [O que fazer depois](#8-o-que-fazer-depois)
9. [Voltar atrás](#9-voltar-atrás)
10. [Problemas comuns](#10-problemas-comuns)

---

## 1. Antes de começar

### O que você precisa

- A impressora **ligada**, **não imprimindo**, e na **mesma rede** que o seu computador
- Um computador com Windows 10/11, Mac ou Linux
- Uns 30 minutos

### O que vai acontecer, em português

A impressora é um computadorzinho com Linux dentro. Você vai entrar nele pela rede (isso se chama
**SSH**), trocar a pasta do Klipper por uma versão nova, recompilar duas coisinhas, e reiniciar.

Só duas coisas são substituídas, a pasta `~/klipper` e o programa `/usr/local/bin/klipper_mcu`.
O chip principal da impressora (o **MCU STM32**) **não é tocado em momento nenhum**. O próprio autor
desaconselha mexer nele, porque exige desmontar a máquina.

### Os riscos, sem enfeite

Mexer em firmware tem risco. O caminho de volta existe e está na [seção 9](#9-voltar-atrás), mas quem
está do lado da impressora é você. Se a energia cair no meio da instalação, você pode precisar
reinstalar o firmware da Elegoo por pendrive.

**Faça o [backup do passo 5](#5-fazer-backup-não-pule-este-passo).** É a diferença entre um susto e
um problema.

---

## 2. Descobrir o IP da impressora

No painel da impressora, vá em **Settings** (Configurações). O IP aparece na tela, algo como
`192.168.0.50`.

Se não achar por lá, entre na página de administração do seu roteador e procure na lista de aparelhos
conectados por um nome parecido com `mkspi`.

Anote esse número. Ele aparece em quase todo comando daqui pra frente. **Onde este guia escrever
`SEU_IP`, troque pelo seu.**

---

## 3. Conectar na impressora

### Abrir o terminal

| Sistema | Como abrir |
|---|---|
| **Windows** | Tecle `Win`, digite `powershell`, Enter |
| **Mac** | `Cmd + Espaço`, digite `terminal`, Enter |
| **Linux** | `Ctrl + Alt + T` |

### Entrar

```bash
ssh mks@SEU_IP
```

Na primeira vez ele pergunta se você confia na máquina. Digite `yes` e Enter.

Depois pede a senha. A padrão é esta.

```
makerbase
```

> **Enquanto você digita a senha, nada aparece na tela.** Nem asteriscos, nem pontinhos. Parece
> que o teclado parou de funcionar. É proposital, todo terminal Linux faz isso. Digite e aperte Enter.

Deu certo se o texto antes do cursor virar algo como `mks@mkspi:~$`.

### Opcional, mas recomendado, entrar sem digitar senha

Se você for repetir os passos, vale instalar uma chave de acesso. **Saia da impressora** (`exit`) e,
no seu computador, rode.

```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
ssh-copy-id mks@SEU_IP
```

No Windows não existe `ssh-copy-id`. Use esta linha no lugar (ela evita duplicar a chave se você
rodar duas vezes).

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh mks@SEU_IP "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys; K=$(cat | tr -d '\r'); grep -qxF \"$K\" ~/.ssh/authorized_keys || echo \"$K\" >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys"
```

### Uma coisa que confunde, o `sudo` continua pedindo senha

Alguns comandos precisam de poder de administrador, eles começam com `sudo`. **Mesmo com a chave
instalada, o `sudo` pede a senha.** É normal. Digite `makerbase` quando ele pedir.

---

## 4. Reconhecimento (só olha, não muda nada)

Estes quatro comandos não alteram nada. Rode **dentro da impressora** (depois do `ssh`).

### 4.1 Qual firmware da Elegoo está instalado

Esta é a informação mais importante do processo inteiro.

```bash
grep -rhoE "1\.[0-9]+\.[0-9]+\.[0-9]+" /home/mks/Desktop/myfile/ 2>/dev/null | sort | uniq -c | sort -rn | head -3
```

O que deve aparecer, o número que se repete mais é o certo.

```
     97 1.2.3.4
      1 Binary file /home/mks/Desktop/myfile/znp/znp_tjc_klipper/build/... matches
```

Aqui o firmware é o **1.2.3.4**. Anote o seu.

### 4.2 Quais versões do Klipper novo existem para ele

```bash
git ls-remote --tags https://github.com/sandmmakers/klipper.git | grep -oE 'sandmmakers-[A-Za-z0-9.-]+' | grep -v '\^{}' | sort -u
```

Saída de exemplo.

```
sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-0-1
sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-51-1
```

Como ler esse nome.

```
sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-51-1
                              └──┬───┘ └──┬───┘ └┬┘
                    firmware Elegoo   Klipper   commits extras
```

> **Regra que não pode ser quebrada.** A parte do meio tem que ser **exatamente** o firmware que
> você anotou no 4.1. Se o seu firmware é `1.2.3.4`, só serve tag com `v1.2.3.4`. Instalar a de outro
> firmware quebra a impressora.

Entre as compatíveis, escolha a com o **maior número de commits extras** (no exemplo, a `-51-1`).

**Não apareceu nenhuma tag com o seu firmware?** Então você precisa antes atualizar o firmware da
Elegoo, e esse processo é manual. Veja a [seção 10](#10-problemas-comuns).

**Não apareceu nada e deu erro?** A impressora provavelmente está sem internet. Ela precisa de
internet de verdade, não basta enxergar o seu computador.

### 4.3 Tem espaço em disco?

```bash
df -h /
```

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk1p2  6.6G  4.9G  1.7G  75% /
```

Você precisa de pelo menos **800 MB** na coluna `Avail`. Se tiver menos, apague gcodes antigos em
`~/gcode_files`.

### 4.4 A impressora está imprimindo?

```bash
curl -s http://localhost:7125/printer/objects/query?print_stats | grep -o '"state": "[a-z]*"'
```

Precisa dizer `"state": "complete"`, `"standby"` ou `"cancelled"`. **Se disser `"printing"`, pare
aqui** e espere a impressão terminar.

---

## 5. Fazer backup (não pule este passo)

O instalador salva cópias dentro da própria impressora. Isso resolve 95% dos problemas, mas não
resolve se o cartão de memória da impressora corromper. Por isso vale tirar uma cópia **para fora**.

Rode isto **no seu computador**, não dentro da impressora. Saia com `exit` primeiro.

**Windows, PowerShell.**

```powershell
cd $env:USERPROFILE\Desktop
ssh mks@SEU_IP "tar czf - -C / home/mks/klipper_config home/mks/klipper usr/local/bin/klipper_mcu* 2>/dev/null" > backup-neptune.tar.gz
```

**Mac ou Linux.**

```bash
cd ~/Desktop
ssh mks@SEU_IP "tar czf - -C / home/mks/klipper_config home/mks/klipper usr/local/bin/klipper_mcu* 2>/dev/null" > backup-neptune.tar.gz
```

Vai demorar alguns minutos e criar um arquivo de algumas centenas de MB na sua Área de Trabalho.

**Confira que o backup presta.** Um backup não verificado não é um backup.

```bash
gzip -t backup-neptune.tar.gz && echo "BACKUP OK"
```

Se aparecer `BACKUP OK`, pode seguir. Se não aparecer nada ou der erro, refaça.

> O que mais importa nesse arquivo é o `klipper_config/printer.cfg`. É ele que guarda toda a
> calibração da sua máquina, e é o único que não dá para baixar da internet de novo.

---

## 6. Instalar

Volte para dentro da impressora (`ssh mks@SEU_IP`).

**Antes de colar qualquer coisa**, defina estas duas variáveis com os SEUS valores do passo 4.
Todos os comandos seguintes usam elas.

```bash
FW=1.2.3.4
TAG=sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-51-1
```

Confira que ficou certo antes de continuar.

```bash
echo "firmware=$FW  tag=$TAG"
```

### 6.1 Parar os serviços

```bash
sudo systemctl stop klipper
sudo systemctl stop klipper_mcu
sudo systemctl stop makerbase-client
```

Vai pedir a senha (`makerbase`) na primeira vez. A partir daqui a impressora fica sem responder no
Fluidd/Mainsail até o fim, isso é esperado.

### 6.2 Guardar as cópias de segurança

```bash
cp ~/klipper_config/printer.cfg ~/klipper_config/printer.cfg.stock.v$FW
mv ~/klipper ~/klipper.stock.v$FW
sudo mv /usr/local/bin/klipper_mcu /usr/local/bin/klipper_mcu.stock.v$FW
```

Confira que os três existem antes de seguir.

```bash
ls -d ~/klipper.stock.v$FW /usr/local/bin/klipper_mcu.stock.v$FW ~/klipper_config/printer.cfg.stock.v$FW
```

Se algum dos três não aparecer, **pare**. Sem eles não dá para voltar atrás.

### 6.3 Ajustar o arquivo de configuração

O Klipper novo **removeu** um ajuste chamado `max_accel_to_decel`. Se ele continuar no arquivo, o
Klipper não sobe, e a mensagem de erro não explica direito o motivo.

```bash
sed -i "s/^max_accel_to_decel:/#max_accel_to_decel:/" ~/klipper_config/printer.cfg
sed -i "/{% set RUN_DECEL/d" ~/klipper_config/printer.cfg
sed -i "s/ ACCEL_TO_DECEL={RUN_DECEL}//" ~/klipper_config/printer.cfg
```

Confira que não sobrou nenhuma linha ativa.

```bash
grep -nE "^max_accel_to_decel|RUN_DECEL" ~/klipper_config/printer.cfg
```

Se não aparecer nada, ou só aparecer linha começando com `#`, está certo.

### 6.4 Baixar o Klipper novo

```bash
git clone https://github.com/sandmmakers/klipper.git ~/klipper.sandmmakers
ln -sfn ~/klipper.sandmmakers ~/klipper
cd ~/klipper
git checkout $TAG
```

Confira que pegou a versão certa.

```bash
git describe --tags
```

Tem que devolver exatamente a sua `$TAG`.

### 6.5 Compilar a parte 1 de 2

```bash
cd ~/klipper
sudo rm -f klippy/chelper/c_helper.so
~/klippy-env/bin/python2 klippy/chelper/__init__.py
~/klippy-env/bin/python2 -m compileall klippy
```

> **Apagar o `c_helper.so` antes é obrigatório.** Se esse arquivo não existir no momento em que a
> impressora liga, o módulo da tela da Elegoo copia uma versão incompatível por cima, e o Klipper
> morre com `undefined symbol: extruder_stepper_free`. Recompilar resolve, mas é um susto que dá para
> evitar fazendo na ordem certa.

### 6.6 Compilar a parte 2 de 2 (a demorada)

O tutorial original manda rodar `make menuconfig` e marcar "Linux process" numa tela azul. Dá para
pular essa tela escrevendo a opção direto. O resultado é idêntico.

```bash
cd ~/klipper
make clean
echo "CONFIG_MACH_LINUX=y" > .config
make olddefconfig
```

Confira que a configuração pegou.

```bash
grep CONFIG_BOARD_DIRECTORY .config
```

Tem que aparecer `CONFIG_BOARD_DIRECTORY="linux"`. Se não aparecer, **não continue**.

Agora compile de verdade. **Esta parte demora de 5 a 15 minutos e parece travada.** Não é. Não feche
a janela.

```bash
make clean
make
```

Confira que o arquivo saiu.

```bash
ls -la out/klipper.elf
```

### 6.7 Instalar o que foi compilado

```bash
sudo mv out/klipper.elf /usr/local/bin/klipper_mcu.sandmmakers
sudo ln -sfn /usr/local/bin/klipper_mcu.sandmmakers /usr/local/bin/klipper_mcu
```

### 6.8 Reiniciar

```bash
sudo reboot now
```

A conexão vai cair, é esperado. Espere de 45 a 90 segundos.

---

## 7. Conferir se deu certo

Entre de novo (`ssh mks@SEU_IP`) e rode.

### A versão instalada

```bash
grep -m1 "Git version" ~/klipper_logs/klippy.log
```

```
Git version: 'sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-51-1-0-g8dc12fe4'
```

### O Klipper subiu?

```bash
curl -s http://localhost:7125/printer/info | tr ',' '\n' | grep -E 'state|software_version'
```

```
{"result": {"state_message": "Printer is ready"
 "software_version": "sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-51-1-0-g8dc12fe4"
 "state": "ready"
```

Tem que dizer `"state": "ready"`.

### Os dois processadores apareceram?

```bash
grep -oE "Loaded MCU '[a-z]+' [0-9]+ commands" ~/klipper_logs/klippy.log | tail -2
```

```
Loaded MCU 'mcu' 105 commands
Loaded MCU 'rpi' 127 commands
```

O `mcu` é o STM32 original da impressora. O `rpi` é o que você acabou de compilar. **Os dois têm que
aparecer.**

---

## 8. O que fazer depois

**Antes de imprimir qualquer coisa**, no painel da impressora.

1. **Nivelamento automático da mesa** (auto bed leveling)
2. **Ajustar o Z-offset**

A calibração antiga não é aproveitada de forma confiável pelo Klipper novo.

> **Se o Z-offset parecer que não faz efeito nenhum, não é você.** Esta máquina tem um defeito
> conhecido, com três causas, e a solução está em **[Z-OFFSET.md](Z-OFFSET.md)**. Vale ler antes de
> perder tempo achando que errou a calibração, nós perdemos.

### Duas coisas estranhas que são normais

**1. Erro ao salvar o nivelamento.** Depois de nivelar pelo painel e apertar salvar, pode aparecer
uma mensagem de erro no console do Fluidd/Mainsail. É inofensivo. Mande um `FIRMWARE_RESTART` (ou
reinicie a impressora) e pronto, o nivelamento **foi salvo** e será usado.

**2. Os "modos de performance" mudaram.** Aqueles modos de velocidade do painel usavam o
`max_accel_to_decel`, que foi removido do Klipper. Agora eles não controlam mais a desaceleração.
Na prática você pode notar diferença nos cantos das peças. Para voltar ao comportamento antigo,
acrescente no `[printer]` do seu `printer.cfg`.

```ini
minimum_cruise_ratio: 0
```

---

## 9. Voltar atrás

Funciona se você fez o passo 6.2 e as três cópias existem.

```bash
FW=1.2.3.4                    # o mesmo do passo 4.1

sudo systemctl stop klipper
sudo systemctl stop klipper_mcu
sudo systemctl stop makerbase-client

# guarda a config nova antes de sobrescrever
cp ~/klipper_config/printer.cfg ~/klipper_config/printer.cfg.novo
cp ~/klipper_config/printer.cfg.stock.v$FW ~/klipper_config/printer.cfg

rm ~/klipper
mv ~/klipper.stock.v$FW ~/klipper

sudo rm -f /usr/local/bin/klipper_mcu
sudo mv /usr/local/bin/klipper_mcu.stock.v$FW /usr/local/bin/klipper_mcu

sudo reboot now
```

> **A reversão devolve o `printer.cfg` de fábrica.** Toda a calibração que você fez depois da
> instalação fica no `printer.cfg.novo` e **não volta sozinha**. Se quiser recuperar algum ajuste,
> abra os dois arquivos lado a lado e copie o que interessa.

A pasta `~/klipper.sandmmakers` continua no lugar, então reinstalar depois é rápido.

---

## 10. Problemas comuns

### `Permission denied` ao entrar por SSH

Senha errada, ou alguém trocou a senha. A padrão é `makerbase`. Se outro mod foi instalado antes
(OpenNept4une, por exemplo), a senha pode ser outra.

### `Host key verification failed`

Acontece quando a impressora foi reinstalada e a "identidade" dela mudou. Rode no seu computador.

```bash
ssh-keygen -R SEU_IP
```

E conecte de novo.

### O Windows diz que `ssh` não é reconhecido

Vá em **Configurações → Aplicativos → Recursos opcionais → Adicionar recurso** e instale o
**Cliente OpenSSH**. Feche e reabra o PowerShell.

### O Klipper não sobe depois de instalar

Veja o motivo.

```bash
tail -30 ~/klipper_logs/klippy.log
```

Os dois erros mais comuns.

| Mensagem | Causa | Solução |
|---|---|---|
| `Option 'max_accel_to_decel' is not valid` | O passo 6.3 não pegou | Refaça o 6.3 e mande `FIRMWARE_RESTART` |
| `undefined symbol: extruder_stepper_free` | O `c_helper.so` errado foi copiado por cima | Refaça o passo 6.5 inteiro |

### Não existe versão do Klipper novo para o meu firmware

Aí o caminho é **manual**. Você precisa primeiro atualizar o firmware da Elegoo.

1. Baixe em [elegoo.com/pages/download](https://www.elegoo.com/pages/download)
2. **Placa principal.** Copie a pasta `ELEGOO_UPDATE_DIR` para um pendrive vazio, espete na
   impressora, e no painel vá em Settings → About Machine → seta embaixo → Confirm. Leva 1 a 2 minutos.
3. **Tela.** Copie o arquivo `.tft` para o cartão SD que veio com a impressora. Aqui precisa
   desmontar a tampa de trás da tela com uma chave hexagonal de 2 mm, colocar o SD, ligar, esperar
   atualizar, e abrir de novo para tirar o cartão.
4. Refaça o nivelamento e o Z-offset.

Depois volte para o [passo 4](#4-reconhecimento-só-olha-não-muda-nada).

> A atualização da Elegoo **pode apagar seu `printer.cfg`** e pode forçar o nivelamento para o
> modo Standard (6x6). Se você usava o **Professional Mode**, vai precisar configurar de novo.

---

## Créditos

Todo o trabalho pesado é da **S&M Makers**.

- [Tutorial original](https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html)
- [github.com/sandmmakers/klipper](https://github.com/sandmmakers/klipper)
- [Vídeo do @SandMMakers](https://www.youtube.com/watch?v=Aoy3sI1lv1g)

**Sem garantia.** Mexer em firmware tem risco. O caminho de volta existe e funciona, mas quem está do
lado da impressora é você.
