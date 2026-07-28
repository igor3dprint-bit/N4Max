# Neptune 4 Max — Klipper novo, do jeito fácil
### Modern Klipper on the Elegoo Neptune 4 Max, the easy way

**🇧🇷 [Guia completo em português](LEIA-ME.md) · 🇺🇸 [Full guide in English](GUIDE-EN.md) · 🌐 [Página web / Web page](https://igor3dprint-bit.github.io/Neptune4Max-Klipper-Facil/)**

---

## 🙏 Crédito antes de tudo / Credit before anything else

🇧🇷 **Sem a S&M Makers, nada disto existiria.** Todo o trabalho de verdade — portar o Klipper moderno
para a Neptune 4 Max — é dele. Este repositório só empacota o trabalho dele em três cliques.
Se isto te ajudou, o agradecimento vai pra lá.

🇺🇸 **Without S&M Makers, none of this would exist.** All the real work — porting modern Klipper to
the Neptune 4 Max — is theirs. This repository only wraps that work into three clicks.
If this helped you, that is where the thanks belong.

| | |
|---|---|
| ▶️ **Vídeo / Video** | https://www.youtube.com/watch?v=Aoy3sI1lv1g — **@SandMMakers** |
| 📄 **Tutorial original** | https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html |
| 💾 **Código / Code** | https://github.com/sandmmakers/klipper |

---

## 🇧🇷 Em uma frase

A Elegoo Neptune 4 Max sai de fábrica com um Klipper de **2022**. Este pacote instala a versão de
**2025** — sem terminal, sem pendrive, sem chave de fenda. Você clica em três arquivos, na ordem,
e o resto é automático.

O trabalho pesado de portar o Klipper moderno é da [S&M Makers](https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html).
Este repositório é o empacotamento que faz isso caber em três cliques.

**Começar:** leia o **[LEIA-ME.md](LEIA-ME.md)** e siga os três passos.

## 🇺🇸 In one sentence

The Elegoo Neptune 4 Max ships with a Klipper build from **2022**. This package installs the **2025**
version — no terminal, no USB stick, no screwdriver. You double-click three files, in order, and the
rest is automatic.

The heavy lifting of porting modern Klipper is by [S&M Makers](https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html).
This repository is the wrapper that turns it into three clicks.

**Start here:** read **[GUIDE-EN.md](GUIDE-EN.md)** and follow the three steps.

---

## 📂 Todos os arquivos / Every file

| Arquivo / File | 🇧🇷 O que é | 🇺🇸 What it is |
|---|---|---|
| **[LEIA-ME.md](LEIA-ME.md)** | **Comece por aqui.** O tutorial completo em português | The full tutorial, in Portuguese |
| **[GUIDE-EN.md](GUIDE-EN.md)** | O mesmo tutorial, em inglês | **Start here.** The full tutorial, in English |
| **[EXTRA-Z-OFFSET.md](EXTRA-Z-OFFSET.md)** | 🔧 Extra: por que o Z-offset não obedece nesta máquina, e a solução. Bilíngue | 🔧 Extra: why the Z-offset refuses to obey on this machine, and the fix. Bilingual |
| **[USAR-COM-CLAUDE.md](USAR-COM-CLAUDE.md)** | Para quem prefere que uma IA faça: entregue este arquivo ao Claude Code | For those who'd rather have an AI do it: hand this file to Claude Code |
| `1-Configurar-Acesso.bat` | Cria a chave SSH e instala na impressora. Roda uma vez só | Creates the SSH key and installs it on the printer. One time only |
| `2-Verificar-Impressora.bat` | **Só lê, não muda nada.** Descobre o firmware e diz se há Klipper compatível | **Read-only, changes nothing.** Detects the firmware and tells you if a compatible Klipper exists |
| `3-Instalar-Klipper.bat` | Faz a instalação. 5 a 15 minutos | Does the install. 5 to 15 minutes |
| `4-Voltar-Ao-Original.bat` | Desfaz tudo, usando os backups automáticos | Undoes everything, using the automatic backups |
| `_comum.bat` | Interno: pergunta e guarda o IP em `ip.txt` | Internal: asks for and stores the IP in `ip.txt` |
| `scripts/verificar.sh` | Os comandos de leitura que rodam dentro da impressora | The read-only commands that run inside the printer |
| `scripts/instalar.sh` | Os comandos de instalação que rodam dentro da impressora | The install commands that run inside the printer |
| `scripts/reverter.sh` | Os comandos de reversão que rodam dentro da impressora | The rollback commands that run inside the printer |

Nada aqui é caixa-preta — todo `.bat` e todo `.sh` é texto simples, dá para abrir e ler antes de rodar.

Nothing here is a black box — every `.bat` and `.sh` is plain text you can open and read before running it.

---

## ⚡ O caminho rápido / The fast path

```
1-Configurar-Acesso.bat   →   2-Verificar-Impressora.bat   →   3-Instalar-Klipper.bat
```

🇧🇷 Precisa apenas: impressora ligada, na mesma rede, e o IP dela (aparece em **Settings** no painel).
Senha padrão: `makerbase`. Deu ruim? `4-Voltar-Ao-Original.bat`.

🇺🇸 All you need: printer powered on, on the same network, and its IP (shown under **Settings** on the
panel). Default password: `makerbase`. Something went wrong? `4-Voltar-Ao-Original.bat`.

---

## ⚠️ Depois de instalar / After installing

🇧🇷 **Antes de imprimir qualquer coisa**, no painel da impressora: (1) nivelamento automático da mesa,
(2) ajuste do Z-offset. A calibração antiga não é reaproveitada de forma confiável.

Se o Z-offset parecer que não faz efeito, **não é você** — leia o [EXTRA-Z-OFFSET.md](EXTRA-Z-OFFSET.md).

🇺🇸 **Before printing anything**, on the printer's panel: (1) auto bed leveling, (2) set the Z-offset.
The old calibration is not carried over reliably.

If the Z-offset seems to do nothing, **it's not you** — read [EXTRA-Z-OFFSET.md](EXTRA-Z-OFFSET.md).

---

## 🙏 Créditos / Credits

Todo o trabalho de portar o Klipper moderno para a Neptune 4 Max é da **S&M Makers**.
All the work of porting modern Klipper to the Neptune 4 Max belongs to **S&M Makers**.

- 📄 https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html
- 💾 https://github.com/sandmmakers/klipper
- 📺 https://www.youtube.com/watch?v=Aoy3sI1lv1g

O MCU STM32 **não é tocado** em momento nenhum. / The STM32 MCU is **never touched**.

---

## 📜 Sem garantia / No warranty

🇧🇷 Mexer em firmware tem risco. O caminho de volta existe e funciona, mas quem está do lado da
impressora é você. Use por sua conta.

🇺🇸 Touching firmware carries risk. The rollback path exists and works, but you are the one standing
next to the printer. Use at your own risk.
