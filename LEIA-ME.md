# Klipper novo na Neptune 4 Max — do jeito fácil

> 🇺🇸 [English version](GUIDE-EN.md)

A Elegoo Neptune 4 Max sai de fábrica com um Klipper de **2022**. Este pacote instala uma versão de **2025** (a 0.13.0, portada pela S&M Makers), sem você precisar digitar comando nenhum.

Você clica em três arquivos, na ordem. O resto é automático.

> 🙏 **Sem a S&M Makers, nada disto existiria.** Todo o trabalho de verdade é dele — aqui é só o
> empacotamento. Assista o vídeo do **[@SandMMakers](https://www.youtube.com/watch?v=Aoy3sI1lv1g)**
> e leia o [tutorial original](https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html).

**Não precisa** de pendrive, cartão SD, chave de fenda, nem abrir a impressora.

---

## Antes de começar

Confira estas quatro coisas:

- [ ] A impressora está **ligada** e **não está imprimindo**
- [ ] A impressora está na **mesma rede** que o seu computador (wifi ou cabo)
- [ ] Você sabe o **IP da impressora** (explico abaixo como descobrir)
- [ ] Seu Windows tem o **Cliente OpenSSH** (o Windows 10 e 11 já vêm com ele)

### Como descobrir o IP da impressora

No painel da impressora, vá em **Settings** (Configurações). O IP aparece na tela, algo como `192.168.0.50` ou `192.168.68.105`.

Se não achar por lá, entre na página de administração do seu roteador e procure na lista de aparelhos conectados por um nome tipo `mkspi`.

Você só digita esse IP uma vez. O programa guarda e reusa nos passos seguintes.

---

## Os três passos

Clique duas vezes em cada arquivo, na ordem:

### 1️⃣ `1-Configurar-Acesso.bat`

Cria uma chave de acesso e instala na impressora, pra não ficar pedindo senha toda hora.

Vai pedir o IP e depois a **senha da impressora**. A senha padrão é:

```
makerbase
```

> **Atenção:** enquanto você digita a senha, **nada aparece na tela** — nem asteriscos, nem pontinhos. Parece que o teclado não está funcionando. É proposital, é assim mesmo. Digite e aperte Enter.

Só precisa fazer isso uma vez.

### 2️⃣ `2-Verificar-Impressora.bat`

Só olha, não muda nada. Descobre a versão do firmware da sua impressora e diz se existe um Klipper novo compatível.

Se ele disser "TUDO CERTO", siga em frente. Se disser outra coisa, leia a seção de problemas no final.

### 3️⃣ `3-Instalar-Klipper.bat`

Faz a instalação. Vai pedir pra você digitar `SIM` pra confirmar.

**Demora de 5 a 15 minutos.** Em vários momentos vai parecer que travou — não travou, é a impressora compilando. Não feche a janela, não desligue nada.

No fim a impressora reinicia sozinha e o programa confirma a versão instalada.

---

## Prefere que uma IA faça?

Se você usa Claude Code (ou outro agente com acesso ao terminal), entregue o arquivo **`USAR-COM-CLAUDE.md`** pra ele e peça pra executar. Tem o procedimento completo, as armadilhas e as regras de segurança. Dá no mesmo — é só outro jeito de chegar lá.

---

## Depois de instalar

**Faça isso antes de imprimir qualquer coisa**, no painel da impressora:

1. **Nivelamento automático da mesa** (auto bed leveling)
2. **Ajustar o Z-offset**

A calibração antiga não é aproveitada de forma confiável pelo Klipper novo.

> 🔧 **Se o Z-offset parecer que não faz efeito nenhum, não é você** — esta máquina tem um defeito
> conhecido. A causa e a solução estão em **[EXTRA-Z-OFFSET.md](EXTRA-Z-OFFSET.md)**.

### Duas coisas estranhas que são normais

Não se assuste, são limitações conhecidas e documentadas:

**1. Erro ao salvar o nivelamento.** Depois de nivelar pelo painel e apertar salvar, pode aparecer uma mensagem de erro no console do Fluidd/Mainsail. É inofensivo. Mande um `FIRMWARE_RESTART` (ou só reinicie a impressora) e pronto — o nivelamento **foi salvo** e será usado.

**2. Os "modos de performance" mudaram.** Aqueles modos de velocidade que você escolhe no painel usavam um ajuste chamado `max_accel_to_decel`, que foi removido do Klipper. Agora eles não controlam mais a desaceleração. Na prática: pode ser que você note diferença nos cantos das peças. Se incomodar, dá pra ajustar manualmente no `printer.cfg` (procure por `minimum_cruise_ratio`).

---

## Deu ruim? Voltando atrás

Rode `4-Voltar-Ao-Original.bat`.

Ele devolve tudo ao estado de fábrica usando as cópias de segurança que foram feitas automaticamente durante a instalação.

As cópias ficam na impressora, nestes lugares:

| O que | Onde ficou guardado |
|---|---|
| Klipper original | `~/klipper.stock.vSUAVERSAO` |
| Programa do MCU | `/usr/local/bin/klipper_mcu.stock.vSUAVERSAO` |
| Sua configuração | `~/klipper_config/printer.cfg.stock.vSUAVERSAO` |

---

## Problemas comuns

### "NAO CONSEGUI FALAR COM A IMPRESSORA"
O IP está errado ou a impressora está desligada. Rode o arquivo de novo e responda `n` quando ele perguntar se quer usar o IP salvo, aí digite o correto.

### A senha `makerbase` não funciona
Alguém trocou a senha, ou algum outro mod foi instalado antes (OpenNept4une, por exemplo). Se você não souber a senha atual, não dá pra continuar por aqui.

### "seu Windows nao tem o SSH instalado"
Vá em **Configurações → Aplicativos → Recursos opcionais → Adicionar recurso** e instale o **Cliente OpenSSH**. Depois rode de novo.

### "A impressora nao conseguiu acessar a internet"
A impressora precisa de internet pra baixar o Klipper novo — não basta ela enxergar o seu PC. Confira o wifi dela.

### E se aparecer que meu firmware não tem versão?

Aí o caminho é mais chato, e é **manual**. Significa que o firmware da Elegoo instalado na sua impressora não tem uma versão correspondente do Klipper novo, e você precisa primeiro atualizar o firmware da Elegoo.

Resumo do processo (o detalhe está no site oficial, link no fim):

1. Baixe o firmware novo em [elegoo.com/pages/download](https://www.elegoo.com/pages/download)
2. **Placa principal:** copie a pasta `ELEGOO_UPDATE_DIR` para um pendrive vazio, espete na impressora, e no painel vá em Settings → About Machine → seta embaixo → Confirm. Leva 1 a 2 minutos.
3. **Tela:** copie o arquivo `.tft` para o cartão SD que veio com a impressora. Aqui precisa desmontar a tampa de trás da tela com uma chave hexagonal de 2 mm, colocar o SD, ligar, esperar atualizar, e depois abrir de novo pra tirar o cartão.
4. Refaça o nivelamento e o Z-offset.

Só depois disso rode o `2-Verificar-Impressora.bat` de novo.

> ⚠️ A atualização da Elegoo **pode apagar seu `printer.cfg`** e pode forçar o nivelamento pro modo Standard (6x6). Se você usava o **Professional Mode**, vai precisar configurar de novo.

---

## O que estes arquivos fazem, por dentro

Pra quem quiser conferir antes de rodar — nada aqui é caixa-preta:

| Arquivo | O que faz |
|---|---|
| `1-Configurar-Acesso.bat` | Cria uma chave SSH e copia a pública pra impressora |
| `2-Verificar-Impressora.bat` | Roda `scripts/verificar.sh` — só leitura |
| `3-Instalar-Klipper.bat` | Roda `scripts/instalar.sh` |
| `4-Voltar-Ao-Original.bat` | Roda `scripts/reverter.sh` |
| `_comum.bat` | Pergunta e guarda o IP em `ip.txt` |
| `scripts/*.sh` | Os comandos que rodam dentro da impressora |

O MCU STM32 **não é tocado** em momento nenhum. O site oficial descreve como atualizá-lo, mas o próprio autor desaconselha, porque exige desmontar a impressora e o risco não compensa.

---

## Créditos

Todo o trabalho pesado — portar o Klipper moderno para a Neptune 4 Max — é da **S&M Makers**:

- Instruções originais: https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html
- Repositório: https://github.com/sandmmakers/klipper
- Vídeo: https://www.youtube.com/watch?v=Aoy3sI1lv1g

Este pacote é só um empacotamento em `.bat` pra facilitar a vida de quem não tem intimidade com terminal.

**Sem garantia.** Mexer em firmware tem risco. Existe o caminho de volta e ele funciona, mas quem está do lado da impressora é você.
