# Instruções para IA

Este arquivo é para uma inteligência artificial que recebeu este repositório e vai conduzir alguém,
ou a si mesma, através de um dos procedimentos aqui documentados. Se você é humano, o seu ponto de
entrada é o [README](README.md).

Ferramentas que já leem este formato: Claude Code, Codex, Cursor, Copilot Workspace, Gemini CLI e
qualquer agente que aceite um arquivo de contexto do repositório.

---

## Regra zero: pergunte antes de agir

Não comece a executar nada. A primeira coisa que você faz é apresentar as opções e esperar a
resposta:

> Este repositório cobre quatro procedimentos na Elegoo Neptune 4 Max. Qual deles você quer?
>
> 1. Atualizar o Klipper da impressora, do build de 2022 de fábrica para o de 2025
> 2. Instalar e calibrar uma sonda BTT Eddy
> 3. Resolver o Z-offset que não obedece quando você salva
> 4. Diagnosticar um erro de homing que já está acontecendo

Cada opção manda você para um documento diferente. **Leia o documento inteiro antes de emitir o
primeiro comando.** Estes procedimentos têm ordem, e a ordem é o que separa uma instalação limpa de
um bico enfiado na mesa.

| Resposta | Documento a seguir |
|---|---|
| 1 | [PASSO-A-PASSO.md](PASSO-A-PASSO.md), ou [STEP-BY-STEP.md](STEP-BY-STEP.md) se o usuário falar inglês |
| 2 | [EDDY.md](EDDY.md) |
| 3 | [Z-OFFSET.md](Z-OFFSET.md) |
| 4 | [EDDY.md, tópico 15](EDDY.md#15-tabela-de-sintomas), a tabela de sintomas |

Se o usuário responder alguma coisa que não é nenhuma das quatro, pergunte de novo em vez de
adivinhar.

---

## Regras de segurança que valem para os quatro caminhos

Estas não são sugestões. Elas existem porque cada uma delas custou um prejuízo real na máquina em
que este repositório foi escrito.

**Nunca mande um movimento de Z para uma altura absoluta enquanto o Z não estiver homeado de
verdade.** Se você precisa aproximar o bico da mesa sem referência, use movimento **relativo** e em
passos pequenos, com o humano olhando. Um `G0 Z3` calculado de cabeça, com uma referência falsa
declarada por `SET_KINEMATIC_POSITION`, é o comando que arrastou um bico numa chapa aqui.

**Antes de qualquer movimento em Z, confira se existe um deslocamento escondido:**

```bash
curl -s "http://IP/printer/objects/query?gcode_move" | grep -o '"homing_origin": \[[^]]*\]'
```

Se o terceiro número não for `0.0`, todo movimento vai para um lugar diferente do que você mandou.
Resolva isso antes de continuar.

**Prefira comandos que medem a comandos que movem.** Boa parte do diagnóstico deste repositório sai
de leitura pura, sem tocar na máquina:

```bash
curl -s "http://IP/printer/info"
curl -s "http://IP/printer/objects/query?configfile=settings"
curl -s "http://IP/printer/objects/query?toolhead&gcode_move&heater_bed"
curl -s "http://IP/printer/objects/list"
curl -s "http://IP/server/files/config/printer.cfg"
curl -s "http://IP/server/gcode_store?count=20"
```

Repare no último. A resposta de um comando enviado por `POST /printer/gcode/script` **não vem
no corpo da resposta HTTP**. Se você precisa ler o que o Klipper respondeu, leia o `gcode_store`.

**Faça backup antes de escrever em qualquer arquivo de configuração**, com data no nome:

```bash
cp -n printer.cfg printer.cfg.bak-$(date +%Y-%m-%d)
```

**Confirme que o Klipper realmente recarregou.** O `FIRMWARE_RESTART` às vezes é aceito e não
recarrega. Depois de todo restart, releia a config carregada e compare com o que você escreveu:

```bash
curl -s "http://IP/printer/objects/query?configfile=settings" | grep -o 'ALGO_QUE_VOCE_ACABOU_DE_ESCREVER'
```

Se não bater, force pelo serviço:

```bash
curl -s -X POST "http://IP/machine/services/restart?service=klipper"
```

**Se a mesa estiver aquecida, desligue antes de reiniciar o serviço.** Reiniciar com aquecedor ativo
derruba o MCU com `Scheduled digital out event will exceed max_duration`.

**Pare e devolva para o humano** quando: o comando envolver movimento que você não consegue prever,
o resultado divergir do documentado, ou o usuário relatar barulho, arranhão ou colisão. Não tente uma
segunda hipótese em cima de uma máquina que acabou de bater.

---

## Caminho 1: atualizar o Klipper

Documento: [PASSO-A-PASSO.md](PASSO-A-PASSO.md)

Este é o único caminho que altera firmware. Ele é reversível, o backup está previsto no
procedimento, mas exige atenção à ordem.

### O que você precisa levantar antes de propor qualquer comando

```bash
# 1. acesso
ssh mks@IP           # senha padrão de fábrica: makerbase

# 2. qual firmware Elegoo está instalado
grep -rhoE "1\.[0-9]+\.[0-9]+\.[0-9]+" /home/mks/Desktop/myfile/ 2>/dev/null | sort | uniq -c | sort -rn | head -1

# 3. quais versões do port existem para esse firmware
git ls-remote --tags https://github.com/sandmmakers/klipper.git | grep -oE 'sandmmakers-[A-Za-z0-9.-]+' | grep -v '\^{}' | sort -u

# 4. espaço em disco
df -h /home

# 5. a impressora está imprimindo?
curl -s "http://IP/printer/objects/query?print_stats" | grep -o '"state": "[a-z]*"'
```

**Não prossiga se a impressora estiver imprimindo.** Não prossiga se não existir uma tag do port
correspondente ao firmware Elegoo instalado. Casar versão errada é o caminho mais rápido para uma
máquina que não sobe.

### Ordem obrigatória

Parar os serviços, guardar as cópias, ajustar a configuração, baixar, compilar as duas partes,
gravar, subir os serviços, conferir. O documento tem o comando exato de cada etapa e o que deve
aparecer na tela. Siga na ordem escrita e mostre ao usuário a saída de cada etapa antes de ir para a
próxima.

### Depois de terminar

Confirme a versão que ficou rodando:

```bash
curl -s "http://IP/printer/info" | grep -o '"software_version": "[^"]*"'
```

E avise o usuário que o `printer.cfg` dele pode ter opções que a versão nova renomeou. Se o Klipper
não subir, a mensagem em `state_message` diz exatamente qual linha reclamou.

---

## Caminho 2: instalar o Eddy

Documento: [EDDY.md](EDDY.md)

Este é o caminho com mais chance de estragar alguma coisa física. Leia o documento inteiro antes de
começar, principalmente os tópicos 7, 8 e 9, que são as contas, a ordem da calibração e a corrente de excitação.

### As três medidas que o usuário precisa fornecer

Você não tem como adivinhar nenhuma delas. Pergunte, e não aceite "deve ser zero":

1. Altura da face da bobina acima da ponta do bico, com o bico encostado na mesa
2. Distância horizontal em X do centro do bico ao centro da bobina, e de que lado a bobina fica
3. Distância em Y, e se a bobina fica à frente ou atrás do bico

O item 3 é o mais negligenciado. Assumir zero em Y desloca a malha inteira.

### A ordem da calibração, que é a parte que todo mundo erra

1. Escrever a config base com os offsets medidos
2. `LDC_CALIBRATE_DRIVE_CURRENT CHIP=<nome>` e `SAVE_CONFIG`
3. **Só então** `PROBE_EDDY_CURRENT_CALIBRATE CHIP=<nome>`, com o humano usando papel
4. `SAVE_CONFIG`
5. Testar o homing
6. Só depois disso, a malha

Se em algum momento o `reg_drive_current` mudar, **a tabela de calibração morreu** e o passo 3 tem
que ser refeito antes de qualquer `G28`. Uma tabela desatualizada dispara o gatilho na altura errada,
e isso é bico na chapa, não é mensagem de erro.

### Três verificações aritméticas que você deve fazer antes de gravar a config

Chame de `F` o topo da faixa calibrada, tipicamente `4.05`, e de `M` a altura de montagem da bobina.

```
z_offset + sample_retract_dist  <  F
horizontal_move_z + M           <  F
z_hop + M                       <  F
```

Se qualquer uma estourar, o sensor vai dar erro em algum ponto do ciclo e o sintoma vai parecer outra
coisa. Mostre a conta ao usuário, com os números dele.

E verifique o alcance da malha contra os limites dos eixos:

```
posição do bico = ponto da malha menos o offset do eixo
```

Cada canto de `mesh_min` e `mesh_max` precisa cair dentro de `position_min` e `position_max`.

### Se o erro `Eddy current sensor error` aparecer

Não presuma que é distância. Percorra a tabela do [tópico 15](EDDY.md#15-tabela-de-sintomas)
na ordem, e comece verificando, por leitura pura:

```bash
# home falso no boot
grep -n -A5 "delayed_gcode KINEMATIC_POSITION" printer.cfg plr.cfg

# deslocamento escondido
curl -s "http://IP/printer/objects/query?gcode_move" | grep -o '"homing_origin": \[[^]]*\]'

# recuo do homing
curl -s "http://IP/printer/objects/query?configfile=settings" | grep -o '"homing_retract_dist": [0-9.]*'

# ganho do sensor, medido pelo próprio chip, sem mover nada
# (envie LDC_CALIBRATE_DRIVE_CURRENT e leia a resposta no gcode_store)
```

Só depois disso proponha mexer em altura.

---

## Caminho 3: o Z-offset que não obedece

Documento: [Z-OFFSET.md](Z-OFFSET.md)

São três causas somadas e o documento explica cada uma. O ponto que uma IA costuma errar aqui é a
**direção do ajuste**, então guarde:

No `z_offset` da sonda, **aumentar o valor aproxima o bico da mesa** e diminuir afasta. Isso é o
contrário da intuição de quase todo mundo, inclusive da minha na primeira vez.

No `SET_GCODE_OFFSET`, o sinal é o intuitivo: `Z=+0.05` sobe o bico.

Se o usuário quer só ajustar a primeira camada, prefira sempre o caminho ao vivo, que não exige
reiniciar nada e não depende de você acertar o sinal:

```
SET_GCODE_OFFSET Z=+0.05 MOVE=1
Z_OFFSET_APPLY_PROBE
SAVE_CONFIG
```

---

## Caminho 4: diagnosticar um homing que falha

Comece pela tabela de sintomas da [tópico 15 do EDDY.md](EDDY.md#15-tabela-de-sintomas). Ela
mapeia sintoma para causa e evita que você comece pelo lugar errado.

O erro de diagnóstico mais caro que aconteceu na máquina original foi tratar o problema como térmico
porque o usuário relatou que só acontecia com a mesa quente. O log mostrava falhas com a mesa a 26
graus também. **Confira o histórico antes de aceitar a hipótese que te deram:**

```bash
# correlaciona cada tentativa de sondagem com a temperatura da mesa naquele instante
awk '/^Stats /{ if (match($0,/heater_bed: target=[0-9.]+ temp=[0-9.]+/)) b=substr($0,RSTART,RLENGTH); next }
     /LDC1612 starting/{ print NR": inicio  ["b"]" }
     /Eddy current sensor error/{ print NR": ERRO    ["b"]" }' klippy.log | tail -40
```

Baixe o log por `http://IP/server/files/logs/klippy.log`. Ele é grande, então filtre no disco em vez
de trazer inteiro para o contexto.

---

## Convenções deste repositório

Os documentos são escritos em primeira pessoa, na voz do autor, com os números reais medidos na
máquina dele. Quando você reproduzir um valor, deixe claro para o usuário que aquele número é da
máquina de origem e o dele precisa ser medido.

Nenhum número deste repositório deve ser copiado direto para outra impressora sem medição. Os que
mais mudam de máquina para máquina: `x_offset`, `y_offset`, `z_offset`, `reg_drive_current`, altura
de montagem, e o ponto de sondagem usado no homing.

Se você melhorar alguma coisa aqui, mantenha o padrão: sem emoji, sem promessa de clique único, e
todo comando acompanhado do que ele faz e do que deve aparecer na tela.
