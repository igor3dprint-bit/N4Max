# Elegoo Neptune 4 Max — Klipper moderno + o Z-offset que não obedece

**🇧🇷 [Passo a passo em português](PASSO-A-PASSO.md) · 🇺🇸 [Step by step in English](STEP-BY-STEP.md) · 🌐 [Página web / Web page](https://igor3dprint-bit.github.io/Neptune4Max-Klipper-Facil/)**

---

## 🙏 Crédito antes de tudo / Credit before anything else

🇧🇷 **Sem a S&M Makers, nada disto existiria.** Todo o trabalho de portar o Klipper moderno para a
Neptune 4 Max é dele. Este repositório traduz o processo para o português e acrescenta o que
descobrimos usando a máquina no dia a dia. Se isto te ajudou, o agradecimento vai pra lá.

🇺🇸 **Without S&M Makers, none of this would exist.** All the work of porting modern Klipper to the
Neptune 4 Max is theirs. This repository walks through their process in Portuguese and English, and
adds what we found living with the machine. If this helped you, that is where the thanks belong.

| | |
|---|---|
| ▶️ **Vídeo / Video** | https://www.youtube.com/watch?v=Aoy3sI1lv1g — **@SandMMakers** |
| 📄 **Tutorial original** | https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html |
| 💾 **Código / Code** | https://github.com/sandmmakers/klipper |

---

## O que tem aqui / What's inside

### 1️⃣ Instalar o Klipper de 2025 no lugar do de 2022

🇧🇷 A Neptune 4 Max sai de fábrica com um Klipper de **2022**. O passo a passo leva você até a versão
de **2025**, comando por comando, explicando o que cada um faz e mostrando o que você deve ver na
tela. Sem pendrive, sem chave de fenda, sem abrir a impressora.

🇺🇸 The Neptune 4 Max ships with a Klipper build from **2022**. The step-by-step takes you to the
**2025** one, command by command, explaining what each does and showing what you should see. No USB
stick, no screwdriver, no opening the printer.

→ **[PASSO-A-PASSO.md](PASSO-A-PASSO.md)** · **[STEP-BY-STEP.md](STEP-BY-STEP.md)**

### 2️⃣ O Z-offset que não obedece — e por quê

🇧🇷 Nesta máquina você ajusta o Z-offset, salva, e **quase nada muda**. Medido: mudar de `0.0` para
`2.110` deslocou o bico em **0,05 mm** quando deveria deslocar 2,11.

São **três causas somadas**, e nenhuma delas está documentada em outro lugar: o módulo da tela zera o
valor no `SAVE_CONFIG`, o `plr.cfg` declara a impressora zerada segundos depois de ligar sem ter
homeado, e o `PROBE_CALIBRATE` repete o mesmo valor errado. Tem a solução, como medir o **seu** valor,
e o efeito colateral que enfiou um bico na borracha de limpeza aqui.

🇺🇸 On this machine you adjust the Z-offset, save, and **almost nothing changes**. Measured: going
from `0.0` to `2.110` moved the nozzle by **0.05 mm** when it should have moved 2.11.

**Three causes stacked**, none documented anywhere else: the LCD module zeroes the value on
`SAVE_CONFIG`, `plr.cfg` declares the printer homed seconds after boot when it isn't, and
`PROBE_CALIBRATE` repeats the same wrong number. Includes the fix, how to measure **your** value, and
the side effect that drove a nozzle into the wipe pad here.

→ **[Z-OFFSET.md](Z-OFFSET.md)** (bilíngue / bilingual)

---

## ⚡ O caminho curto / The short path

```bash
# 1. entrar na impressora (senha padrao: makerbase)
ssh mks@SEU_IP

# 2. descobrir o firmware Elegoo instalado
grep -rhoE "1\.[0-9]+\.[0-9]+\.[0-9]+" /home/mks/Desktop/myfile/ 2>/dev/null | sort | uniq -c | sort -rn | head -1

# 3. ver quais versoes existem para ele
git ls-remote --tags https://github.com/sandmmakers/klipper.git | grep -oE 'sandmmakers-[A-Za-z0-9.-]+' | grep -v '\^{}' | sort -u
```

🇧🇷 A partir daqui, siga o [passo a passo](PASSO-A-PASSO.md) — os próximos comandos mexem na máquina
e a ordem importa.
🇺🇸 From here, follow the [step by step](STEP-BY-STEP.md) — the next commands change the machine and
the order matters.

---

## 📁 Estrutura / Layout

| Arquivo / File | |
|---|---|
| `PASSO-A-PASSO.md` | 🇧🇷 Guia completo de instalação, comando por comando |
| `STEP-BY-STEP.md` | 🇺🇸 The same guide, in English |
| `Z-OFFSET.md` | 🔧 O Z-offset que não obedece: causas, solução, medição (bilíngue) |
| `docs/` | 🌐 A página web deste repositório |

---

## 🤔 Por que comandos, e não um instalador de um clique

🇧🇷 Um instalador promete "clica e funciona". Essa promessa exige testar a instalação inteira numa
máquina de fábrica, várias vezes — e quem escreve isto tem uma impressora só, em produção.

Comando na tela promete outra coisa: **você está no comando, aqui está o que vai rodar e por quê.**
Essa promessa dá pra sustentar. Você lê antes de colar, entende o que mudou, e sabe onde parar se
algo sair diferente do esperado. De quebra funciona em Mac e Linux, não só Windows.

🇺🇸 An installer promises "click and it works". Backing that up means testing the full install on a
factory machine, repeatedly — and whoever writes this has one printer, in production.

Commands on screen promise something else: **you are in control, here is what will run and why.**
That promise can be kept. You read before pasting, you understand what changed, and you know where to
stop if something looks off. It also works on Mac and Linux, not just Windows.

---

## 📜 Licença e garantia / License and warranty

Código sob [MIT](LICENSE). O Klipper em si é GPLv3, e o port é da S&M Makers, sob a licença dele.

🇧🇷 **Sem garantia.** Mexer em firmware tem risco. O caminho de volta existe e funciona, mas quem
está do lado da impressora é você.

🇺🇸 **No warranty.** Touching firmware carries risk. The rollback path exists and works, but you are
the one standing next to the printer.
