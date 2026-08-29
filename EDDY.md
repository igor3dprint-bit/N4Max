# BTT Eddy Duo na Elegoo Neptune 4 Max

Autor [@Igor3DPrint](https://instagram.com/igor3dprint)

Este guia cobre a instalação da sonda BTT Eddy Duo na Neptune 4 Max rodando o Klipper moderno. Está
escrito na ordem em que as coisas acontecem, com os números que eu medi na minha máquina e os erros
que eu cometi antes de chegar neles.

Um resumo antes de tudo. O parâmetro que mais me atrasou foi a corrente de excitação da bobina, o
`reg_drive_current`. Com ele errado o sensor acusa falha mesmo com o bico na distância certa, e a
mensagem de erro aponta para o lugar errado. Está no [tópico 9](#9-a-corrente-de-excitacao).

---

## Tópicos

1. [Hardware que eu usei](#1-hardware-que-eu-usei)
2. [Peças impressas](#2-pecas-impressas)
3. [Como o Eddy aparece no computador](#3-como-o-eddy-aparece-no-computador)
4. [O que o Eddy faz e o que ele não faz](#4-o-que-o-eddy-faz-e-o-que-ele-nao-faz)
5. [As três medidas da montagem](#5-as-tres-medidas-da-montagem)
6. [A configuração base](#6-a-configuracao-base)
7. [As contas que evitam erro de sensor](#7-as-contas-que-evitam-erro-de-sensor)
8. [A ordem da calibração](#8-a-ordem-da-calibracao)
9. [A corrente de excitação](#9-a-corrente-de-excitacao)
10. [Quatro armadilhas da Neptune 4 Max](#10-quatro-armadilhas-da-neptune-4-max)
11. [O homing e o ritual do primeiro home](#11-o-homing-e-o-ritual-do-primeiro-home)
12. [A malha densa](#12-a-malha-densa)
13. [Macros que eu uso no dia a dia](#13-macros-que-eu-uso-no-dia-a-dia)
14. [Como medir se a calibração ficou boa](#14-como-medir-se-a-calibracao-ficou-boa)
15. [Tabela de sintomas](#15-tabela-de-sintomas)

---

## 1. Hardware que eu usei

Sonda **BTT Eddy Duo**, da BigTreeTech. A versão Duo se conecta por **USB**, direto na placa da
impressora ou no host. Não precisa de fio de dados ligado na placa mãe da Neptune, o que simplifica
bastante a instalação.

Ela aparece no Klipper como um MCU separado, com serial próprio.

```ini
[mcu eddy]
serial: /dev/serial/by-id/usb-Klipper_rp2040_SEU_ID_AQUI-if00
```

Para descobrir o seu ID, com a sonda plugada, rode dentro da impressora.

```bash
ls /dev/serial/by-id/
```

---

## 2. Peças impressas

Tudo o que eu imprimi para esta montagem.

### Adaptador da sonda

O suporte que prende o Eddy no carro do extrusor da Neptune 4.

https://www.printables.com/model/928061-neptune-4-btt-eddy-adapter

Tem duas variantes no modelo, uma reta e uma a noventa graus. Eu usei os arquivos
`BTT-Eddy_Adapter_v05.stl` e `BTT-Eddy_Adapter90deg_v05.stl`. Escolha conforme a folga que sobrar no
seu carro, porque a posição do adaptador define a altura de montagem da bobina, e essa altura entra
em todas as contas do [tópico 7](#7-as-contas-que-evitam-erro-de-sensor).

### Suporte da borracha de limpeza

`nozzle-cleaner-holder-improved-lifted-pad-n4.stl`

A borracha em si é a **almofada de limpeza da Bambu Lab A1**, aquela de silicone que acompanha a
máquina. Ela é barata, aguenta temperatura de bico sem derreter e tem a rigidez certa para raspar
sem entortar o carro.

Eu montei a borracha perto da origem, ocupando aproximadamente de X0 a X5 e de Y0 a Y35, com sete
milímetros de altura. Anote a sua posição e altura, porque elas entram na configuração do homing e
das macros de limpeza.

### Guias de canto do prato

`en4max-buildplatecornerguide-left.stl` e `en4max-buildplatecornerguide-right.stl`

Servem para o prato magnético voltar sempre na mesma posição depois de você tirar a peça. Sem eles a
chapa desloca alguns milímetros a cada retirada, e a malha que você levou meia hora fazendo passa a
descrever um lugar que mudou.

Com uma malha densa, esses guias deixam de ser conforto e passam a fazer parte da calibração.

### Coletor de purga

`ecc2-poop-chute-magnetic-snap-in-place-15x10-20x10mm_magnets_logo.stl`

Opcional. Se você adotar a purga em bloco descrita no [tópico 13](#13-macros-que-eu-uso-no-dia-a-dia),
o material sai no canto da mesa e fica lá. O coletor magnético resolve isso levando o material para
fora do prato.

---

## 3. Como o Eddy aparece no computador

Este ponto merece destaque porque é onde muita gente trava antes mesmo de começar.

O **botão de BOOT do Eddy Duo fica na parte de cima da placa**. Ele não aparece sozinho no
computador quando você só liga o cabo. A sequência que funciona é a seguinte.

1. Com o cabo USB desconectado, pressione e segure o botão de BOOT
2. Sem soltar o botão, ligue o cabo USB no computador
3. Solte o botão

Agora ele aparece, e você consegue gravar o firmware do Klipper nele.

Se você ligar o USB primeiro e só depois apertar o botão, ele não entra em modo de gravação. Foi o
que aconteceu comigo na primeira tentativa, e passei um tempo achando que a placa estava com
defeito.

Depois de gravado, ele passa a aparecer normalmente em `/dev/serial/by-id/` toda vez que a
impressora liga, sem precisar de botão nenhum.

---

## 4. O que o Eddy faz e o que ele não faz

O Eddy mede distância pela corrente parasita induzida numa bobina. Ele lê rápido, repete bem, e não
encosta em nada.

A limitação que quase ninguém avisa é o alcance. Ele enxerga **apenas os últimos milímetros**. Na
minha máquina a faixa calibrada vai de 0,05 mm até 4,05 mm. Acima disso o chip não vê a mesa, liga os
bits de erro e o Klipper aborta.

Daí sai a frase que resume o guia inteiro.

> O Eddy não serve sozinho como fim de curso de Z.

Um fim de curso mecânico dispara de qualquer altura. O Eddy não dispara, porque de longe não existe
leitura nenhuma para comparar.

Na Neptune 4 Max isso pesa, porque o `[stepper_z]` de fábrica usa
`endstop_pin: probe:z_virtual_endstop`, ou seja, a sonda é a única referência de Z que a máquina
tem. Se você remover a sonda original ao instalar o Eddy, como eu removi, cria um ciclo. Para homear
o bico precisa estar perto, e para saber que está perto o Z precisa estar homeado.

O [tópico 11](#11-o-homing-e-o-ritual-do-primeiro-home) mostra como quebrar esse ciclo. Se der para
manter a sonda original instalada em paralelo, mantenha, e você pula aquele tópico inteiro.

Um detalhe que me enganou. Depois de remover a sonda antiga, o pino dela continua na placa e
continua sendo lido. Entrada com resistor de pull-up e nada plugado flutua em nível alto, o que faz o
Klipper acreditar que existe um fim de curso acionado. Não confie no que o pino informa, confie no
que está parafusado na máquina.

---

## 5. As três medidas da montagem

Depois de parafusar o adaptador você precisa de três números. Errar qualquer um deles faz a malha
inteira medir o lugar errado.

### Altura da bobina

Encoste o bico na mesa e meça quanto a face da bobina fica acima da ponta do bico. Na minha ficou
**0,94 mm**. A BigTreeTech recomenda entre dois e três milímetros.

Eu fiquei mais baixo por escolha, e isso reduz a folga de manobra. Com 0,94 mm, quando o bico está a
três milímetros da mesa a bobina está a 3,94 mm, quase no limite dos 4,05 mm que ela enxerga.

Guarde esse número, porque ele entra em todas as contas do próximo tópico.

```
altura da bobina = altura do bico + altura de montagem
```

### Deslocamento em X

Meça do centro do bico ao centro da bobina, na horizontal. Na minha deu **33,34 mm**.

O sinal confunde. A regra que eu uso é olhar o `[stepper_x]` no `printer.cfg`. Com
`position_endstop: 0` e `homing_positive_dir: false`, o fim de curso fica no lado X igual a zero, ou
seja, na esquerda. Se a bobina está do mesmo lado do fim de curso, ela fica à esquerda do bico, e o
`x_offset` é **negativo**.

No meu caso ficou `x_offset: -33.34`.

### Deslocamento em Y

Este é o que quase todo mundo assume como zero. Eu assumi, e depois refiz uma malha inteira por
causa disso. Meça.

Na minha o Eddy fica **atrás** do bico e deu **20 mm**. Atrás quer dizer que a bobina cobre um ponto
do prato com Y maior que o do bico, então o `y_offset` é **positivo**.

No meu caso ficou `y_offset: 20`.

Rodei uma malha completa com `y_offset` em zero quando o certo era vinte. Cada ponto foi medido vinte
milímetros fora do lugar. A malha parecia normal na tela e estava errada inteira.

---

## 6. A configuração base

Eu mantenho o Eddy num arquivo separado chamado `eddy.cfg`, com um `[include eddy.cfg]` no
`printer.cfg`. Fica mais fácil de comparar e de reverter.

```ini
[mcu eddy]
serial: /dev/serial/by-id/usb-Klipper_rp2040_SEU_ID_AQUI-if00

[probe_eddy_current btt_eddy]
sensor_type: ldc1612
i2c_mcu: eddy
i2c_bus: i2c0f
x_offset: -33.34
y_offset: 20
speed: 5.0
samples: 2
samples_result: median
sample_retract_dist: 1.0

[bed_mesh]
speed: 200
horizontal_move_z: 2.5
mesh_min: 20,25
mesh_max: 390,410
probe_count: 6,6
algorithm: bicubic
bicubic_tension: 0.2
mesh_pps: 2, 2
fade_start: 5.0
fade_end: 30.0
```

Repare que **não existe `z_offset` nesse bloco**, e isso é de propósito. O motivo está na
[armadilha 4](#armadilha-4-o-z_offset-escrito-a-mao-trava-o-save_config).

### Por que o mesh_max não cobre o prato inteiro

O prato tem 420 mm, mas a área que dá para medir é menor, e a culpa é da geometria da sonda. O
Klipper calcula assim.

```
posição do bico = ponto da malha menos o offset do eixo
```

Com `x_offset: -33.34`, o bico precisa ir para `ponto + 33,34`. O `position_max` do X é 430,1, então
o ponto mais à direita que dá para medir fica por volta de 396. Eu uso 390 para sobrar margem, o que
leva o bico a 423,34.

Com `y_offset: 20`, o bico vai para `ponto - 20`. Um `mesh_min` em Y de 25 leva o bico a 5, quase
encostado no batente da frente.

O limite inferior de X também tem motivo. Com `mesh_min` em X abaixo de 20, a bobina passaria por
cima da borracha de limpeza, que tem sete milímetros de altura, durante a varredura.

---

## 7. As contas que evitam erro de sensor

Três desigualdades. Chame de `F` o topo da faixa calibrada, que na minha máquina é 4,05, e de `M` a
altura de montagem da bobina, que na minha é 0,94.

```
z_offset + sample_retract_dist   <  F
horizontal_move_z + M            <  F
altura de início do mergulho + M <  F
```

Se qualquer uma estourar, o sensor vai acusar erro em algum ponto do ciclo, e o sintoma vai parecer
outra coisa completamente diferente.

### Primeira conta, o sample_retract_dist

Com `samples: 2` o Klipper sonda, sobe esse tanto e sonda de novo. O gatilho acontece com a bobina
lendo o valor do `z_offset`. Se o recuo for grande demais, a segunda sondagem começa fora da faixa.

O padrão de fábrica é 3,0. Com `z_offset` perto de 2,0 isso dá 5,0 e estoura. Eu uso **1,0**.

### Segunda conta, o horizontal_move_z

É a altura do bico durante a viagem entre pontos da malha. Some a altura de montagem para saber onde
a bobina fica.

O padrão de dez milímetros colocaria a bobina a 10,94 mm, cega. Eu uso **2,5**, que resulta em 3,44
mm.

### Terceira conta, a altura de início do mergulho

Quem define isso é o `z_hop` do `safe_z_home`, ou o seu `homing_override`. Com montagem de 0,94 mm,
começar o mergulho a três milímetros deixa a bobina em 3,94 mm, dentro da faixa mas com pouca folga.

---

## 8. A ordem da calibração

Esta é a parte que eu fiz na ordem errada e que me custou uma noite inteira.

1. Escrever a configuração base com os offsets medidos
2. Calibrar a corrente de excitação com `LDC_CALIBRATE_DRIVE_CURRENT CHIP=btt_eddy` e rodar
   `SAVE_CONFIG`
3. Só então construir a tabela com `PROBE_EDDY_CURRENT_CALIBRATE CHIP=btt_eddy` e rodar `SAVE_CONFIG`
4. Testar o homing
5. Depois disso, a malha

Nunca o contrário, e nunca só uma das duas calibrações.

A corrente de excitação define a amplitude do sinal, e mudar ela desloca todas as frequências. Se
você construir a tabela primeiro e mexer na corrente depois, a tabela perde a validade.

O pior é que ela não avisa. Ela passa a disparar o gatilho na altura errada, o que significa bico
contra a chapa.

> Mexeu no `reg_drive_current`, a tabela morreu. Refaça o `PROBE_EDDY_CURRENT_CALIBRATE` antes de
> mandar qualquer `G28`.

---

## 9. A corrente de excitação

O LDC1612 excita a bobina com uma corrente configurável chamada `reg_drive_current`, que é um número
inteiro de zero a trinta e um. Ela precisa estar casada com a sua bobina, a sua altura de montagem e
a sua mesa.

Corrente **alta demais** satura a amplitude. Corrente **baixa demais** apaga o sinal. Nos dois casos
o chip liga um bit de erro e o Klipper devolve isto.

```
Error during homing z: Eddy current sensor error
```

Aqui está a armadilha. Essa mensagem parece dizer que o sensor está longe da mesa, e não é isso que
ela informa. No meu caso o bico estava a dois milímetros, dentro da faixa, e o erro acontecia igual.
Passei horas mexendo em altura, em temperatura da mesa e em distância de recuo, quando o problema
era o ganho do sinal.

Se quiser confirmar na fonte, o erro nasce no firmware, em `src/sensor_ldc1612.c`.

```c
if (data > 0x0fffffff) {
    // Sensor reports an issue - cancel homing
    ld->homing_flags = 0;
    trsync_do_trigger(ld->ts, ld->error_reason);
    return;
}
```

Os quatro bits altos são os bits de erro do próprio chip. Repare que o teste vem **antes** de
qualquer movimento, então ele aborta na primeira amostra. É por isso que o sintoma aparece como
"não desce e já dá erro". E repare também que isso não tem relação com a tabela `calibrate`, porque é
hardware reclamando, não o Klipper comparando números.

### Como medir sem mover a máquina

Existe um comando que faz o próprio chip escolher o valor certo, na posição em que ele está, sem
mover nada.

```
LDC_CALIBRATE_DRIVE_CURRENT CHIP=btt_eddy
```

A resposta sai no console.

```
probe_eddy_current btt_eddy: reg_drive_current: 16
```

Compare com o que está na sua configuração. No meu caso estava dezoito e o chip queria dezesseis.
Dois pontos de diferença travavam tudo.

### Onde esse comando mora

Se você procurar esse comando dentro do `probe_eddy_current.py`, não acha, e é fácil concluir que o
seu fork do Klipper não tem. Ele fica no `ldc1612.py`, que é o driver do chip.

```bash
grep -n "LDC_CALIBRATE_DRIVE_CURRENT" ~/klipper*/klippy/extras/ldc1612.py
```

Eu quase abandonei essa linha de investigação porque procurei no arquivo errado.

### Depois de medir

Rode `SAVE_CONFIG`. A impressora reinicia com o valor novo. Em seguida refaça a tabela, como está no
[tópico 8](#8-a-ordem-da-calibracao). Não pule essa parte.

---

## 10. Quatro armadilhas da Neptune 4 Max

Listadas na ordem em que apareceram aqui, porque uma escondia a outra. Se você tem
`Eddy current sensor error` e já conferiu a altura, muito provavelmente é uma destas.

### Armadilha 1, a impressora se declara zerada no boot

No `printer.cfg` e no `plr.cfg` da Neptune existe este bloco.

```ini
[delayed_gcode KINEMATIC_POSITION]
initial_duration: 3.0
gcode:
      SET_KINEMATIC_POSITION X=110
      SET_KINEMATIC_POSITION Y=110
      SET_KINEMATIC_POSITION Z=0
```

Poucos segundos depois de ligar, o Klipper passa a acreditar que o Z está em zero, com o bico
fisicamente a trinta milímetros da mesa. Quando você manda `G28`, o `safe_z_home` conclui que o Z já
está homeado, que zero é menor que o `z_hop`, e **sobe** o bico para "três", que na vida real são
trinta e três. A bobina não vê nada e aborta.

O sintoma é bem característico. Ele homeia X e Y, volta para o meio, não desce, e já dá o erro.

Comente o bloco inteiro nos dois arquivos. Ele aparece duplicado, e quem vale é o do `printer.cfg`,
porque vem depois na ordem de leitura. Comentar só um não resolve.

### Armadilha 2, uma compensação de Z antiga aplicada às cegas

Eu tinha isto no `printer.cfg`, de quando usava a sonda de contato.

```ini
[gcode_macro G28]
rename_existing: G28.1
gcode:
    G28.1 {rawparams}
    SET_GCODE_OFFSET Z=-1.95
```

Depois de trocar de sonda, isso continuou sendo aplicado. Todo `G0 Z` passou a descer 1,95 mm a mais
do que eu mandava. Foi assim que eu arrastei o bico na chapa enquanto tentava posicionar
manualmente.

Confira o valor ativo na sua máquina agora.

```bash
curl -s "http://SEU_IP/printer/objects/query?gcode_move" | grep -o '"homing_origin": \[[^]]*\]'
```

Se o terceiro número não for `0.0`, existe um deslocamento escondido comendo a sua descida. Zere isso
antes de mandar qualquer movimento manual em Z.

### Armadilha 3, o recuo entre as duas passadas do homing

O `[stepper_z]` vem com `homing_retract_dist: 5`.

O Klipper encosta no gatilho, sobe esse tanto, e faz uma segunda passada lenta para confirmar. Com o
gatilho a dois milímetros de leitura, subir cinco leva a bobina a sete, fora da faixa. A segunda
passada começa cega e o chip aborta.

O sintoma engana porque a **primeira passada funciona**. Você vê a máquina descer, encostar, e só
então dar erro. Parece problema de gatilho e é problema de recuo.

Eu uso **1,5**, que deixa a bobina em 3,5 mm.

### Armadilha 4, o z_offset escrito à mão trava o SAVE_CONFIG

Se você escrever `z_offset` no `eddy.cfg`, que é um arquivo incluído, todo `SAVE_CONFIG` depois de um
`PROBE_CALIBRATE` vai falhar com esta mensagem.

```
SAVE_CONFIG section 'probe_eddy_current btt_eddy' option 'z_offset' conflicts with included value
```

O Klipper não sobrescreve por autosave um valor que veio de um include. A calibração roda, mostra o
número novo, e não consegue gravar.

A solução é deixar o `z_offset` fora do `eddy.cfg` e permitir que ele viva no bloco autosave, no fim
do `printer.cfg`. Se você está migrando de uma configuração que já tinha o valor escrito à mão,
remova a linha do arquivo incluído e acrescente o valor no bloco autosave.

```
#*# [probe_eddy_current btt_eddy]
#*# z_offset = 1.861
#*# reg_drive_current = 16
```

---

## 11. O homing e o ritual do primeiro home

Se a sua sonda original foi removida, o primeiro `G28` depois de ligar não tem como funcionar
sozinho, porque não existe referência de Z e a bobina só enxerga quatro milímetros.

O que funciona, e é seguro, é homear X e Y primeiro e depois **descer olhando**.

```
G28 X Y
G0 X215 Y215 F6000
```

Agora desça o Z pelo painel, olhando o bico, até uns dois milímetros da mesa. Use passos de dez
apenas enquanto estiver claramente longe, depois um, depois zero vírgula um. Em seguida.

```
G28 Z
```

Feito isso o Z fica homeado, e a impressora funciona normalmente até você desligar.

> Nunca mande um `G0 Z` absoluto para uma altura calculada de cabeça enquanto o Z não for confiável.
> Foi exatamente assim que eu arrastei o bico. Passo pequeno, olho no bico, e pare se encostar.

### Separando a folga de viagem da altura de mergulho

Se você tem algo alto na mesa perto da origem, como a borracha de limpeza, o `z_hop` do
`safe_z_home` cria um impasse. Ele é ao mesmo tempo a folga da viagem até o fim de curso e a altura
de início do mergulho. Você precisa de folga alta para viajar e de altura baixa para sondar, e um
número só não resolve as duas coisas.

A saída é trocar o `safe_z_home` por um `homing_override`.

```ini
[homing_override]
axes: xyz
gcode:
    {% set tudo = 'X' not in params and 'Y' not in params and 'Z' not in params %}
    {% if 'z' not in printer.toolhead.homed_axes %}
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
        G91
        G0 Z-16 F600
        G90
        G28 Z
    {% endif %}
```

Ajuste o `G0 X239.25 Y194.55` para o ponto de sondagem da sua máquina.

A lógica em português. Ele sobe dezesseis milímetros relativos, o que é seguro de qualquer altura,
inclusive com o Z virgem. Homeia X e Y com folga total sobre a borracha. Volta ao ponto de sondagem.
Desce os mesmos dezesseis milímetros relativos, devolvendo o bico exatamente à altura de onde saiu.
E aí sonda.

Repare que **não existe descida para altura absoluta** aqui dentro. Eu cheguei a escrever uma versão
que descia para Z igual a três quando o Klipper achava o Z conhecido, e isso é perigoso, porque uma
referência declarada na mão com `SET_KINEMATIC_POSITION` também conta como conhecida. A descida
viraria um mergulho de dezenas de milímetros contra a mesa.

Quem sabe que o próprio Z é confiável, como uma macro de início de impressão que acabou de homear,
se posiciona sozinho antes de chamar `G28 Z`.

O `safe_z_home` e o `homing_override` não podem coexistir. Comente um para usar o outro.

---

## 12. A malha densa

Sonda de contato leva quase um segundo por ponto. O Eddy varre em movimento contínuo, e é aqui que
ele paga o investimento. Dá para medir milhares de pontos no tempo em que a mesa estabiliza.

```ini
[gcode_macro EDDY_MALHA]
description: Malha densa de toda a area util. Ex, EDDY_MALHA BED=50 SOAK=300
variable_pontos: 70
gcode:
    {% set c = printer['gcode_macro EDDY_MALHA'] %}
    {% set bed = params.BED|default(50)|float %}
    {% set soak = params.SOAK|default(300)|int %}
    {% set n = params.PONTOS|default(c.pontos)|int %}
    M117 Aquecendo a mesa
    M140 S{bed}
    TEMPERATURE_WAIT SENSOR=heater_bed MINIMUM={bed - 1} MAXIMUM={bed + 1}
    M117 Soak
    G4 P{soak * 1000}
    M117 Homeando
    G28
    BED_MESH_CLEAR
    M117 Varrendo a mesa
    _BED_MESH_CALIBRATE METHOD=rapid_scan HORIZONTAL_MOVE_Z=2.5 PROBE_COUNT={n},{n} MESH_PPS=0 SCAN_SPEED=200
    M400
    RESPOND TYPE=command MSG="Malha pronta. Rode SAVE_CONFIG para gravar."
```

Uso normal.

```
EDDY_MALHA
SAVE_CONFIG
```

São 4900 pontos numa área de 370 por 385 milímetros, cerca de 5,3 mm de espaçamento. Contra os seis
por seis de fábrica, que dão setenta e três milímetros de espaçamento, a diferença é grande.

Três observações que valem para qualquer máquina.

O `rapid_scan` só é liberado quando a sonda é do tipo `probe_eddy_current`. Com sonda de contato o
Klipper cai no método normal sem avisar.

O `HORIZONTAL_MOVE_Z` é a altura do **bico** durante a varredura, não da bobina. Refaça a conta do
[tópico 7](#7-as-contas-que-evitam-erro-de-sensor) com a sua altura de montagem.

O tempo da rotina é quase todo soak, e o soak é o que faz a malha valer alguma coisa. Mesa fria mede
uma superfície, mesa estabilizada mede outra. Meia hora de rotina com cinco minutos de varredura é
tempo bem gasto.

---

## 13. Macros que eu uso no dia a dia

### Limpeza do bico na borracha

Passa o bico na almofada de silicone. Aceita parâmetros para reaproveitar em outros contextos.

```ini
[gcode_macro LIMPAR_BICO]
description: Limpa o bico na borracha
variable_x: 2.5
variable_y_ini: 5
variable_y_fim: 30
variable_z: 6.0
variable_passadas: 10
variable_temp: 150
gcode:
    {% set c = printer['gcode_macro LIMPAR_BICO'] %}
    {% set t = params.TEMP|default(c.temp)|float %}
    {% set n = params.PASSADAS|default(c.passadas)|int %}
    {% if 'xyz' not in printer.toolhead.homed_axes %}
        { action_raise_error("LIMPAR_BICO, eixos nao homeados") }
    {% endif %}
    {% if t > 0 %}
        M109 S{t}
    {% endif %}
    G90
    G0 Z{c.z + 6} F1200
    G0 X{c.x} Y{c.y_ini} F6000
    G0 Z{c.z} F600
    {% for i in range(n) %}
        G0 Y{c.y_fim} F6000
        G0 Y{c.y_ini} F6000
    {% endfor %}
    G0 Z{c.z + 10} F1200
```

Com `TEMP=0` ela não mexe na temperatura, o que permite chamar no meio de uma impressão.

O `variable_z` fica um milímetro abaixo da altura da borracha, o que dá a interferência que faz a
raspagem acontecer. Com borracha de sete milímetros eu uso seis.

### Purga em bloco no canto morto

Solta o filamento velho num canto e depois limpa o bico. É a ideia do coletor da Bambu adaptada.

```ini
[gcode_macro PURGA_BAMBU]
description: Purga em bloco no canto e limpa o bico. Ex, PURGA_BAMBU Q=50
variable_x: 0
variable_y: 45
variable_z: 15
variable_quantidade: 50
variable_velocidade: 150
variable_altura_segura: 15
gcode:
    {% set c = printer['gcode_macro PURGA_BAMBU'] %}
    {% set q = params.Q|default(c.quantidade)|float %}
    {% if 'xyz' not in printer.toolhead.homed_axes %}
        { action_raise_error("PURGA_BAMBU, eixos nao homeados") }
    {% endif %}
    {% if printer.extruder.temperature < 170 %}
        { action_raise_error("PURGA_BAMBU, bico frio demais para extrudar") }
    {% endif %}
    SAVE_GCODE_STATE NAME=purga_bambu
    G90
    G0 Z{c.altura_segura} F1200
    G0 X{c.x} Y{c.y} F6000
    G0 Z{c.z} F600
    M83
    G1 E{q} F{c.velocidade}
    G1 E-1.5 F2100
    G4 P1500
    G0 Z{c.altura_segura} F1200
    LIMPAR_BICO TEMP=0 PASSADAS=4
    G92 E0
    RESTORE_GCODE_STATE NAME=purga_bambu MOVE=1 MOVE_SPEED=200
```

A altura de purga muda bastante o resultado. A dois milímetros o material forma uma bolota grudada na
chapa. A quinze milímetros ele sai em fio e quase não encosta, que é o comportamento parecido com o
da Bambu. Eu uso quinze.

O volume eu tirei do próprio gcode inicial da Bambu Lab A1, que executa `G1 E50 F200`. Ela repete
esse bloco duas vezes quando está trocando material no AMS. Sem troca de cor, um bloco basta.

### Ajuste de z-offset ao vivo

O `z_offset` da sonda tem sinal invertido em relação à intuição. Valor maior aproxima o bico da mesa.
Eu errei essa direção na primeira vez e quase bati o bico, então embrulhei em macros cujo nome
descreve o que acontece com o bico.

```ini
[gcode_macro SOBE]
description: Afasta o bico da mesa. Ex, SOBE P=0.05
gcode:
    {% set p = params.P|default(0.02)|float %}
    {% set m = 1 if 'z' in printer.toolhead.homed_axes else 0 %}
    SET_GCODE_OFFSET Z_ADJUST={p} MOVE={m}

[gcode_macro DESCE]
description: Aproxima o bico da mesa. Ex, DESCE P=0.05
gcode:
    {% set p = params.P|default(0.02)|float %}
    {% set m = 1 if 'z' in printer.toolhead.homed_axes else 0 %}
    SET_GCODE_OFFSET Z_ADJUST=-{p} MOVE={m}

[gcode_macro ZOFFSET_SALVAR]
description: Grava o ajuste da sessao no z_offset da sonda e reinicia
gcode:
    {% if printer.gcode_move.homing_origin.z == 0 %}
        RESPOND TYPE=error MSG="Nada para gravar, o ajuste da sessao esta zerado."
    {% else %}
        Z_OFFSET_APPLY_PROBE
        SAVE_CONFIG
    {% endif %}
```

Com a peça imprimindo a primeira camada, vá dando `SOBE` até ficar boa, depois `ZOFFSET_SALVAR`.
Julgar pelo resultado real funciona melhor que julgar pelo papel.

### Rotina completa de z-offset

Homeia, aquece o bico para amolecer o que estiver grudado, manda esfriar enquanto limpa, e abre o
ajuste manual na temperatura em que a máquina vai imprimir.

```ini
[gcode_macro EDDY_OFFSET_FULL]
description: Homeia, limpa o bico e abre o ajuste de z-offset
variable_temp_limpeza: 200
variable_temp_offset: 150
variable_passadas: 20
gcode:
    {% set c = printer['gcode_macro EDDY_OFFSET_FULL'] %}
    G28
    M109 S{c.temp_limpeza}
    M104 S{c.temp_offset}
    M106 S255
    LIMPAR_BICO TEMP=0 PASSADAS={c.passadas}
    TEMPERATURE_WAIT SENSOR=extruder MAXIMUM={c.temp_offset + 2}
    M106 S0
    G90
    G0 Z10 F1200
    G0 X215 Y215 F6000
    G0 Z3 F600
    PROBE_CALIBRATE
```

A limpeza acontece enquanto o bico esfria, com a ventoinha ligada para acelerar. Medir o offset com o
bico a cento e cinquenta graus é proposital, porque bico quente está dilatado, e é assim que ele vai
estar imprimindo.

---

## 14. Como medir se a calibração ficou boa

No fim do `PROBE_EDDY_CURRENT_CALIBRATE` o Klipper reporta o desvio padrão.

```
probe_eddy_current: stddev=67.901 in 2482 queries
```

Esse número sozinho não diz muita coisa, porque está em hertz. Para saber o que significa em
distância, pegue a tabela gravada no fim do `printer.cfg` e veja quantos hertz correspondem a um
milímetro na altura em que o gatilho acontece.

Na minha, entre 1,5 e 2,5 mm a curva anda 23422 hertz por milímetro.

```
67,9 dividido por 23422 = 0,0029 mm
```

Cerca de três micra de repetibilidade na altura de disparo, o que é melhor que qualquer sonda de
contato que eu já usei.

Confira também duas propriedades da tabela.

Ela precisa ser **monotônica**, com a frequência caindo de forma contínua conforme a altura sobe, sem
nenhuma inversão. Se houver inversão, a corrente de excitação está errada e você volta ao
[tópico 9](#9-a-corrente-de-excitacao).

E a sensibilidade **cai conforme sobe**. Na minha, 47672 hertz por milímetro junto da mesa contra
12849 no topo da faixa. Isso não é defeito, é a natureza do sensor, e explica por que ele vira erro
quando você tenta usar de longe.

---

## 15. Tabela de sintomas

| Sintoma | Causa provável | Onde olhar |
|---|---|---|
| Homeia XY, volta pro meio, não desce e dá erro | Home falso no boot deixando o Z alto | [Armadilha 1](#armadilha-1-a-impressora-se-declara-zerada-no-boot) |
| Desce, encosta, e só então dá erro | `homing_retract_dist` grande demais | [Armadilha 3](#armadilha-3-o-recuo-entre-as-duas-passadas-do-homing) |
| Erro mesmo com o bico a dois milímetros da mesa | `reg_drive_current` errado | [Tópico 9](#9-a-corrente-de-excitacao) |
| Todo movimento em Z desce mais do que o comandado | `SET_GCODE_OFFSET` antigo ativo | [Armadilha 2](#armadilha-2-uma-compensacao-de-z-antiga-aplicada-as-cegas) |
| `SAVE_CONFIG` recusa com "conflicts with included value" | `z_offset` escrito num arquivo incluído | [Armadilha 4](#armadilha-4-o-z_offset-escrito-a-mao-trava-o-save_config) |
| Segunda amostra do `PROBE` falha | `sample_retract_dist` estourando a faixa | [Tópico 7](#7-as-contas-que-evitam-erro-de-sensor) |
| Erro durante a malha, entre pontos | `horizontal_move_z` estourando a faixa | [Tópico 7](#7-as-contas-que-evitam-erro-de-sensor) |
| Primeira camada torta de um lado só | `y_offset` errado ou assumido zero | [Tópico 5](#5-as-tres-medidas-da-montagem) |
| Gatilho na altura errada depois de mexer na corrente | Tabela não refeita | [Tópico 8](#8-a-ordem-da-calibracao) |
| Fim de curso lendo acionado com o bico no ar | Pino de sonda removida flutuando alto | [Tópico 4](#4-o-que-o-eddy-faz-e-o-que-ele-nao-faz) |
| O Eddy não aparece no computador para gravar | Botão de BOOT não foi pressionado antes do USB | [Tópico 3](#3-como-o-eddy-aparece-no-computador) |

### Dois detalhes de operação

O `FIRMWARE_RESTART` nem sempre recarrega a configuração. Quando desconfiar, force pelo serviço e
confira lendo de volta o que ficou carregado.

```bash
curl -s -X POST "http://SEU_IP/machine/services/restart?service=klipper"
```

Se você mantém a mesa aquecida parada, desligue o aquecedor alguns segundos antes de reiniciar o
serviço. Reiniciar com aquecedor ativo derruba o MCU com
`Scheduled digital out event will exceed max_duration`. O desligamento corta o aquecedor, então não
há risco, mas exige religar.

---

## Licença e garantia

Sem garantia. Mexer em sonda tem risco de bico contra a chapa, e quem está do lado da impressora é
você. Vá devagar, olhe o bico, e pare quando ficar estranho.
