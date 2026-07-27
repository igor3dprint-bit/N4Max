@echo off
REM Arquivo auxiliar - nao rode este diretamente.
REM Cuida do IP da impressora: pergunta na primeira vez e guarda em ip.txt.

set "PASTA=%~dp0"
set "ARQIP=%PASTA%ip.txt"

if exist "%ARQIP%" (
    set /p IP=<"%ARQIP%"
)

if not "%IP%"=="" (
    echo IP salvo da impressora: %IP%
    set /p TROCAR=Usar este IP? (S/n):
    if /i "%TROCAR%"=="n" set "IP="
)

if "%IP%"=="" (
    echo.
    echo Digite o IP da sua impressora.
    echo Voce encontra ele no painel da impressora, em Settings, ou no seu roteador.
    echo Exemplo: 192.168.0.50
    echo.
    set /p IP=IP da impressora:
)

if "%IP%"=="" (
    echo.
    echo Nenhum IP informado. Encerrando.
    pause
    exit /b 1
)

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
