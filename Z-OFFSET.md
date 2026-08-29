# EXTRA, o Z-offset que não obedece (e como resolver)

> Português abaixo · [English version below](#english-the-z-offset-that-refuses-to-obey)

Este documento é um **extra**. A instalação do Klipper novo (os passos 1, 2 e 3) funciona sem ele.
Mas se, depois de instalar, o seu Z-offset parecer "ignorado", é aqui que está a explicação.

Tudo o que está escrito abaixo foi descoberto **na prática**, numa Neptune 4 Max real, em julho de 2026,
depois de perder quatro rodadas de calibração com diagnósticos errados. Está registrado justamente
para você não perder as mesmas quatro rodadas.

---

## O sintoma

Você ajusta o Z-offset, salva, e **quase nada muda**.

Foi medido. Mudar o `z_offset` de `0.0` para `2.110`, uma diferença de **2,11 mm**, deslocou o ponto
de contato real do bico em **0,05 mm**. Cerca de 2% do que foi pedido.

Não é impressão sua, não é bico entupido, não é mesa torta. É a máquina.

---

## As três causas (nesta ordem de importância)

### 1. O módulo da tela apaga o seu z_offset quando você salva

A Elegoo/Makerbase roda um módulo próprio chamado `znp_tjc_klipper` (é ele que faz a tela LCD
conversar com o Klipper). Esse módulo **reescreve o `[probe] z_offset` para zero** toda vez que um
`SAVE_CONFIG` acontece.

Reproduzido três vezes, sempre igual.

```
probe: z_offset: 2.110
save_config: set [probe] z_offset = 0.000
```

**Consequência prática.** Nesta máquina, **não use** `SAVE_CONFIG` nem `Z_OFFSET_APPLY_PROBE` para
gravar o Z. O que você salvar vira zero.

### 2. A impressora se declara "zerada" alguns segundos depois de ligar, sem ter homeado

Existe no `plr.cfg` (o arquivo da recuperação de queda de energia) um bloco assim.

```ini
[delayed_gcode KINEMATIC_POSITION]
initial_duration:0.2
gcode:
      SET_KINEMATIC_POSITION X=0
      SET_KINEMATIC_POSITION Y=0
      SET_KINEMATIC_POSITION Z=0
```

Traduzindo, poucos segundos após **qualquer** inicialização, a impressora passa a acreditar que está
na posição zero, esteja o bico onde estiver, a 5 mm ou a 200 mm da mesa.

O mesmo bloco quebra o homing do BTT Eddy pelo mesmo motivo, e está descrito com mais detalhe na
[Armadilha 1 do EDDY.md](EDDY.md#armadilha-1-a-impressora-se-declara-zerada-no-boot).

Isso sabota qualquer teste de Z feito logo após um restart. Foi exatamente o que aconteceu aqui.
Quatro tentativas seguidas de calibração deram resultado sem sentido, porque todo teste vinha logo
depois de reiniciar.

> **Regra de ouro.** Nesta máquina, **todo teste de Z exige um `G28` explícito antes.** Sempre.
>
> **Risco de verdade.** Uma impressora que se acha referenciada sem ter homeado **aceita** um
> `G1 Z-5` e desce contra a mesa. Não mande comando de Z sem homear.

### 3. O `PROBE_CALIBRATE` repete o mesmo valor errado

Ele devolveu `2.110` três vezes seguidas. Isso parece confiança, mas não é.
**Repetibilidade não é correção.** Um instrumento pode errar sempre igual.

O teste que valeu foi comparar o `PROBE` (o que o Klipper *acha* que a altura é) com a medida real
feita por um **calibre de lâmina** entre o bico e a mesa.

---

## A solução que funciona

Já que o valor não sobrevive no `[probe]`, ele passa a viver **numa macro**. Você embrulha o `G28`
original e aplica a correção logo depois de homear.

Cole isto no fim do seu `printer.cfg`.

```ini
[gcode_macro G28]
rename_existing: G28.1
gcode:
    G28.1 {rawparams}                  # chama o home original da máquina
    SET_GCODE_OFFSET Z=-2.0            # <<< TROQUE por SEU valor medido
```

Depois, rode `FIRMWARE_RESTART`.

### Como descobrir o SEU valor (não use o -2.0 deste exemplo)

O `-2.0` é o valor **desta** impressora específica. Bico diferente, sonda diferente, mesa diferente =
valor diferente. Copiar o número dos outros é como calçar o sapato dos outros.

Passo a passo, pelo console do Fluidd ou Mainsail.

1. `G28`, sempre comece homeando (lembre da causa nº 2)
2. `G1 Z0 F300`, leva o bico até onde a máquina acha que é o zero
3. Tente passar uma folha de papel comum entre o bico e a mesa.
   - **Passa folgado?** O bico está alto → o seu valor é **negativo** (aproxima o bico)
   - **Não passa de jeito nenhum?** O bico está baixo → o seu valor é **positivo** (afasta o bico)
4. Ajuste em passos pequenos e vá testando com `SET_GCODE_OFFSET Z=-0.5`, depois `G1 Z0 F300`, repita
5. O ponto certo é quando o papel desliza com uma leve raspagem
6. Anote o número que funcionou e coloque na macro acima

Para mais precisão, use um **calibre de lâmina** (feeler gauge) em vez do papel. Uma folha comum tem
cerca de 0,1 mm, e no calibre você escolhe a espessura e sabe exatamente qual é.

---

## O efeito colateral que quebra impressão

Isto é a parte que ninguém avisa, e que aqui **destruiu uma impressão de verdade**.

O `SET_GCODE_OFFSET` desloca **todos** os Z que a máquina recebe, não só o da primeira camada.
Inclui os Z das suas macros de limpeza de bico, de purga, de estacionamento.

Foi o que aconteceu, existia uma rotina que limpava o bico na borracha a `Z3.8`. Com o offset de
`-2.0`, esse `Z3.8` virou **1,8 mm reais**, e o bico foi enfiado dentro da borracha, oito vezes
seguidas, a alta velocidade. O eixo Z perdeu passo **em silêncio** e o resto da peça saiu raspando a mesa.

**O que fazer depois de aplicar o offset.**

- Abra o `printer.cfg` e procure **toda** linha com `Z` absoluto dentro de macro
  (limpeza de bico, purga, `PARK`, start gcode)
- Some o seu offset a cada uma delas. No exemplo, `Z3.8` precisou virar `Z5.8`
- Na primeira vez, fique **com a mão no botão de emergência** e assista

Do lado bom, os `Z0.2` da linha de purga, que antes ficavam 2 mm no ar sem encostar, passaram a
encostar de verdade.

---

## Resumo em cinco linhas

| Problema | Resposta |
|---|---|
| `SAVE_CONFIG` zera meu z_offset | Não use. Guarde o valor numa macro `G28` |
| Teste de Z dá resultado sem sentido | Você não homeou. `G28` antes de **todo** teste |
| `PROBE_CALIBRATE` repete e mesmo assim erra | Confie no papel/calibre, não no número da tela |
| Bico começou a bater na borracha | Some o offset aos `Z` absolutos das suas macros |
| Que valor eu uso? | O **seu**, medido. Nunca o de outra pessoa |

---

## Lição que serve para qualquer impressora

**Medição vence teoria.** Nesta sessão foram três diagnósticos errados seguidos, todos por raciocinar
em vez de medir. Um calibre de lâmina resolveu em um minuto o que meia hora de teoria não resolveu.

**Confirme o estado antes de testar.** Quatro rodadas foram perdidas porque a máquina estava sem
referência e recusava os comandos de Z em silêncio, sem erro, sem aviso, sem mover.

> O Klipper moderno nesta máquina é trabalho da **S&M Makers**.
> [Vídeo do @SandMMakers](https://www.youtube.com/watch?v=Aoy3sI1lv1g) ·
> [tutorial original](https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html)

---
---

# English, the Z-offset that refuses to obey

This document is an **extra**. Installing the new Klipper (steps 1, 2 and 3) works fine without it.
But if your Z-offset seems to be ignored after the install, the explanation is here.

Everything below was found **the hard way**, on a real Neptune 4 Max, in July 2026, after four
wasted calibration rounds chasing the wrong causes. It is written down so you don't waste the same four.

---

## The symptom

You adjust the Z-offset, you save, and **almost nothing changes**.

Measured on a real machine. Changing `z_offset` from `0.0` to `2.110`, a **2.11 mm** difference,
moved the actual nozzle contact point by **0.05 mm**. Roughly 2% of what was asked for.

It is not your imagination, not a clogged nozzle, not a warped bed. It is the machine.

---

## The three causes (in order of importance)

### 1. The LCD module wipes your z_offset when you save

Elegoo/Makerbase ships its own module called `znp_tjc_klipper` (it is what lets the LCD screen talk
to Klipper). That module **rewrites `[probe] z_offset` back to zero** every time a `SAVE_CONFIG` runs.

Reproduced three times, identical every time.

```
probe: z_offset: 2.110
save_config: set [probe] z_offset = 0.000
```

**What this means for you.** On this machine, **do not use** `SAVE_CONFIG` or `Z_OFFSET_APPLY_PROBE`
to store your Z. Whatever you save becomes zero.

### 2. The printer declares itself "at zero" seconds after boot, without ever homing

Inside `plr.cfg` (the power-loss-recovery file) there is a block like this.

```ini
[delayed_gcode KINEMATIC_POSITION]
initial_duration:0.2
gcode:
      SET_KINEMATIC_POSITION X=0
      SET_KINEMATIC_POSITION Y=0
      SET_KINEMATIC_POSITION Z=0
```

In plain words, a few seconds after **any** startup, the printer starts believing it is at position
zero, no matter where the nozzle actually is, 5 mm or 200 mm above the bed.

The same block also breaks homing on the BTT Eddy probe for the same reason, described in more
detail in [EDDY.md's Armadilha 1](EDDY.md#armadilha-1-a-impressora-se-declara-zerada-no-boot)
(Portuguese only).

This ruins any Z test done right after a restart. That is exactly what happened here. Four
calibration attempts in a row produced nonsense, because every test followed a restart.

> **Golden rule.** On this machine, **every Z test requires an explicit `G28` first.** Always.
>
> **Real danger.** A printer that thinks it is homed when it is not **will accept** a `G1 Z-5`
> and drive straight into the bed. Never send a Z command without homing.

### 3. `PROBE_CALIBRATE` repeats the same wrong number

It returned `2.110` three times in a row. That looks like confidence, but it isn't.
**Repeatability is not accuracy.** An instrument can be consistently wrong.

The test that actually settled it was comparing `PROBE` (what Klipper *believes* the height is)
against a real measurement taken with a **feeler gauge** between nozzle and bed.

---

## The fix that works

Since the value will not survive inside `[probe]`, it lives **inside a macro** instead. You wrap the
original `G28` and apply the correction right after homing.

Paste this at the end of your `printer.cfg`.

```ini
[gcode_macro G28]
rename_existing: G28.1
gcode:
    G28.1 {rawparams}                  # call the machine's original home
    SET_GCODE_OFFSET Z=-2.0            # <<< REPLACE with YOUR measured value
```

Then run `FIRMWARE_RESTART`.

### How to find YOUR value (do not use the -2.0 from this example)

`-2.0` is the value for **that one** printer. Different nozzle, different probe, different bed =
different value. Copying someone else's number is like wearing someone else's shoes.

Step by step, from the Fluidd or Mainsail console.

1. `G28`, always start by homing (remember cause #2)
2. `G1 Z0 F300`, move the nozzle to where the machine thinks zero is
3. Try sliding a sheet of ordinary paper between nozzle and bed.
   - **Slides freely?** Nozzle is too high → your value is **negative** (brings it closer)
   - **Won't fit at all?** Nozzle is too low → your value is **positive** (lifts it away)
4. Adjust in small steps and retest with `SET_GCODE_OFFSET Z=-0.5`, then `G1 Z0 F300`, repeat
5. It is right when the paper slides with slight drag
6. Write down the number that worked and put it into the macro above

For better precision use a **feeler gauge** instead of paper. A normal sheet is roughly 0.1 mm,
and with a gauge you pick the thickness and know exactly what it is.

---

## The side effect that ruins prints

This is the part nobody warns you about, and it **destroyed a real print** here.

`SET_GCODE_OFFSET` shifts **every** Z the machine receives, not just the first layer. That includes
the Z values inside your nozzle-wipe macros, purge routines and park positions.

Here is what happened. A routine wiped the nozzle on a rubber pad at `Z3.8`. With a `-2.0` offset,
that `Z3.8` became **1.8 mm in reality**, and the nozzle was driven into the rubber, eight times in a
row, at high speed. The Z axis lost steps **silently**, and the rest of the part printed scraping the bed.

**What to do after applying the offset.**

- Open `printer.cfg` and find **every** absolute `Z` inside a macro
  (nozzle wipe, purge, `PARK`, start gcode)
- Add your offset to each one. In the example, `Z3.8` had to become `Z5.8`
- The first time, **keep your hand on the emergency stop** and watch it

The upside, the `Z0.2` of the purge line, which used to float 2 mm above the bed touching nothing,
finally touches.

---

## Five-line summary

| Problem | Answer |
|---|---|
| `SAVE_CONFIG` zeroes my z_offset | Don't use it. Keep the value in a `G28` macro |
| Z tests give nonsense results | You didn't home. `G28` before **every** test |
| `PROBE_CALIBRATE` repeats and is still wrong | Trust the paper/gauge, not the number on screen |
| Nozzle started slamming into the wipe pad | Add your offset to the absolute `Z` in your macros |
| Which value do I use? | **Yours**, measured. Never someone else's |

---

## A lesson that applies to any printer

**Measurement beats theory.** Three wrong diagnoses in a row here, all from reasoning instead of
measuring. A feeler gauge solved in one minute what half an hour of theory could not.

**Confirm the state before testing.** Four rounds were lost because the machine had no reference and
was silently refusing Z commands, no error, no warning, no movement.
