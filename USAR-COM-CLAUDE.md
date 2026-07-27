# Instalar com ajuda do Claude

Se você prefere que uma IA faça isso conversando com você em vez de clicar nos `.bat`, é só entregar este arquivo pro Claude (ou outro agente com acesso ao terminal).

**Como usar:** abra o Claude Code na pasta deste projeto e cole a mensagem abaixo. Ou simplesmente diga: *"leia o USAR-COM-CLAUDE.md e faz aí"*.

---

## Mensagem para colar

> Quero instalar o Klipper moderno da S&M Makers na minha Elegoo Neptune 4 Max.
> O IP da impressora é: **_(coloque seu IP aqui)_**
> Siga o procedimento descrito no arquivo `USAR-COM-CLAUDE.md`, na seção "Procedimento". Me avise antes de alterar qualquer coisa na impressora.

---

## Contexto (para o agente)

A Neptune 4 Max sai de fábrica com Klipper de 2022. A S&M Makers mantém um fork com Klipper 0.13.0 (2025) portado para essa máquina, preservando o stack Elegoo/Makerbase (tela LCD, `znp_tjc_klipper`).

Só são substituídos o `~/klipper` e o binário `/usr/local/bin/klipper_mcu` (o MCU "Linux"). **O MCU STM32F401 não é tocado** — o próprio autor desaconselha, porque exige desmontar a impressora.

- Instruções originais: https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html
- Repositório: https://github.com/sandmmakers/klipper
- Acesso SSH: usuário `mks`, senha padrão `makerbase`
- Formato das tags: `sandmmakers-ElegooNeptune4Max-v<FIRMWARE_ELEGOO>-v<KLIPPER>-<COMMITS>-<REV>`

**Regra que não pode ser quebrada:** a tag precisa corresponder exatamente à versão do firmware Elegoo instalado na máquina. Se não existir tag para aquele firmware, o processo para — atualizar o firmware Elegoo é manual (pendrive + cartão SD dentro da tela) e o usuário tem que fazer com as próprias mãos.

## Procedimento

### 1. Acesso

O prompt de senha do SSH exige um terminal de verdade. Um agente rodando com stdin fechado **não consegue** digitar a senha — as tentativas falham instantaneamente com `Permission denied`, o que parece senha errada mas não é.

Resolva instalando a chave pública primeiro. Peça ao usuário para rodar isto no PowerShell **dele**, fora do agente:

```powershell
ssh-keygen -t ed25519 -N "" -f $env:USERPROFILE\.ssh\id_ed25519
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh mks@<IP> "mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys"
```

Se o `ssh-copy-id` falhar com `Host key verification failed`, o agente pode resolver sozinho antes:

```bash
ssh-keyscan -H <IP> >> ~/.ssh/known_hosts
```

Confirme o acesso com `ssh -o BatchMode=yes mks@<IP> 'echo ok'`.

`sudo` continua pedindo senha mesmo com chave. Use `echo makerbase | sudo -S <comando>`.

### 2. Reconhecimento (só leitura)

```bash
# firmware Elegoo (o valor mais frequente é o certo)
grep -rhoE "1\.[0-9]+\.[0-9]+\.[0-9]+" /home/mks/Desktop/myfile/ | sort | uniq -c | sort -rn | head -1

# tags disponíveis
git ls-remote --tags https://github.com/sandmmakers/klipper.git | grep -oE 'sandmmakers-[A-Za-z0-9.-]+' | sort -u

# estado atual
df -h /                                     # precisa de ~800 MB livres
systemctl is-active klipper klipper_mcu makerbase-client moonraker
grep -nE "max_accel_to_decel|RUN_DECEL" ~/klipper_config/printer.cfg
```

Escolha a tag com o maior número de commits entre as compatíveis. **Confirme com o usuário antes de seguir.**

### 3. Instalação

Substitua `<FW>` pela versão do firmware (ex: `1.2.3.4`) e `<TAG>` pela tag escolhida.

```bash
# parar serviços
sudo systemctl stop klipper
sudo systemctl stop klipper_mcu
sudo systemctl stop makerbase-client

# backups
cp ~/klipper_config/printer.cfg ~/klipper_config/printer.cfg.stock.v<FW>
mv ~/klipper ~/klipper.stock.v<FW>
sudo mv /usr/local/bin/klipper_mcu /usr/local/bin/klipper_mcu.stock.v<FW>

# printer.cfg: o Klipper novo removeu max_accel_to_decel; se ficar, não sobe
sed -i "s/^max_accel_to_decel:/#max_accel_to_decel:/" ~/klipper_config/printer.cfg
sed -i "/{% set RUN_DECEL/d" ~/klipper_config/printer.cfg
sed -i "s/ ACCEL_TO_DECEL={RUN_DECEL}//" ~/klipper_config/printer.cfg

# baixar
git clone https://github.com/sandmmakers/klipper.git ~/klipper.sandmmakers
ln -sfn ~/klipper.sandmmakers ~/klipper
cd ~/klipper && git checkout <TAG>

# compilar o c_helper
sudo rm -f klippy/chelper/c_helper.so
~/klippy-env/bin/python2 klippy/chelper/__init__.py
~/klippy-env/bin/python2 -m compileall klippy

# compilar o MCU Linux
make clean
echo "CONFIG_MACH_LINUX=y" > .config
make olddefconfig
make clean
make
sudo mv out/klipper.elf /usr/local/bin/klipper_mcu.sandmmakers
sudo ln -sfn /usr/local/bin/klipper_mcu.sandmmakers /usr/local/bin/klipper_mcu

sudo reboot now
```

**Sobre o `menuconfig`:** as instruções oficiais mandam rodar `make menuconfig` e marcar "Linux process". É uma tela interativa, que um agente não consegue operar. Escrever `CONFIG_MACH_LINUX=y` no `.config` e rodar `make olddefconfig` dá o mesmo resultado — confira que o `.config` ficou com `CONFIG_BOARD_DIRECTORY="linux"`. Avise o usuário desse desvio.

**Sobre o `c_helper.so`:** apagar antes de compilar é obrigatório. Se o arquivo não existir no boot, o `znp_tjc_klipper` copia uma versão incompatível por cima, e o Klipper morre com `undefined symbol: extruder_stepper_free`.

### 4. Verificação

Espere o reboot (uns 30-60s) e confirme:

```bash
grep -m1 "Git version" ~/klipper_logs/klippy.log
curl -s http://localhost:7125/server/info    # klippy_state deve ser "ready"
```

Nos logs, dois MCUs devem aparecer: `mcu` (~84 MHz, o STM32 original) e `rpi` (~50 MHz, o Linux recém-compilado).

### 5. O que sobra para o usuário

Diga explicitamente que **ele** precisa fazer, no painel da impressora, antes de imprimir:

1. Nivelamento automático da mesa
2. Ajustar o Z-offset

E avise dos dois comportamentos conhecidos:

- Salvar o nivelamento pelo LCD pode gerar erro de timing no console. É inofensivo — `FIRMWARE_RESTART` resolve e o dado foi salvo.
- Os "performance modes" do LCD não ajustam mais a desaceleração (`minimum_cruise_ratio` fica no default), porque o `max_accel_to_decel` foi removido. Pode mudar o acabamento nos cantos.

## Reverter

```bash
sudo systemctl stop klipper klipper_mcu makerbase-client
cp ~/klipper_config/printer.cfg.stock.v<FW> ~/klipper_config/printer.cfg
rm ~/klipper && mv ~/klipper.stock.v<FW> ~/klipper
sudo rm /usr/local/bin/klipper_mcu
sudo mv /usr/local/bin/klipper_mcu.stock.v<FW> /usr/local/bin/klipper_mcu
sudo rm -f /usr/local/bin/klipper_mcu.sandmmakers
sudo reboot now
```

## Regras de conduta para o agente

- Confirme com o usuário **antes** da primeira escrita na impressora. Recon é livre; alterar não é.
- Nunca instale uma tag que não corresponda ao firmware detectado.
- Não prossiga se a impressora estiver imprimindo.
- Faça os backups antes de qualquer alteração, e não sobrescreva backup existente.
- Não toque no MCU STM32F401.
- Se algo falhar no meio, pare e explique. Quem está do lado da impressora é o usuário, não você.
