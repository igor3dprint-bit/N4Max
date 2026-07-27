@echo off
title Passo 3 - Instalar o Klipper novo
color 0E

echo ==========================================================
echo   PASSO 3 de 3 - INSTALAR
echo ==========================================================
echo.
echo ATENCAO, leia antes de continuar:
echo.
echo  - Isto vai trocar o Klipper da sua impressora.
echo  - A impressora NAO PODE estar imprimindo.
echo  - NAO desligue a impressora nem o computador durante o processo.
echo  - Demora entre 5 e 15 minutos. E normal parecer travado.
echo  - Ao final a impressora reinicia sozinha.
echo  - Copias de seguranca sao feitas automaticamente, e da para
echo    voltar atras com o 4-Voltar-Ao-Original.bat
echo.
set /p OK=Digite SIM para continuar:
if /i not "%OK%"=="SIM" (
    echo.
    echo Cancelado. Nada foi alterado.
    pause
    exit /b 0
)

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

echo.
echo Senha da impressora (a padrao e makerbase).
set "SENHA="
set /p SENHA=Aperte Enter para usar a padrao:
if "%SENHA%"=="" set "SENHA=makerbase"

echo.
echo Comecando. Pode ir tomar um cafe.
echo.

scp -q -o BatchMode=yes "%~dp0scripts\instalar.sh" mks@%IP%:/tmp/instalar.sh
ssh -o BatchMode=yes mks@%IP% "sed -i 's/\r$//' /tmp/instalar.sh; SENHA='%SENHA%' bash /tmp/instalar.sh"
set ERRO=%errorlevel%
set "SENHA="

if not "%ERRO%"=="0" (
    echo.
    echo ==========================================================
    echo   ALGO DEU ERRADO
    echo ==========================================================
    echo.
    echo Leia a mensagem acima. A impressora nao foi reiniciada.
    echo Se quiser desfazer, rode: 4-Voltar-Ao-Original.bat
    echo.
    pause
    exit /b 1
)

echo.
echo Aguardando a impressora reiniciar...
timeout /t 45 /nobreak >nul

set TENTATIVA=0
:ESPERA
set /a TENTATIVA+=1
ssh -o BatchMode=yes -o ConnectTimeout=5 mks@%IP% "echo ok" >nul 2>&1
if not errorlevel 1 goto VOLTOU
if %TENTATIVA% geq 20 goto DEMOROU
timeout /t 10 /nobreak >nul
goto ESPERA

:DEMOROU
echo.
echo A impressora esta demorando para voltar.
echo Espere mais um pouco e confira pelo Fluidd/Mainsail no navegador.
pause
exit /b 1

:VOLTOU
echo Impressora ligada. Conferindo...
echo.
ssh -o BatchMode=yes mks@%IP% "grep -m1 'Git version' ~/klipper_logs/klippy.log; curl -s http://localhost:7125/server/info | grep -o '\"klippy_state\": \"[a-z]*\"'"

echo.
echo ==========================================================
echo   INSTALACAO CONCLUIDA
echo ==========================================================
echo.
echo AGORA FALTA VOCE FAZER, no painel da impressora:
echo.
echo   1. Nivelamento automatico da mesa (auto bed leveling)
echo   2. Ajustar o Z-offset
echo.
echo Faca isso ANTES de imprimir qualquer coisa.
echo.
echo Leia a secao "Depois de instalar" no LEIA-ME.md - tem dois
echo comportamentos estranhos que sao normais e esperados.
echo.
pause
