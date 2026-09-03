# eddy-ng: o Z-offset que se mede sozinho

Este documento continua de onde o [EDDY.md](EDDY.md) para. Lá você instala o BTT Eddy com o driver
que vem no Klipper. Aqui você troca esse driver pelo **eddy-ng**, e a máquina passa a descobrir o
zero do bico sozinha, a cada impressão, em vez de você calibrar com papel e guardar um número.

Feito e medido na minha Neptune 4 Max em 03/09/2026. Como todo o resto deste repositório: quebrou
primeiro, funcionou depois, e os erros estão escritos junto.

> **Crédito.** O Klipper moderno nesta máquina é trabalho da
> [S&M Makers](https://github.com/sandmmakers/klipper). O eddy-ng é do
> [vvuk](https://github.com/vvuk/eddy-ng). Eu só juntei os dois nesta impressora e anotei o caminho.

---

## 1. Eddy e eddy-ng: qual é a diferença, em duas frases

**O BTT Eddy é o hardware** — uma bobina que mede a que distância a mesa está, sem encostar. Isso
não muda.

**O eddy-ng é um software alternativo para esse mesmo hardware.** Mesmo sensor, mesmo cabo, mesma
peça no toolhead. O que muda é o programa dentro do Klipper que interpreta o que a bobina lê.

### Por que trocar

![Eddy e eddy-ng usam o mesmo hardware](docs/img/eddy-vs-eddyng.svg)

Todo sensor eddy sofre do mesmo problema: **a leitura muda conforme a coisa esquenta.** A mesa
quente e a própria bobina quente deslocam a medida. Não é defeito, é física do princípio indutivo.

Os dois softwares atacam esse problema de formas diferentes:

| | Driver padrão (`probe_eddy_current`) | eddy-ng (`probe_eddy_ng`) |
|---|---|---|
| Como acha o zero do bico | Você faz o teste do papel uma vez e guarda o número | O bico **encosta na mesa** e o zero é medido na hora |
| Quando isso acontece | Uma vez, e vale pra sempre | A cada impressão |
| Deriva térmica | Corrigida por uma tabela de compensação que você calibra | Não precisa: a medição já é feita quente |
| Trocar de bico | Recalibrar tudo | Não faz nada, o próximo tap já acha sozinho |
| Imprimir ABS a 100 °C depois de PLA a 60 °C | O zero está errado, você compensa no olho | O zero é o certo dos dois |

Esse "o bico encosta e mede" tem nome: **tap**. É o recurso inteiro. Se o tap não funcionar na sua
montagem, não vale a pena trocar de driver — o resto o driver padrão já faz.

### E o que NÃO muda

- Velocidade de varredura da mesa. O `rapid_scan` já existe no driver padrão.
- A peça física, o adaptador, a fiação.
- O fato de o Eddy enxergar só os últimos milímetros. Continua valendo tudo do [EDDY.md](EDDY.md).

---

## 2. Três coisas que me disseram que impediam, e não impediam

Eu quase não fiz essa instalação por causa de três "bloqueios". **Dois eram falsos e o terceiro
estava mal enunciado.** Se você leu isso em algum lugar, leia aqui também:

**"O Klipper mainline não tem o porte do HC32F460, então migrar deixa a placa-mãe sem firmware."**
Falso. O diretório `src/hc32f460` existe no
[Klipper mainline](https://github.com/Klipper3d/klipper/tree/master/src). E é discussão inútil de
qualquer jeito, porque:

**"Precisa migrar para o Klipper mainline."** Não precisa. O eddy-ng instala **em cima do fork da
S&M Makers**, sem trocar de Klipper. A instalação inteira é três links simbólicos e dois `sed`.

**"A bobina precisa estar a ~2,95 mm do bico ou o tap não funciona."** Aqui está o enunciado
correto: a wiki do eddy-ng diz que o tap é *sensível* a essa altura. A minha está a **0,94 mm**,
um terço do recomendado, e **o tap funciona** — três medições deram −0,050 / −0,042 / −0,057 mm,
desvio padrão de **0,006 mm**. Seis micra.

A lição não é "ignore a wiki". É que **a calibração te responde isso em 2 minutos** (tópico 6), e o
número real vale mais que a previsão. Rode e veja.

---

## 3. O que você precisa antes de começar

- Um BTT Eddy já instalado e **funcionando** com o driver padrão. Se ainda não chegou lá, o
  [EDDY.md](EDDY.md) é o caminho — não comece por aqui.
- Acesso SSH à impressora.
- Uma hora tranquila. Tem uma etapa que reinicia o Klipper com outro interpretador de Python, e
  você quer estar perto da máquina.
- Nenhuma impressão rodando.

**O caminho de volta existe em todos os passos** e está no tópico 10. Nada aqui é irreversível.

---

## 4. A receita, na ordem

![A ordem da migracao](docs/img/eddyng-ordem.svg)

### Passo 0 — proteja o que você já tem

```bash
# backup datado das configs
cd ~/klipper_config
cp printer.cfg printer.cfg.pre-eddyng-$(date +%Y%m%d-%H%M)
cp eddy.cfg   eddy.cfg.pre-eddyng-$(date +%Y%m%d-%H%M)
```

Se você tem alguma alteração à mão dentro da pasta do Klipper (eu tinha um patch no `probe.py`),
**commite numa branch local agora**, senão o resto do processo apaga:

```bash
cd ~/klipper.sandmmakers
git status --short          # veja se tem algo modificado
git checkout -b patch-local-$(date +%Y%m%d)
git add -A && git commit -m "preserva alteracoes locais"
```

### Passo 1 — baixe o eddy-ng num lugar permanente

**Não clone em `/tmp`.** O instalador cria *links simbólicos* apontando para a pasta do repositório.
`/tmp` é limpo no reboot, e no dia seguinte o Klipper sobe sem os módulos.

```bash
git clone https://github.com/vvuk/eddy-ng.git ~/eddy-ng
```

### Passo 2 — o Klipper aqui roda Python 2, e o eddy-ng é Python 3

Confira:

```bash
~/klippy-env/bin/python --version    # aqui deu: Python 2.7.16
```

Se der 2.x, você precisa de um ambiente Python 3. **Crie um novo do lado, não substitua o antigo** —
o antigo é o seu rollback:

```bash
virtualenv -p /usr/bin/python3 ~/klippy-env-py3
~/klippy-env-py3/bin/pip install -r ~/klipper/scripts/klippy-requirements.txt
~/klippy-env-py3/bin/pip install numpy
```

> `python3 -m venv` falha nesta imagem (`ensurepip` não vem instalado). Use `virtualenv`, que já está
> lá. E o `numpy` é dependência do eddy-ng que ninguém declara — sem ele o Klipper não sobe.

**Antes de trocar, teste que o fork inteiro compila em Python 3:**

```bash
cd ~/klipper && ~/klippy-env-py3/bin/python -m compileall -q klippy/
```

Silêncio e código de saída 0 significam que nenhum módulo da Elegoo é Python-2-only. Aqui passou
limpo. Se aparecer erro, **pare** e leia qual arquivo é — esse é o momento de desistir barato.

### Passo 3 — aponte o serviço para o Python 3

Precisa de `sudo`:

```bash
sudo cp /etc/systemd/system/klipper.service /etc/systemd/system/klipper.service.bak-pre-py3
sudo sed -i 's#/home/mks/klippy-env/bin/python#/home/mks/klippy-env-py3/bin/python#' \
     /etc/systemd/system/klipper.service
sudo systemctl daemon-reload
sudo systemctl restart klipper
```

**Desligue os aquecedores antes** (`M140 S0` e `M104 S0`). Reiniciar o Klipper com um aquecedor
ligado derruba o MCU com esta mensagem:

```
MCU 'mcu' shutdown: Missed scheduling of next digital out event
```

Isso **não é defeito nem sinal de que o Python 3 não funcionou**. É a trava de segurança do
micro-controlador fazendo o trabalho dela: o host sumiu enquanto um pino de aquecedor estava
pulsando. Um `FIRMWARE_RESTART` resolve. Perdi um bom tempo achando que era o interpretador.

Confirme:

```bash
curl -s http://localhost:7125/printer/info | grep -o '"python_path":[^,]*'
```

### Passo 4 — instale o eddy-ng

```bash
cd ~/eddy-ng && ./install.sh
```

Ele copia três arquivos e aplica dois `sed`, um no `src/Makefile` e outro no
`klippy/extras/bed_mesh.py`. **Confira que os dois pegaram** — o instalador usa `os.system` e não
checa se casou:

```bash
grep -n "LDC1612" ~/klipper/src/Makefile          # deve terminar com sensor_ldc1612_ng.c
grep -n "eddy.*probe_name" ~/klipper/klippy/extras/bed_mesh.py   # deve ter #eddy-ng no fim
```

No fork da S&M as duas linhas alvo existem e o patch aplica limpo.

### Passo 5 — recompile o firmware do Eddy

O eddy-ng traz um sensor novo (`sensor_ldc1612_ng.c`) que precisa estar dentro do firmware do
próprio Eddy. **Isto não toca na placa-mãe da impressora.**

Use um arquivo de configuração **separado**, não o `.config` da máquina (o porquê está no tópico 9):

```bash
cd ~/klipper
cat > ~/eddyng-rp2040.config <<'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_RPXXXX=y
CONFIG_MACH_RP2040=y
CONFIG_RPXXXX_FLASH_START_0100=y
CONFIG_RP2040_USB=y
CONFIG_USBSERIAL=y
CONFIG_WANT_LDC1612=y
EOF
make KCONFIG_CONFIG=~/eddyng-rp2040.config olddefconfig
make KCONFIG_CONFIG=~/eddyng-rp2040.config
ls -la out/klipper.uf2      # tem que existir
```

**Guarde o firmware que você acabou de compilar e o `.config` que o gerou**, porque o rollback do
tópico 10 depende dos dois existirem:

```bash
mkdir -p ~/eddy-firmware-backup
cp out/klipper.uf2 ~/eddy-firmware-backup/klipper-eddyng-$(date +%Y%m%d).uf2
cp ~/eddyng-rp2040.config ~/eddy-firmware-backup/
```

> Não existe como ler de volta o firmware que **já está** no Eddy — o rp2040 não entrega o
> binário gravado. Então o caminho de volta é recompilar, e para recompilar você precisa do
> `.config` anterior. Se você nunca compilou firmware nesta máquina, o Eddy está com o binário
> pronto da BigTreeTech, que você baixa de novo no repositório oficial deles.

Grave. **Pare o Klipper antes** e use uma sessão com terminal de verdade (`ssh -t`), porque o
`make flash` chama `sudo` no meio:

```bash
curl -s -X POST "http://localhost:7125/machine/services/stop?service=klipper"
make KCONFIG_CONFIG=~/eddyng-rp2040.config flash \
     FLASH_DEVICE=/dev/serial/by-id/usb-Klipper_rp2040_SEU_SERIAL-if00
curl -s -X POST "http://localhost:7125/machine/services/start?service=klipper"
```

> **Se travar em `sudo: no tty present`:** o Eddy já entrou em modo bootloader e a gravação parou no
> meio. Não entre em pânico — **a memória dele ainda tem o firmware antigo**. Ou você repete com
> `ssh -t` e `FLASH_DEVICE=2e8a:0003` (que é o endereço do Eddy em modo bootloader), ou desliga e
> liga a impressora na tomada e tudo volta como estava.

Confirme depois que subir — o MCU `eddy` tem que reportar mais comandos que antes:

```bash
grep "Loaded MCU 'eddy'" ~/klipper_logs/klippy.log | tail -1
```

Aqui foi de 105 para **131 comandos**. Os 26 a mais são o sensor novo.

### Passo 6 — troque a configuração

No `eddy.cfg` (ou onde estiver a sua seção do Eddy):

```ini
[probe_eddy_ng btt_eddy]        # era [probe_eddy_current btt_eddy]
sensor_type: ldc1612
i2c_mcu: eddy
i2c_bus: i2c0f
x_offset: -33.34                # o SEU, medido
y_offset: 20                    # o SEU, medido
```

**Apague as opções que só existem no driver antigo** — o Klipper recusa opção desconhecida e não
sobe: `speed`, `samples`, `samples_result`, `sample_retract_dist`, e a `calibrate:`.

**Apague também o bloco de autosave do driver velho** no fim do `printer.cfg`:

```
#*# [probe_eddy_current btt_eddy]
#*# z_offset = ...
#*# reg_drive_current = ...
#*# calibrate = ...
```

E procure no resto da configuração qualquer macro que leia `probe_eddy_current` — eu tinha uma
trava no `PRINT_START` que lia o `z_offset` dele e teria quebrado toda impressão.

---

## 5. O bootstrap do Z: o ovo e a galinha

![O impasse do primeiro homing e a saida](docs/img/eddyng-bootstrap-z.svg)

Aqui você vai bater numa parede que parece um erro grave e não é.

Nesta máquina **a sonda é a única referência de Z que existe** (`endstop_pin: probe:z_virtual_endstop`,
e o sensor físico original foi removido do toolhead na instalação do Eddy). Então:

- `G28` precisa da sonda para achar o Z.
- A sonda ainda não tem calibração do eddy-ng.
- E o `PROBE_EDDY_NG_SETUP` exige X e Y homeados.

```
$ G28
!! Drive current 15 not calibrated

$ PROBE_EDDY_NG_SETUP
!! X and Y must be homed before setup
```

**A saída é homear só X e Y**, que não chamam a sonda:

```
G28 X Y
PROBE_EDDY_NG_SETUP
```

### A armadilha que me custou uma calibração inteira

O setup abre um teste do papel (`TESTZ` para descer, `ACCEPT` para confirmar). Duas coisas:

**O número de Z que aparece na tela é fictício.** Aqui ele começou em `462.5` porque o
`[homing_override]` desta máquina declara `SET_KINEMATIC_POSITION Z=482.5` antes de sondar. **Ignore
o número e olhe o papel.** O zero real vai aparecer em qualquer valor esquisito.

**Não toque em X nem em Y durante o teste.** Nem botão de jog, nem `G28`, nem outra macro. O Klipper
recusa o `ACCEPT` se o cabeçote tiver saído do ponto onde o teste começou:

```python
# klippy/extras/manual_probe.py
if pos[:2] != start_pos[:2] or pos[2] >= start_pos[2]:
    "Manual probe failed! Use TESTZ commands to position the nozzle prior to running ACCEPT."
```

Eu fiz o teste do papel certinho e perdi tudo por causa disso. A mensagem sugere que você errou a
altura — e o problema estava em X/Y.

---

## 6. A calibração, e como ler o resultado

![Como ler as correntes de excitacao](docs/img/eddyng-correntes.svg)

Depois do `ACCEPT`, o eddy-ng varre as correntes de excitação sozinho e escolhe duas. Saída real
desta máquina:

```
!! Drive current 15 error: min height for valid samples is too high: 3.728 > 0.65
!! Drive current 16 error: min height for valid samples is too high: 1.092 > 0.65
// Drive current 17 warning: min height is 0.218 (> 0.025) is too high for tap.
//   This calibration will work fine for homing, but may not for tap.
// Drive current 17: valid height: 0.218 to 15.000, freq spread 3.46%, Fit 0.0053
// using 17 for homing.
// Drive current 18: valid height: 0.001 to 5.360, freq spread 3.57%, Fit 0.0051
// using 18 for tap.
// Setup success.
```

**Como ler isto:**

- As correntes 15 e 16 **falharam** e está tudo bem. O eddy-ng testa várias e descarta as ruins.
- A 17 serve para **homing** (enxerga de 0,218 a 15 mm — longe, bom para descer procurando).
- A 18 serve para **tap** (enxerga a partir de **0,001 mm** — coladinho, que é o que o toque exige).
- Aquele *warning* na 17 assusta e não é problema: ele está dizendo que a 17 não serve pro tap. A 18
  serve, e é ela que o tap usa.

Rode `SAVE_CONFIG`. Depois confirme que gravou de verdade — no meu primeiro `ACCEPT` recusado, o
`SAVE_CONFIG` rodou e não gravou nada, e eu só descobri olhando:

```bash
grep -A6 "probe_eddy_ng" ~/klipper_config/printer.cfg | tail -8
```

Tem que aparecer `calibrated_drive_currents`, `reg_drive_current`, `tap_drive_current` e as curvas
`calibration_17` / `calibration_18`.

Aí teste, nesta ordem:

```
G28 Z                  # usa a corrente de homing
PROBE_EDDY_NG_TAP      # usa a de tap
```

Resultado aqui:

```
// Tap 1: z=-0.050
// Tap 2: z=-0.042
// Tap 3: z=-0.057
// Probe computed tap at -0.050 (stddev 0.006) with 3 samples
```

**O que olhar é o `stddev`**, não o valor. 0,006 mm significa que três toques concordaram dentro de
seis micra — é isso que diz que dá pra confiar. Se o seu vier na casa dos centésimos, a montagem
precisa de atenção antes de você colocar o tap na impressão.

---

## 7. O fluxo de impressão que sai disso

![A sequencia nova do PRINT_START](docs/img/eddyng-print-start.svg)

O tap **não é um número que se guarda**. Ele é refeito a cada impressão. Então ele mora dentro do
`PRINT_START`:

```ini
[gcode_macro PRINT_START]
variable_temp_home: 120
gcode:
    {% set bed  = params.BED|default(printer.heater_bed.target)|float %}
    {% set extr = params.EXTRUDER|default(printer.extruder.target)|float %}
    {% set th   = printer['gcode_macro PRINT_START'].temp_home|float %}

    G90
    G92 E0
    M140 S{bed}
    M104 S{th}
    M190 S{bed}
    M109 S{th}

    G28
    PROBE_EDDY_NG_TAP        # <- o zero, medido agora

    M109 S{extr}
    LINHA_KAMP               # <- purga
```

**Por que o tap roda a 120 °C e não na temperatura final:** quente o bastante para a leitura ser
consistente com a impressão, frio o bastante para o bico não escorrer e sujar a própria medição. Um
bico babando na hora do toque mede a bolinha de plástico, não o bico.

**Nunca ponha `SAVE_CONFIG` depois de um tap.** O `SAVE_CONFIG` reinicia o Klipper e joga fora a
medição que você acabou de fazer. Se o tap ficar sempre alto ou sempre baixo por igual, o ajuste é
`PROBE_EDDY_NG_SET_TAP_OFFSET` — esse sim se grava.

O start gcode do fatiador fica com **uma linha só**:

```
PRINT_START BED=[bed_temperature_initial_layer_single] EXTRUDER=[nozzle_temperature_initial_layer]
```

Se você deixar `G28` no fatiador antes disso, ele homeia com o bico frio e o `PRINT_START` refaz
tudo depois. É sondagem jogada fora e uns 30 segundos por impressão.

As macros completas, incluindo a linha de purga e uma macro guiada de z-offset com janela de
confirmação, estão em [config/eddyng_macros.cfg](config/eddyng_macros.cfg).

---

## 8. Erros e acertos desta instalação

Ordem em que apareceram de verdade.

| O que aconteceu | Por quê | O que resolveu |
|---|---|---|
| Quase não fiz a instalação | Três "bloqueios" recebidos de segunda mão, dois falsos | Medir em vez de aceitar. Tópico 2 |
| `No module named 'numpy'` | Dependência não declarada do eddy-ng | `pip install numpy` no ambiente novo |
| `cannot import name 'final' from 'typing'` | eddy-ng quer Python ≥3.8, a imagem tem 3.7.3 | Tópico 9. É o **único** recurso de 3.8 usado |
| Build saiu para AVR e não gerou `.uf2` | `make olddefconfig` num `.config` antigo | Tópico 9 |
| `hardware/structs/ticks.h: No such file` | Mesma causa acima: o `#if` caiu no ramo do RP2350 | Tópico 9 |
| MCU caiu no `Missed scheduling of next digital out event` | Reiniciei o Klipper com a mesa a 50 °C | Trava de segurança, não defeito. Aquecedor off + `FIRMWARE_RESTART` |
| `make flash` parou em `sudo: no tty present`, Eddy em bootloader | `ssh` sem `-t` | `ssh -t` e `FLASH_DEVICE=2e8a:0003`. Nada foi apagado |
| `ACCEPT` recusado com o papel na altura certa | X/Y se moveram durante o teste | Tópico 5 |
| Uma opção do `[bed_mesh]` sumiu | Meu `sed` de `^speed:` pegou duas seções | Editar config grande com script que sabe onde está, não regex global |
| Mesa aquecendo sozinha, "misteriosa" | Uma macro minha, `MANTER_MESA_50`, pedida meses antes | Ler a própria configuração antes de teorizar |

**O que deu certo de primeira:** o `compileall` do fork em Python 3 (nenhum módulo da Elegoo é
Python-2-only), os dois patches do instalador no fork da S&M, o homing com a corrente 17, e o tap.

**O maior acerto de método:** quase todo diagnóstico desta lista saiu de *ler*, não de tentar. O
`~/klipper_logs/klippy.log` e o `curl .../server/gcode_store?count=30` responderam todas as
perguntas. Quando eu chutei, errei — inclusive sobre a mesa aquecendo.

---

## 9. Duas armadilhas de build que valem por si

**O símbolo do Kconfig mudou de nome.** Se o seu `.config` é antigo, ele diz
`CONFIG_MACH_RP2040=y` como *arquitetura*. No Klipper atual a arquitetura é `CONFIG_MACH_RPXXXX`, e
`MACH_RP2040` virou a escolha do *modelo* dentro dela (porque agora existe RP2350 também). Um
`.config` antigo faz o `make olddefconfig` não reconhecer a escolha e **cair no primeiro item da
lista, que é AVR** — o build sai para um ATmega e você fica olhando sem entender. Pelo mesmo motivo o
`main.c` do rp2040 entra no ramo errado do `#if` e pede um `ticks.h` que só existe no RP2350.

Por isso o tópico 5 usa um arquivo separado com os nomes atuais, e nunca `olddefconfig` no `.config`
da máquina.

**`typing.final` não existe no Python 3.7.** É o único recurso de 3.8+ que o eddy-ng usa, e é só um
decorador para conferência de tipos — não faz nada em tempo de execução. Em `probe_eddy_ng.py`,
tire o `final,` de dentro do `from typing import (...)` e ponha logo abaixo:

```python
try:
    from typing import final
except ImportError:      # Python 3.7
    def final(x):
        return x
```

---

## 10. Como voltar atrás

Cada passo tem retorno, e nenhum depende do anterior ter dado certo.

| Para desfazer | Comando |
|---|---|
| O Python 3 | `sudo cp /etc/systemd/system/klipper.service.bak-pre-py3 /etc/systemd/system/klipper.service && sudo systemctl daemon-reload && sudo systemctl restart klipper` |
| O eddy-ng | `cd ~/eddy-ng && ./install.sh -u` (desfaz os arquivos e os dois `sed`) |
| A configuração | restaure o `printer.cfg.pre-eddyng-*` e o `eddy.cfg.pre-eddyng-*` do passo 0 |
| O firmware do Eddy | recompile com o seu `.config` anterior e grave de novo |
| Uma gravação que travou no meio | desligue e ligue a impressora na tomada |

O ambiente Python 2 (`~/klippy-env`) **continua intacto** o tempo todo. Não apague.

---

## 11. O que ficou pendente aqui

Escrito para você não achar que está completo:

- **A malha da mesa está fora do `PRINT_START` de propósito.** A que estava salva foi sondada com
  `y_offset=0` e está 20 mm deslocada, além de ser do driver antigo. Refaça a sua antes de religar.
- **Compensação de temperatura**: não uso. O `[temperature_probe]` não sobe neste fork (falta o
  sensor do chip) e o tap torna ela desnecessária. Se você depende dela, isso é um ponto a testar.
- **Montagem a 0,94 mm**: funciona *nesta* máquina. Se o seu `stddev` de tap vier ruim, subir a
  bobina para perto dos 2,95 mm da wiki é a primeira coisa a tentar.

---

## 12. Links

- [vvuk/eddy-ng](https://github.com/vvuk/eddy-ng) · [wiki do BTT Eddy no eddy-ng](https://github.com/vvuk/eddy-ng/wiki/BTT-Eddy)
- [S&M Makers / klipper](https://github.com/sandmmakers/klipper) — o port que faz esta máquina existir
- [EDDY.md](EDDY.md) — instalação do Eddy com o driver padrão, e as armadilhas do sensor
- [config/](config/) — os arquivos reais desta máquina
- [MAQUINA-REFERENCIA.md](MAQUINA-REFERENCIA.md) — a máquina inteira, valor por valor
