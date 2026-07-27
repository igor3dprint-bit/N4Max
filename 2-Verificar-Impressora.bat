@echo off
title Passo 2 - Verificar a impressora
color 0B

echo ==========================================================
echo   PASSO 2 de 3 - VERIFICAR
echo ==========================================================
echo.
echo Este passo SO OLHA a impressora. Ele nao muda nada.
echo Serve para descobrir qual versao do Klipper serve para voce.
echo.
pause

call "%~dp0_comum.bat"
if errorlevel 1 exit /b 1

ssh -o BatchMode=yes -o ConnectTimeout=10 mks@%IP% "echo ok" >nul 2>&1
if errorlevel 1 (
    echo.
    echo Nao consegui entrar na impressora sem senha.
    echo Rode primeiro o arquivo: 1-Configurar-Acesso.bat
    pause
    exit /b 1
)

scp -q -o BatchMode=yes "%~dp0scripts\verificar.sh" mks@%IP%:/tmp/verificar.sh
ssh -o BatchMode=yes mks@%IP% "sed -i 's/\r$//' /tmp/verificar.sh; bash /tmp/verificar.sh"
set ERRO=%errorlevel%

echo.
if "%ERRO%"=="0" (
    echo Proximo passo: rode o 3-Instalar-Klipper.bat
) else (
    echo Leia a mensagem acima antes de continuar.
    echo Em caso de duvida, abra o arquivo LEIA-ME.md
)
echo.
pause
