# A máquina de referência

Esta é a Neptune 4 Max em que este repositório foi escrito, descrita por inteiro: o hardware que
está montado nela, cada valor que está gravado na configuração, cada coisa que foi mudada e por quê,
e o que ainda está em aberto.

Serve para duas coisas.

Se você é humano, é o exemplo completo. Os outros documentos ensinam o procedimento; este mostra
uma máquina onde o procedimento já foi até o fim.

Se você é uma IA conduzindo alguém, é a sua referência trabalhada. Quando o usuário perguntar
"e quanto devo colocar aqui", você tem um caso real inteiro para explicar o raciocínio, com a conta
que justifica cada número. **Nenhum destes números deve ser copiado para outra impressora sem
medição.** Eles são o exemplo, não a resposta.

> Os endereços de rede abaixo são da rede local do autor. Troque pelo IP da impressora do usuário.

---
---

## Acesso

| Item | Valor |
|---|---|
| IP | 192.168.68.105 |
| SSH | `ssh mks@192.168.68.105`, sem senha, chave já autorizada |
| Interface | Fluidd |
| Klipper | fork sandmmakers, `sandmmakers-ElegooNeptune4Max-v1.2.3.4-v0.13.0-51-1-0-g8dc12fe4` |
| Config | `/home/mks/klipper_config/printer.cfg` mais `eddy.cfg` e `plr.cfg` |
| Fonte | `/home/mks/klipper.sandmmakers/` |
| Log | `/home/mks/klipper_logs/klippy.log` |

Leitura de estado sem tocar na máquina

```bash
curl -s "http://192.168.68.105/printer/info"
curl -s "http://192.168.68.105/printer/objects/query?configfile=settings"
curl -s "http://192.168.68.105/printer/objects/query?toolhead&gcode_move&heater_bed&extruder"
curl -s "http://192.168.68.105/server/files/config/printer.cfg"
curl -s "http://192.168.68.105/server/gcode_store?count=30"
```

A resposta de um `POST /printer/gcode/script` não traz a saída do comando. Para ler o que o Klipper
respondeu, use o `gcode_store`.

---

## Hardware

Sonda **BTT Eddy Duo**, ligada por USB, montada com adaptador impresso. O botão de BOOT fica em cima
da placa, e para gravar firmware é preciso segurar o botão antes de plugar o USB.

A **sonda original de contato foi removida da cabeça**. O cabo dela continua ligado na placa, no pino
`PA11`, mas não existe sensor na ponta. O pino flutua em nível alto por causa do pull-up. Já foi
tentado usar `PA11` como fim de curso de Z em 2026-08-29 e o eixo desceu sem parar, sendo necessário
cortar a energia. Não repita isso sem reinstalar fisicamente um sensor.

Borracha de limpeza, almofada de silicone da Bambu Lab A1, montada em suporte impresso na região
X0 a X5 e Y0 a Y35, com sete milímetros de altura.

Guias de canto impressos para o prato magnético voltar sempre na mesma posição.

STLs usados, todos versionados na pasta [stl/](stl/) deste repositório

```
BTT-Eddy_Adapter_v05.stl
BTT-Eddy_Adapter90deg_v05.stl
nozzle-cleaner-holder-improved-lifted-pad-n4.stl
en4max-buildplatecornerguide-left.stl
en4max-buildplatecornerguide-right.stl
ecc2-poop-chute-magnetic-snap-in-place-15x10-20x10mm_magnets_logo.stl
```

Adaptador do Eddy vem de https://www.printables.com/model/928061-neptune-4-btt-eddy-adapter

Todas essas peças devem ser impressas em ABS ou ASA. Ficam sobre a mesa aquecida e ao lado do
hotend, e PLA deforma em serviço.

---

## Geometria medida

| Medida | Valor | Como foi obtida |
|---|---|---|
| Altura de montagem da bobina | 0,94 mm acima da ponta do bico | medida com o bico encostado na mesa |
| `x_offset` | -33,34 | paquímetro, bobina à esquerda do bico |
| `y_offset` | +20 | bobina atrás do bico |
| Faixa útil da bobina | 0,05 mm a 4,05 mm | tabela de calibração |

Regra que vale para toda conta neste documento

```
altura da bobina = altura do bico + 0,94
```

---

## Valores vigentes, atualizado na sessão da noite de 2026-08-29

```
probe_eddy_current btt_eddy
  x_offset            -33.34
  y_offset            20.0
  z_offset            0.300      (mora no bloco autosave, não no eddy.cfg)
  sample_retract_dist 1.0
  reg_drive_current   18
  tabela              101 pontos, gravada pelo PROBE_EDDY_CURRENT_CALIBRATE mais recente

bed_mesh
  mesh_min            20, 25
  mesh_max            390, 410
  horizontal_move_z   2.5

stepper_z
  endstop_pin         probe:z_virtual_endstop
  homing_retract_dist 1.5
```

`z_offset` e `reg_drive_current` mudaram de novo depois da tarde do dia 29, numa sessão de recalibração
que fechou junto com a malha densa. O valor anterior desta tabela era `z_offset: 1.861` e
`reg_drive_current: 16`. Meça o seu, não copie nem o de hoje nem o de ontem.

Invariantes que precisam continuar valendo, com F igual a 4,05 e M igual a 0,94

```
z_offset + sample_retract_dist   <  F      0,300 + 1,0 = 1,300   ok
horizontal_move_z + M            <  F      2,5 + 0,94 = 3,44     ok
altura de início do mergulho + M <  F
```

---

## O que foi alterado nesta sessão

### Correções que destravaram o homing

`[delayed_gcode KINEMATIC_POSITION]` desativado no `printer.cfg` e no `plr.cfg`. Ele declarava o Z
em zero poucos segundos depois de ligar, com o bico a trinta milímetros da mesa, e fazia o
`safe_z_home` subir o bico achando que estava baixo.

`[gcode_macro G28]` com `SET_GCODE_OFFSET Z=-1.95` desativado. Era compensação medida para a sonda
física antiga e continuou sendo aplicada depois da troca. Todo movimento em Z descia 1,95 mm a mais
que o comandado, e foi a causa de um bico arrastado na chapa.

`homing_retract_dist` de 5 para 1,5 no `[stepper_z]`. Com 5 a bobina ia para sete milímetros na
segunda passada do homing e o chip abortava.

`reg_drive_current` de 18 para 16, medido por `LDC_CALIBRATE_DRIVE_CURRENT CHIP=btt_eddy`. Em
seguida a tabela foi refeita com `PROBE_EDDY_CURRENT_CALIBRATE`, obrigatório depois de mexer na
corrente.

Numa sessão posterior, depois de remedir `x_offset` e `y_offset`, o comando voltou a apontar 18, e o
`z_offset` mudou de 1,861 para 0,300 junto com a tabela nova. A lição não muda: sempre que a montagem
física mexer, rode `LDC_CALIBRATE_DRIVE_CURRENT` de novo antes de confiar no número antigo.

`sample_retract_dist` de 3,0 para 1,0 e `horizontal_move_z` de 10 para 2,5, ambos estouravam a faixa
do sensor.

`x_offset` corrigido de -32,33 para -33,34 e `y_offset` de 0 para 20. O `y_offset` estava assumido
como zero e nunca havia sido medido, o que deslocava a malha inteira em vinte milímetros.

`z_offset` retirado do `eddy.cfg` e movido para o bloco autosave. Enquanto estava no arquivo
incluído, todo `SAVE_CONFIG` depois de um `PROBE_CALIBRATE` falhava com
`conflicts with included value`.

### Troca do safe_z_home por homing_override

O `z_hop` fazia duas coisas incompatíveis ao mesmo tempo, a folga da viagem até X0 e Y0, onde está a
borracha de sete milímetros, e a altura de início do mergulho, que precisa caber em quatro
milímetros. O `homing_override` separa as duas. Ele sobe dezesseis milímetros relativos, homeia X e
Y, volta ao ponto de sondagem e desce os mesmos dezesseis, devolvendo o bico à altura de onde saiu.

Não existe descida para altura absoluta dentro dele, e isso é deliberado. Uma versão intermediária
descia para Z igual a três quando o Klipper achava o Z conhecido, e isso é perigoso porque uma
referência declarada com `SET_KINEMATIC_POSITION` também conta como conhecida.

Ele ganhou uma guarda. Quando o Z não tem referência real, homeia X e Y e para com uma mensagem
escrita em vez de mergulhar às cegas.

### Macros criadas

```
LIMPAR_BICO        limpa o bico na borracha, aceita TEMP e PASSADAS
PURGA_BAMBU        purga em bloco em X0 Y45 a 15mm de altura e limpa o bico, aceita Q
LINHA_PURGA        linha de purga na faixa morta da lateral esquerda, X2.5, Y60 a Y300
SOBE / DESCE       ajusta o bico ao vivo, 0.02mm por padrão, aceita P
ZOFFSET            mostra o valor gravado e o ajuste de sessão
ZOFFSET_SALVAR     grava o ajuste no z_offset da sonda e reinicia
EDDY_OFFSET_FULL   homeia, aquece a 200, limpa esfriando até 150, abre o PROBE_CALIBRATE
EDDY_MALHA         mesa a 50, soak de 300s, malha 70x70 por varredura a 200mm/s
MANTER_MESA_50     delayed_gcode, segura a mesa em 50 quando ociosa, re-arma a cada 60s
```

`PRINT_START` refeito. Liga a mesa sem esperar, homeia se precisar, limpa o bico a 150 enquanto a
mesa sobe, vai para as temperaturas finais, faz soak, re-homeia o Z a quente, carrega a malha, purga
em bloco e faz a linha de purga.

O `SAVE_VARIABLE was_interrupted` foi movido para depois do homing. Enquanto era a primeira linha da
macro, um `G28` que falhava deixava a impressora marcada como tendo impressão interrompida sem
impressão nenhuma, e toda tentativa seguinte devolvia `SD busy`.

`m600` pausa e recua 80 mm para a troca. O `RESUME` chama `PURGA_BAMBU Q=100`, limpa o bico e volta.
Antes ele fazia `G1 E100 F200` na posição em que a peça estava parada.

### Fluidd

As macros `EDDY_OFFSET_FULL` e `EDDY_MALHA` estão pintadas de verde. A cor vive no banco do
Moonraker, namespace `fluidd`, chave `macros.stored`, num array onde cada item tem `name` minúsculo e
`color` em hex.

### Orca Slicer

Perfil `Elegoo Neptune 4 Max (0.6 nozzle) PRINCIPAL`, em
`C:\Users\Igor\AppData\Roaming\OrcaSlicer\user\default\machine\`

O gcode inicial foi reduzido a isto, porque tudo passou para as macros

```
;ELEGOO NEPTUNE 4 MAX 0.6
M220 S100
M221 S100
G90
M82
PRINT_START BED=[bed_temperature_initial_layer_single] EXTRUDER=[nozzle_temperature_initial_layer]
```

O gcode antigo chamava `MALHA_ADAPTATIVA` e `LINE_PURGE`, que são do KAMP. O KAMP está desativado
desde 2026-08-28, então essas duas linhas já vinham falhando silenciosamente.

---

## O ritual do primeiro home

Depois de ligar ou reiniciar, o Z não tem referência e o `G28` não funciona sozinho.

```
G28 X Y
G0 X215 Y215 F6000
```

Descer o Z pelo painel até uns dois milímetros da mesa, olhando o bico. Depois

```
G28 Z
```

A partir daí o Z fica homeado até desligar.

Nunca mandar um `G0 Z` absoluto calculado de cabeça enquanto o Z não for confiável. Foi assim que o
bico foi arrastado na chapa.

---

## Decisão em aberto

O ritual existe porque a sonda de contato foi removida e o Eddy só enxerga quatro milímetros. Três
caminhos foram apresentados ao Igor e ele ainda não escolheu.

**Conviver com o ritual.** Trinta segundos por ligada, risco zero. É o estado atual.

**Reinstalar um sensor de contato no `PA11`**, que está livre e com cabo já na placa. O `G28` voltaria
a funcionar de qualquer altura e o Eddy ficaria só com a malha. É a correção de raiz.

**Salvar e restaurar a altura do Z entre reinicializações.** Funciona porque o fuso segura a posição
com o motor desligado, mas se o valor ficar errado alguma vez o `G28` mergulha contra uma referência
falsa, e isso não dá erro, dá bico na mesa. É a mesma família do defeito original desta máquina.

---

## Erros conhecidos e o que cada um significa

| Sintoma | Causa |
|---|---|
| Homeia XY, volta ao meio, não desce e dá erro | Mergulho começou fora dos 4 mm |
| Desce, encosta, e só então dá erro | `homing_retract_dist` grande demais |
| Erro com o bico a 2 mm da mesa | `reg_drive_current` errado |
| Todo Z desce mais que o comandado | `SET_GCODE_OFFSET` antigo ativo |
| `SAVE_CONFIG` recusa com `conflicts with included value` | valor escrito num arquivo incluído |
| `SD busy` ao tentar imprimir | `was_interrupted` marcado sem impressão em curso |
| `Missed scheduling of next digital out event` | reinício do serviço com aquecedor ligado |

O erro `Eddy current sensor error` vem de `src/sensor_ldc1612.c`, em `check_home`, no teste
`if (data > 0x0fffffff)`. São os bits de erro do próprio chip, testados antes de qualquer movimento,
por isso ele aborta na primeira amostra. Não tem relação com a tabela `calibrate`.

O comando que mede a corrente sem mover nada é `LDC_CALIBRATE_DRIVE_CURRENT CHIP=btt_eddy`, e ele
mora em `klippy/extras/ldc1612.py`, não em `probe_eddy_current.py`.

---

## Cuidados operacionais

O `FIRMWARE_RESTART` nem sempre recarrega a configuração. Quando desconfiar, force pelo serviço e
confirme lendo de volta o que ficou carregado.

```bash
curl -s -X POST "http://192.168.68.105/machine/services/restart?service=klipper"
```

A mesa fica ligada em 50 graus quando ociosa. Desligue o aquecedor alguns segundos antes de
reiniciar o serviço, senão o MCU cai com `Scheduled digital out event will exceed max_duration`.

Backups no diretório de configuração, todos com data no nome

```
printer.cfg.bak-2026-08-29        eddy.cfg.bak-2026-08-28
printer.cfg.bak-2026-08-29c       eddy.cfg.bak-2026-08-29b
printer.cfg.bak-2026-08-29d       eddy.cfg.bak-zoff2
printer.cfg.bak-2026-08-29e       plr.cfg.bak-2026-08-29
printer.cfg.bak-purga             printer.cfg.bak-purga2
printer.cfg.bak-fixhome           printer.cfg.bak-macros2
printer.cfg.bak-zoff2             printer.cfg.bak-guard
```

---

## Pendências

A malha densa de 4900 pontos (setenta por setenta) já foi feita e salva como perfil padrão. O
`PRINT_START` carrega ela.

O `z_offset` de 0,300 saiu da recalibração mais recente e ainda não foi validado imprimindo.
