@echo off
title Voltar ao Klipper original
color 0C

echo ==========================================================
echo   VOLTAR AO KLIPPER ORIGINAL DE FABRICA
echo ==========================================================
echo.
echo Isto desfaz a instalacao e devolve a impressora ao Klipper
echo que veio de fabrica, usando as copias de seguranca.
echo.
echo A impressora nao pode estar imprimindo.
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

echo.
echo Senha da impressora (a padrao e makerbase).
set "SENHA="
set /p SENHA=Aperte Enter para usar a padrao:
if "%SENHA%"=="" set "SENHA=makerbase"

scp -q -o BatchMode=yes "%~dp0scripts\reverter.sh" mks@%IP%:/tmp/reverter.sh
ssh -o BatchMode=yes mks@%IP% "sed -i 's/\r$//' /tmp/reverter.sh; SENHA='%SENHA%' bash /tmp/reverter.sh"
set ERRO=%errorlevel%
set "SENHA="

echo.
if not "%ERRO%"=="0" (
    echo Algo deu errado. Leia a mensagem acima.
) else (
    echo Pronto. A impressora esta reiniciando com o Klipper original.
    echo.
    echo Depois que ligar, refaca o nivelamento da mesa e o Z-offset.
)
echo.
pause
