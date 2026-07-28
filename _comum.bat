@echo off
REM Arquivo auxiliar - nao rode este diretamente.
REM Cuida do IP da impressora: pergunta na primeira vez e guarda em ip.txt.

REM ATENCAO para quem for editar este arquivo:
REM nao coloque "set /p" dentro de um bloco entre parenteses. O cmd expande as
REM variaveis do bloco inteiro ANTES de executar, entao a resposta do usuario
REM nunca seria lida. E um parentese solto no texto do prompt - por exemplo
REM "(S/n)" - fecha o bloco no meio e derruba o script com
REM ": was unexpected at this time.". Por isso aqui se usa goto, e colchetes.

set "PASTA=%~dp0"
set "ARQIP=%PASTA%ip.txt"
set "IP="

if exist "%ARQIP%" set /p IP=<"%ARQIP%"

if not defined IP goto PERGUNTAR

echo IP salvo da impressora: %IP%
set "TROCAR="
set /p "TROCAR=Usar este IP? [S/n]: "
if /i "%TROCAR%"=="n" set "IP="
if defined IP goto TEMIP

:PERGUNTAR
echo.
echo Digite o IP da sua impressora.
echo Voce encontra ele no painel da impressora, em Settings, ou no seu roteador.
echo Exemplo: 192.168.0.50
echo.
set "IP="
set /p "IP=IP da impressora: "

if not defined IP (
    echo.
    echo Nenhum IP informado. Encerrando.
    pause
    exit /b 1
)

:TEMIP
REM Tira espacos acidentais: um espaco sobrando no IP faz o ssh falhar
REM com uma mensagem que nao ajuda em nada quem esta comecando.
set "IP=%IP: =%"

echo %IP%>"%ARQIP%"

echo.
echo Testando conexao com %IP% ...
ping -n 2 %IP% >nul 2>&1
if errorlevel 1 (
    echo.
    echo NAO CONSEGUI FALAR COM A IMPRESSORA.
    echo Verifique se ela esta ligada e na mesma rede que este computador.
    echo Se o IP estiver errado, rode de novo e responda "n" para trocar.
    pause
    exit /b 1
)
echo Impressora respondeu.
echo.
exit /b 0
