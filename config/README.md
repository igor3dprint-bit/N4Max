# Os arquivos reais da minha Neptune 4 Max

Esta pasta é o acervo: a configuração **de verdade** da máquina onde este repositório foi escrito,
copiada da impressora, não digitada à mão para o tutorial. Serve para você comparar quando algo não
bate, ou para ver como uma coisa ficou depois de pronta.

Estado destes arquivos: **03/09/2026**, com Klipper da S&M Makers rodando em Python 3, BTT Eddy com
o driver [eddy-ng](../EDDY-NG.md), e a borracha de limpeza já removida da máquina.

---

## ⚠️ Leia antes de copiar qualquer coisa

**Estes arquivos não servem para colar na sua impressora.** Sério. Alguns valores aqui são medidas
físicas da *minha* montagem, e usar os meus é a forma mais rápida de enfiar um bico na sua chapa:

| Valor | Por que é só meu |
|---|---|
| `x_offset` / `y_offset` | Depende de qual adaptador você imprimiu e de como ele ficou |
| `reg_drive_current` / `tap_drive_current` | Sai da calibração da *sua* bobina, na *sua* altura |
| `calibration_17` / `calibration_18` | A curva medida do meu sensor. Não tem significado no seu |
| `[bed_mesh default]` | O empeno da minha chapa |
| `position_endstop`, limites dos eixos | Da minha máquina, com as minhas peças |
| `serial:` do Eddy | Foi trocado por um marcador. O seu sai de `ls /dev/serial/by-id/` |

Use como **referência de estrutura e de ordem**: onde a seção fica, o que vem antes do quê, como um
comentário explica a decisão. Os números, meça os seus.

---

## O que tem em cada arquivo

| Arquivo | O que é |
|---|---|
| `printer.cfg` | A configuração principal. ~1.200 linhas, com os comentários de cada decisão e a data. É o arquivo mais útil aqui, e o mais perigoso de copiar |
| `eddy.cfg` | Só o BTT Eddy: MCU, a seção `[probe_eddy_ng]` e o `[bed_mesh]`. Incluído pelo `printer.cfg` |
| `eddyng_macros.cfg` | As macros do fluxo novo: `PRINT_START` com tap, `LINHA_KAMP` (purga) e `ZoffNGEddy` (z-offset guiado). Incluído por último, de propósito |
| `moonraker.conf` | Praticamente de fábrica. Está aqui só para mostrar que não precisa de mágica |
| `plr.cfg` | Recuperação de queda de energia, da Elegoo. **Não é meu e tem armadilha** — veja abaixo |
| `KAMP_Settings.cfg` | Herança do KAMP. O include está **desligado** hoje; a purga é a `LINHA_KAMP` |

---

## Três coisas para reparar quando for ler

**1. O `printer.cfg` é um diário, não um arquivo limpo.** Cada bloco tem um comentário com a data e
o motivo. Isso é de propósito: seis meses depois, o comentário é a única coisa que explica por que
aquele número é aquele. Vale mais que um arquivo bonito. Repare especialmente no `[stepper_z]`, que
tem um aviso comprido sobre um quase-acidente.

**2. Tem macro obsoleta lá dentro, e ela ficou de propósito.** `LIMPAR_BICO`, `PURGA_BAMBU`,
`LINHA_PURGA` e `EDDY_OFFSET_FULL` eram do tempo da borracha de limpeza, que **não existe mais na
máquina**. Nada chama elas hoje. Deixei porque o histórico ensina — mas se você copiar o
`printer.cfg` inteiro achando que está tudo ativo, vai se perder.

**3. `MANTER_MESA_50` mantém a mesa a 50 °C o tempo todo.** É um `[delayed_gcode]` que se re-arma a
cada 60 segundos. Foi decisão minha (a mesa desta máquina demora muito para aquecer), e me enganou
depois: passei uma sessão inteira achando que a mesa esquentava sozinha por bug. Se você copiar isso
sem querer, sua mesa vai ficar ligada para sempre. Comente o bloco.

**4. O `plr.cfg` zera o Z-offset.** O `RESUME_INTERRUPTED` começa com `SET_GCODE_OFFSET Z=0` e **não
passa por `G28`**. Retomar uma impressão depois de queda de luz continuava com o offset zerado até o
fim. Com o eddy-ng isso importa menos (o zero vem do tap), mas o arquivo está aqui inteiro para você
ver o que a Elegoo colocou na máquina.

---

## Como comparar com a sua

Em vez de abrir os dois lado a lado, baixe o seu e faça o diff só da seção que te interessa:

```bash
# baixe o seu (pelo Moonraker, sem precisar de SSH)
curl -s "http://SEU_IP/server/files/config/printer.cfg" -o meu-printer.cfg

# compare só uma seção
diff <(sed -n '/^\[stepper_z\]/,/^\[/p' meu-printer.cfg) \
     <(sed -n '/^\[stepper_z\]/,/^\[/p' printer.cfg)
```

---

## Sobre privacidade

Estes arquivos foram varridos antes de subir: sem senha, sem token, sem chave, sem rede de casa, sem
e-mail. O único identificador de hardware que existia — o número de série USB do Eddy — foi trocado
por um marcador, e de todo jeito você precisa do **seu**.

A senha `makerbase` que aparece nos guias é a de fábrica da Elegoo, igual em toda Neptune. Se a sua
impressora fica exposta na internet, troque — mas isso vale desde antes deste repositório existir.

---

Crédito do Klipper moderno nesta máquina: [S&M Makers](https://github.com/sandmmakers/klipper).
