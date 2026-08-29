# Elegoo Neptune 4 Max: Klipper moderno, BTT Eddy e o Z-offset que não obedece

Tudo o que eu aprendi mexendo na minha Neptune 4 Max, escrito comando por comando, com os números
reais que eu medi na máquina. Não é teoria de fórum: cada coisa aqui quebrou primeiro, e só depois
funcionou.

Autor: [@Igor3DPrint](https://instagram.com/igor3dprint)

[Passo a passo em português](PASSO-A-PASSO.md) · [Step by step in English](STEP-BY-STEP.md) ·
[Página web](https://igor3dprint-bit.github.io/Neptune4Max-Klipper-Facil/)

---

## Crédito antes de tudo

**Sem a S&M Makers, nada disto existiria.** Todo o trabalho de portar o Klipper moderno para a
Neptune 4 Max é dele. Este repositório traduz o processo para o português e acrescenta o que eu
descobri usando a máquina no dia a dia. Se isto te ajudou, o agradecimento vai pra lá.

| | |
|---|---|
| Vídeo | https://www.youtube.com/watch?v=Aoy3sI1lv1g, do **@SandMMakers** |
| Tutorial original | https://sandmmakers.com/Projects/Neptune4MaxLatestKlipper/Directions.html |
| Código | https://github.com/sandmmakers/klipper |

---

## O que tem aqui

### 1. Instalar o Klipper de 2025 no lugar do de 2022

A Neptune 4 Max sai de fábrica com um Klipper de **2022**. O passo a passo leva você até a versão de
**2025**, comando por comando, explicando o que cada um faz e mostrando o que você deve ver na tela.
Sem pendrive, sem chave de fenda, sem abrir a impressora.

[PASSO-A-PASSO.md](PASSO-A-PASSO.md) · [STEP-BY-STEP.md](STEP-BY-STEP.md)

### 2. Instalar e calibrar uma sonda BTT Eddy

O Eddy é rápido e preciso, e tem uma limitação que quase ninguém avisa: ele enxerga só os últimos
4 mm. Na Neptune 4 Max, onde a sonda é a única referência de Z da máquina, isso muda tudo.

Este guia cobre a montagem, as três medidas que você precisa tirar, a ordem certa da calibração, e
as quatro armadilhas que me custaram uma noite inteira e um bico arrastado na chapa. Tem ênfase
especial na **corrente de excitação do sensor**, o `reg_drive_current`, que é o parâmetro mais
importante e o menos falado. É a causa mais comum de `Eddy current sensor error` nesta máquina, e a
mensagem parece dizer que o sensor está longe da mesa. Não é isso que ela informa. Com a corrente
errada, o sensor dá erro mesmo estando na distância certa, e você procura horas no lugar errado.

[EDDY.md](EDDY.md)

### 3. O Z-offset que não obedece, e por quê

Nesta máquina você ajusta o Z-offset, salva, e **quase nada muda**. Medido: mudar de `0.0` para
`2.110` deslocou o bico em **0,05 mm** quando deveria deslocar 2,11.

São três causas somadas, e nenhuma delas está documentada em outro lugar. O módulo da tela zera o
valor no `SAVE_CONFIG`, o `plr.cfg` declara a impressora zerada segundos depois de ligar sem ter
homeado, e o `PROBE_CALIBRATE` repete o mesmo valor errado. Tem a solução, como medir o **seu** valor,
e o efeito colateral que enfiou um bico na borracha de limpeza aqui.

[Z-OFFSET.md](Z-OFFSET.md), bilíngue

### 4. Instruções para inteligência artificial

Se você jogar este repositório numa IA e pedir ajuda, ela vai encontrar um arquivo escrito
especificamente para ela. Ele diz para a IA perguntar primeiro qual dos procedimentos você quer,
carregar só o documento certo, e seguir as regras de segurança que existem porque cada uma delas
custou um prejuízo real aqui.

Funciona com Claude Code, Codex, Cursor, Copilot e qualquer agente que leia um arquivo de contexto
do repositório.

[AGENTS.md](AGENTS.md)

---

## O caminho curto

```bash
# 1. entrar na impressora (senha padrao de fabrica: makerbase)
ssh mks@SEU_IP

# 2. descobrir o firmware Elegoo instalado
grep -rhoE "1\.[0-9]+\.[0-9]+\.[0-9]+" /home/mks/Desktop/myfile/ 2>/dev/null | sort | uniq -c | sort -rn | head -1

# 3. ver quais versoes do port existem para ele
git ls-remote --tags https://github.com/sandmmakers/klipper.git | grep -oE 'sandmmakers-[A-Za-z0-9.-]+' | grep -v '\^{}' | sort -u
```

A partir daqui, siga o [passo a passo](PASSO-A-PASSO.md). Os próximos comandos mexem na máquina e a
ordem importa.

---

## Estrutura

| Arquivo | Conteúdo |
|---|---|
| `PASSO-A-PASSO.md` | Guia completo de instalação do Klipper, comando por comando |
| `STEP-BY-STEP.md` | O mesmo guia, em inglês |
| `EDDY.md` | Instalação e calibração do BTT Eddy, com as armadilhas |
| `Z-OFFSET.md` | O Z-offset que não obedece: causas, solução, medição. Bilíngue |
| `AGENTS.md` | Instruções para uma IA conduzir qualquer um dos procedimentos |
| `docs/` | A página web deste repositório |

---

## Por que comandos, e não um instalador de um clique

Um instalador promete "clica e funciona". Essa promessa exige testar a instalação inteira numa
máquina de fábrica, várias vezes, e eu tenho uma impressora só, em produção.

Comando na tela promete outra coisa: **você está no comando, aqui está o que vai rodar e por quê.**
Essa promessa eu consigo sustentar. Você lê antes de colar, entende o que mudou, e sabe onde parar se
algo sair diferente do esperado. De quebra funciona em Mac e Linux, não só Windows.

---

## Um aviso sobre os números deste repositório

Todo valor numérico aqui foi medido na minha máquina. Os que mais mudam de impressora para
impressora são `x_offset`, `y_offset`, `z_offset`, `reg_drive_current`, a altura de montagem da
sonda e o ponto usado no homing.

Copiar esses números direto, sem medir, é a forma mais rápida de reproduzir os meus erros em vez dos
meus acertos. Use a explicação, meça o seu.

---

## English

This repository documents three things about the Elegoo Neptune 4 Max: installing modern Klipper
over the factory 2022 build, installing and calibrating a BTT Eddy probe, and fixing the Z-offset
that refuses to obey when you save it.

The Klipper install guide and the Z-offset write-up are available in English. The Eddy guide and the
AI instructions are currently Portuguese only.

[STEP-BY-STEP.md](STEP-BY-STEP.md) · [Z-OFFSET.md](Z-OFFSET.md)

All the porting work belongs to [S&M Makers](https://github.com/sandmmakers/klipper). This repository
walks through their process and adds what I found living with the machine.

---

## Licença e garantia

Código sob [MIT](LICENSE). O Klipper em si é GPLv3, e o port é da S&M Makers, sob a licença dele.

**Sem garantia.** Mexer em firmware e em sonda tem risco. O caminho de volta existe e está
documentado, mas quem está do lado da impressora é você. Vá devagar, leia antes de colar, e pare
quando ficar estranho.
