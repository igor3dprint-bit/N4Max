# BTT Eddy na Neptune 4 Max: instalar, calibrar e não quebrar o bico

Autor: [@Igor3DPrint](https://instagram.com/igor3dprint)

Este guia é o que eu queria ter lido antes de instalar o Eddy na minha Neptune 4 Max. Ele custou uma
noite inteira, um bico arrastado na chapa e quatro causas diferentes empilhadas uma em cima da outra.
Está tudo aqui, na ordem em que importa.

Se você só quer o resumo: **a corrente de excitação do sensor, o `reg_drive_current`, é o parâmetro
mais importante e o menos falado**. Se ele estiver errado, o sensor dá erro mesmo estando na
distância certa, e você vai procurar horas no lugar errado. Eu procurei.

---

## Índice

1. [Antes de comprar, entenda a limitação](#1-antes-de-comprar-entenda-a-limitação)
2. [Montagem física e as três medidas](#2-montagem-física-e-as-três-medidas)
3. [A configuração base](#3-a-configuração-base)
4. [A ordem da calibração, que não é a que parece](#4-a-ordem-da-calibração-que-não-é-a-que-parece)
5. [A corrente de excitação, a tal onda](#5-a-corrente-de-excitação-a-tal-onda)
6. [As quatro armadilhas que me pegaram](#6-as-quatro-armadilhas-que-me-pegaram)
7. [O homing, e por que ele precisa de um ritual](#7-o-homing-e-por-que-ele-precisa-de-um-ritual)
8. [A malha densa, que é o motivo de ter comprado o Eddy](#8-a-malha-densa-que-é-o-motivo-de-ter-comprado-o-eddy)
9. [Como saber se ficou bom](#9-como-saber-se-ficou-bom)
10. [Referência rápida de erros](#10-referência-rápida-de-erros)

---

## 1. Antes de comprar, entenda a limitação

O Eddy mede distância por corrente parasita numa bobina. É rápido, preciso e não encosta em nada.
Mas ele enxerga **só os últimos milímetros**. Na minha máquina a faixa calibrada vai de **0,05 mm a
4,05 mm**. Acima disso o chip não vê a mesa, liga os bits de erro e o Klipper aborta.

Isso tem uma consequência que quase ninguém avisa:

> **O Eddy não serve sozinho como fim de curso de Z.**

Um fim de curso mecânico ou uma sonda de contato disparam de qualquer altura. O Eddy não. Se o bico
estiver a 30 mm da mesa quando você mandar `G28`, ele não desce procurando: aborta na primeira
leitura, porque não existe leitura válida.

Na Neptune 4 Max isso vira problema real, porque o `[stepper_z]` usa
`endstop_pin: probe:z_virtual_endstop`, ou seja, **a sonda é a única referência de Z da máquina**. Se
você remover a sonda original ao instalar o Eddy, como eu removi, fica um ovo e galinha: pra homear
precisa estar perto, pra saber que está perto precisa homear.

Tem solução, está na [seção 7](#7-o-homing-e-por-que-ele-precisa-de-um-ritual). Mas decida sabendo
disso. Se der pra manter a sonda original instalada em paralelo, mantenha. Vai te poupar aquela
seção inteira.

Um detalhe que me enganou: depois de remover a sonda, o pino dela continua na placa e continua
lendo. Um pino de entrada com pull-up e nada plugado flutua em nível alto, o que faz o Klipper achar
que existe um fim de curso acionado. Não confie no que o pino diz, confie no que está parafusado.

---

## 2. Montagem física e as três medidas

Depois de parafusar o Eddy você precisa de três números. Erre qualquer um e a malha inteira mede o
lugar errado.

### Altura da bobina

Encoste o bico na mesa e meça quanto a face da bobina fica **acima da ponta do bico**. Na minha ficou
**0,94 mm**. A BTT recomenda entre 2 e 3 mm. Eu deixei mais baixo por decisão consciente, e isso
reduz a margem: com 0,94 mm, quando o bico está a 3 mm da mesa a bobina está a 3,94 mm, praticamente
no limite dos 4,05 mm que ela enxerga.

Guarde esse número, ele entra em toda conta daqui pra frente:

> altura da bobina = altura do bico + altura de montagem

### Deslocamento em X

Meça do centro do bico ao centro da bobina, na horizontal. Na minha deu **33,34 mm**.

O sinal confunde todo mundo. A regra: olhe o `[stepper_x]` no `printer.cfg`. Se `position_endstop: 0`
e `homing_positive_dir: false`, o fim de curso está no lado X=0, ou seja, na esquerda. Se a bobina
fica do lado do fim de curso, ela está à esquerda do bico e o **`x_offset` é negativo**. No meu caso,
`x_offset: -33.34`.

### Deslocamento em Y

Esse é o que quase todo mundo assume como zero e depois paga caro. Eu assumi. Meça de verdade.

Na minha o Eddy fica **atrás** do bico e deu **20 mm**. Atrás significa que a bobina fica sobre um
ponto do prato com Y **maior** que o do bico, então **`y_offset` positivo**: `y_offset: 20`.

Se errar esse número a malha inteira é sondada deslocada. Eu rodei uma malha completa com
`y_offset: 0` quando o certo era 20, ou seja, cada ponto medido 20 mm fora do lugar. A malha parecia
perfeitamente normal e estava completamente errada.

---

## 3. A configuração base

Eu deixo o Eddy num arquivo separado, `eddy.cfg`, com `[include eddy.cfg]` no `printer.cfg`. Fica
mais fácil de reverter e de comparar.

```ini
[mcu eddy]
serial: /dev/serial/by-id/usb-Klipper_rp2040_SEU_ID_AQUI-if00

[probe_eddy_current btt_eddy]
sensor_type: ldc1612
i2c_mcu: eddy
i2c_bus: i2c0f
x_offset: -33.34
y_offset: 20
z_offset: 2.0
speed: 5.0
samples: 2
samples_result: median
sample_retract_dist: 1.0

[bed_mesh]
speed: 200
horizontal_move_z: 2.5
mesh_min: 20,30
mesh_max: 385,400
probe_count: 6,6
algorithm: bicubic
bicubic_tension: 0.2
mesh_pps: 2, 2
fade_start: 5.0
fade_end: 30.0
```

Descubra o ID da sua placa com `ls /dev/serial/by-id/` dentro da impressora.

### Duas contas que você precisa fazer antes de salvar

**A primeira, o `sample_retract_dist`.** Com `samples: 2` o Klipper sonda, sobe esse tanto e sonda de
novo. O gatilho acontece com a bobina lendo `z_offset`, que aqui é 2,0 mm. Se o recuo for grande
demais, a segunda sondagem começa fora da faixa e dá erro.

> `z_offset` mais `sample_retract_dist` tem que ficar abaixo de 4,05

O padrão de fábrica é 3,0, que dá 5,0 e estoura. Por isso eu uso **1,0**.

**A segunda, o `horizontal_move_z`.** É a altura que o bico viaja entre pontos da malha. Lembre de
somar a altura de montagem:

> `horizontal_move_z` mais a altura de montagem tem que ficar abaixo de 4,05

O padrão de 10 mm colocaria a bobina a 10,94 mm, cega. Por isso eu uso **2,5**, que dá 3,44 mm.

### Os limites da malha

O bico precisa alcançar cada ponto que a bobina vai medir. A conta do Klipper é:

> posição do bico = ponto da malha menos o offset

Com `x_offset: -33.34` o bico vai para `ponto + 33,34`. Com `position_max: 430.1` no `[stepper_x]`, o
maior `mesh_max` em X que cabe com folga fica por volta de **385**, que leva o bico a 418,34 e deixa
quase 12 mm de margem. Com `y_offset: 20` o bico vai para `ponto − 20`, então `mesh_max` em Y de 400
leva o bico a 380, tranquilo.

---

## 4. A ordem da calibração, que não é a que parece

Essa é a parte que eu fiz errado e que custou a noite. A ordem certa é:

1. **Primeiro** a corrente de excitação, com `LDC_CALIBRATE_DRIVE_CURRENT`
2. **Depois** a tabela de frequência por altura, com `PROBE_EDDY_CURRENT_CALIBRATE`

Nunca o contrário, e nunca só uma das duas.

O motivo é que a corrente de excitação define a amplitude do sinal, e mudar ela **desloca todas as
frequências**. Se você calibrar a tabela primeiro e mexer na corrente depois, a tabela vira lixo. E o
pior é que ela não avisa: passa a disparar o gatilho na altura errada, o que significa bico na chapa.

> Mexeu no `reg_drive_current`? A tabela morreu. Refaça o `PROBE_EDDY_CURRENT_CALIBRATE` antes de
> mandar qualquer `G28`.

---

## 5. A corrente de excitação, a tal onda

Aqui é onde eu quero que você preste atenção, porque foi o que resolveu depois de horas.

O LDC1612 excita a bobina com uma corrente configurável, o `reg_drive_current`, um inteiro de 0 a 31.
Ele precisa estar casado com a sua bobina, a sua altura de montagem e a sua mesa. Se estiver **alto
demais** a amplitude satura. Se estiver **baixo demais** o sinal some. Nos dois casos o chip liga um
bit de erro e o Klipper te devolve isto:

```
Error during homing z: Eddy current sensor error
```

E aqui está a armadilha: **essa mensagem parece dizer que o sensor está longe da mesa, e não é isso
que ela diz.** No meu caso o bico estava a 2 mm, dentro da faixa, e o erro acontecia igual. Eu passei
horas mexendo em altura, em temperatura da mesa e em distância de recuo, quando o problema era o
ganho.

Se quiser confirmar na fonte, o erro nasce no firmware, em `src/sensor_ldc1612.c`:

```c
if (data > 0x0fffffff) {
    // Sensor reports an issue - cancel homing
    ld->homing_flags = 0;
    trsync_do_trigger(ld->ts, ld->error_reason);
    return;
}
```

Esses quatro bits altos são os bits de erro do próprio chip. Repare que o teste vem **antes** de
qualquer movimento, ou seja, ele aborta na primeira amostra. É por isso que o sintoma é "não desce e
já dá erro". E repare também que **isso não tem nada a ver com a tabela `calibrate`**: é hardware
reclamando, não o Klipper comparando números.

### Como medir, sem mover a máquina

Existe um comando que faz o próprio chip escolher o valor certo, na posição em que ele está, sem
mover nada:

```
LDC_CALIBRATE_DRIVE_CURRENT CHIP=btt_eddy
```

A resposta sai no console:

```
probe_eddy_current btt_eddy: reg_drive_current: 16
```

Compare com o que está na sua config. No meu caso estava **18** e o chip queria **16**. Dois pontos
de diferença, e era isso que travava tudo.

### Onde esse comando mora

Se você grepar o `probe_eddy_current.py` procurando esse comando, não acha, e é fácil concluir que o
seu fork não tem. **Ele fica no `ldc1612.py`**, que é o driver do chip:

```bash
grep -n "LDC_CALIBRATE_DRIVE_CURRENT" ~/klipper*/klippy/extras/ldc1612.py
```

Eu quase desisti dessa via porque procurei no arquivo errado.

### Depois de medir

```
SAVE_CONFIG
```

A impressora reinicia com o valor novo. E agora, obrigatoriamente, refaça a tabela. Não pule.

---

## 6. As quatro armadilhas que me pegaram

Listo na ordem em que apareceram, porque uma escondia a outra. Se você tem `Eddy current sensor
error` e já conferiu a altura, é quase certo que é uma destas.

### Armadilha 1: a impressora se declara zerada no boot

Este repositório já documenta isso no [Z-OFFSET.md](Z-OFFSET.md), e com o Eddy fica muito pior.

No `printer.cfg` e no `plr.cfg` da Neptune existe um bloco assim:

```ini
[delayed_gcode KINEMATIC_POSITION]
initial_duration: 3.0
gcode:
      SET_KINEMATIC_POSITION X=110
      SET_KINEMATIC_POSITION Y=110
      SET_KINEMATIC_POSITION Z=0
```

Isso faz o Klipper acreditar, poucos segundos depois de ligar, que o Z está em zero, **com o bico
fisicamente a 30 mm da mesa**. Quando você manda `G28`, o `safe_z_home` olha e conclui: o Z já está
homeado, e 0 é menor que o `z_hop` de 3, então preciso subir. Ele sobe para "3", que na vida real é
33 mm. A bobina não vê nada e aborta.

Esse foi o motivo do sintoma clássico: **homeia X e Y, volta pro meio, não desce e já dá o erro**. Se
é exatamente isso que você está vendo, é aqui.

Comente o bloco inteiro, nos dois arquivos. Ele aparece duplicado, e quem vale é o do `printer.cfg`,
porque vem depois. Comentar só um não resolve.

### Armadilha 2: uma compensação de Z antiga aplicada às cegas

Eu tinha isto no `printer.cfg`, de quando usava a sonda de contato:

```ini
[gcode_macro G28]
rename_existing: G28.1
gcode:
    G28.1 {rawparams}
    SET_GCODE_OFFSET Z=-1.95
```

Depois de trocar de sonda isso continuou sendo aplicado. Resultado: **todo `G0 Z` descia 1,95 mm a
mais do que eu mandava**. Foi isso que arrastou o bico na minha chapa enquanto eu tentava posicionar
manualmente.

Confira o valor ativo na sua máquina agora:

```bash
curl -s "http://SEU_IP/printer/objects/query?gcode_move" | grep -o '"homing_origin": \[[^]]*\]'
```

Se o terceiro número não for `0.0`, existe um deslocamento escondido comendo a sua descida. Antes de
mandar qualquer movimento manual em Z, zere isso.

### Armadilha 3: o recuo entre as duas passadas do homing

O `[stepper_z]` vem com:

```ini
homing_retract_dist: 5
```

O Klipper encosta no gatilho, sobe esse tanto e faz uma segunda passada lenta pra confirmar. Com o
gatilho a 2,0 mm de leitura, subir 5 mm leva a bobina a 7 mm, fora da faixa. A segunda passada começa
cega e o chip aborta.

O sintoma é traiçoeiro porque **a primeira passada funciona**: você vê a máquina descer, encostar, e
só então dar erro. Parece problema de gatilho, é problema de recuo.

Eu uso **1,5**, que deixa a bobina em 3,5 mm.

### Armadilha 4: a corrente de excitação

É a [seção 5](#5-a-corrente-de-excitação-a-tal-onda) inteira. Foi a última a cair e a que realmente
destravou.

---

## 7. O homing, e por que ele precisa de um ritual

Se a sua sonda original foi removida, o primeiro `G28` depois de ligar não tem como funcionar
sozinho, porque não existe referência nenhuma de Z e a bobina só enxerga 4 mm.

O que funciona, e é seguro, é declarar uma referência falsa só pra liberar o eixo e depois **descer
olhando**:

```
SET_KINEMATIC_POSITION Z=50
G91
G0 Z10 F300
G90
G28 X Y
G0 X215 Y215 F6000
```

Agora desça o Z pelo painel, olhando, até uns 2 mm da mesa. Use passos de 10 só enquanto estiver
claramente longe, depois 1, depois 0,1. Então:

```
G28 Z
```

A partir daí o Z fica homeado e a impressora funciona normal até você desligar.

> **Nunca** mande um `G0 Z` absoluto para uma altura calculada de cabeça enquanto o Z não for
> confiável. Foi exatamente assim que eu arrastei o bico. Passo pequeno, olho no bico, e pare se
> encostar.

### Separando a folga de viagem da altura de mergulho

Se você tem alguma coisa alta na mesa perto do X0 e Y0, uma borracha de limpeza por exemplo, o
`z_hop` do `safe_z_home` te coloca num impasse: ele é ao mesmo tempo a folga da viagem até o fim de
curso e a altura de início do mergulho. Você precisa de folga alta pra viajar e altura baixa pra
sondar, e um número só não faz as duas coisas.

A saída é trocar o `safe_z_home` por um `homing_override`, que separa as duas:

```ini
[homing_override]
axes: xyz
gcode:
    {% set tudo = 'X' not in params and 'Y' not in params and 'Z' not in params %}
    {% set z_conhecido = 'z' in printer.toolhead.homed_axes %}
    {% if not z_conhecido %}
        SET_KINEMATIC_POSITION Z=0
    {% endif %}
    G91
    G0 Z16 F600
    G90
    {% if tudo or 'X' in params %}
        G28 X
    {% endif %}
    {% if tudo or 'Y' in params %}
        G28 Y
    {% endif %}
    {% if tudo or 'Z' in params %}
        G0 X239.25 Y194.55 F6000
        {% if z_conhecido %}
            G0 Z3 F600
        {% else %}
            G91
            G0 Z-16 F600
            G90
        {% endif %}
        G28 Z
    {% endif %}
```

Ajuste o `G0 X239.25 Y194.55` para o ponto de sondagem da sua máquina.

A lógica em português: sobe 16 mm relativos, o que é seguro de qualquer altura, inclusive com o Z
virgem. Homeia X e Y com folga total. Volta ao ponto de sondagem. Se o Z já era conhecido, desce para
3 mm absolutos, que é uma altura boa de mergulho. Se não era, desce os mesmos 16 mm relativos e volta
exatamente para onde estava, preservando o posicionamento manual do ritual.

O `safe_z_home` e o `homing_override` não podem coexistir. Comente um pra usar o outro.

---

## 8. A malha densa, que é o motivo de ter comprado o Eddy

Sonda de contato leva quase um segundo por ponto. O Eddy varre em movimento contínuo. É aqui que ele
paga o investimento: dá pra fazer uma malha de milhares de pontos no tempo em que a mesa aquece.

```ini
[gcode_macro MALHA_EDDY_PRECISA]
description: Malha densa por varredura, com a mesa estabilizada
gcode:
    {% set bed = params.BED|default(60)|float %}
    {% set soak = params.SOAK|default(180)|int %}
    M140 S{bed}
    TEMPERATURE_WAIT SENSOR=heater_bed MINIMUM={bed - 1} MAXIMUM={bed + 1}
    G4 P{soak * 1000}
    G28
    BED_MESH_CLEAR
    _BED_MESH_CALIBRATE METHOD=rapid_scan HORIZONTAL_MOVE_Z=2.5 PROBE_COUNT=60,60 MESH_PPS=0 SCAN_SPEED=200
    M400
    RESPOND TYPE=command MSG="Malha pronta. Rode SAVE_CONFIG para gravar."
```

Uso: `MALHA_EDDY_PRECISA BED=60 SOAK=600`, depois `SAVE_CONFIG`.

São 3600 pontos, cerca de 6 mm de espaçamento num prato de 420. Contra os 6x6 de fábrica, que dão
73 mm de espaçamento, é outra categoria.

Duas observações que valem a pena. O `rapid_scan` só é liberado se a sonda for do tipo
`probe_eddy_current`; com sonda de contato o Klipper cai no método normal sem avisar. E o
`HORIZONTAL_MOVE_Z=2.5` é a altura do **bico** durante a varredura, não da bobina: com montagem de
0,94 mm a bobina fica em 3,44 mm, dentro da faixa. Se a sua montagem for mais alta, refaça a conta.

---

## 9. Como saber se ficou bom

No fim do `PROBE_EDDY_CURRENT_CALIBRATE` o Klipper reporta o desvio padrão:

```
probe_eddy_current: stddev=67.901 in 2482 queries
```

Esse número sozinho não diz nada, porque está em Hz. Pra saber o que significa em distância, pegue a
tabela gravada no fim do `printer.cfg` e veja quantos Hz correspondem a um milímetro na altura em que
o gatilho acontece.

Na minha, entre 1,5 e 2,5 mm a curva anda 23.422 Hz por milímetro. Então:

```
67,9 Hz dividido por 23.422 Hz/mm = 0,0029 mm
```

Cerca de 3 micra de repetibilidade na altura de disparo. É melhor que qualquer sonda de contato que
eu já usei.

Confira também duas coisas na tabela. Ela precisa ser **monotônica**, ou seja, a frequência tem que
cair de forma contínua conforme a altura sobe, sem nenhuma inversão. Se tiver inversão, a corrente de
excitação está errada e você está na [seção 5](#5-a-corrente-de-excitação-a-tal-onda).

E repare que a **sensibilidade cai conforme sobe**. Na minha, 47.672 Hz/mm junto da mesa contra
12.849 Hz/mm no topo da faixa. Isso não é defeito, é a natureza do sensor, e é exatamente por isso
que ele vira erro quando você tenta usar de longe.

---

## 10. Referência rápida de erros

| Sintoma | Causa provável | Onde olhar |
|---|---|---|
| Homeia XY, volta pro meio, não desce e dá erro | Home falso no boot deixando o Z alto | [Armadilha 1](#armadilha-1-a-impressora-se-declara-zerada-no-boot) |
| Desce, encosta, e só então dá erro | `homing_retract_dist` grande demais | [Armadilha 3](#armadilha-3-o-recuo-entre-as-duas-passadas-do-homing) |
| Erro mesmo com o bico a 2 mm da mesa | `reg_drive_current` errado | [Seção 5](#5-a-corrente-de-excitação-a-tal-onda) |
| Todo movimento em Z desce mais do que o comandado | `SET_GCODE_OFFSET` antigo ativo | [Armadilha 2](#armadilha-2-uma-compensação-de-z-antiga-aplicada-às-cegas) |
| Segunda amostra do `PROBE` falha | `sample_retract_dist` estourando a faixa | [Seção 3](#3-a-configuração-base) |
| Erro durante a malha, entre pontos | `horizontal_move_z` estourando a faixa | [Seção 3](#3-a-configuração-base) |
| Primeira camada torta de um lado só | `y_offset` errado ou assumido zero | [Seção 2](#2-montagem-física-e-as-três-medidas) |
| Gatilho na altura errada depois de mexer na corrente | Tabela não refeita | [Seção 4](#4-a-ordem-da-calibração-que-não-é-a-que-parece) |
| Fim de curso lendo acionado com o bico no ar | Pino de sonda removida flutuando alto | [Seção 1](#1-antes-de-comprar-entenda-a-limitação) |

### Dois detalhes de operação que me custaram tempo

O `FIRMWARE_RESTART` nem sempre recarrega a config de verdade. Quando desconfiar, force pelo serviço
e confirme lendo de volta o que ficou carregado:

```bash
curl -s -X POST "http://SEU_IP/machine/services/restart?service=klipper"
```

E se você mantém a mesa aquecida parada, desligue ela antes de reiniciar o serviço. Reiniciar com
aquecedor ativo derruba o MCU com `Scheduled digital out event will exceed max_duration`. Não é
perigoso, o desligamento corta o aquecedor, mas dá um susto e exige religar.

---

## Licença e garantia

Mesma coisa do resto do repositório. Sem garantia. Mexer em sonda tem risco de bico na chapa, e quem
está do lado da impressora é você. Vá devagar, olhe o bico, e pare quando ficar estranho.
