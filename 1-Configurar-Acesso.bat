@echo off
title Passo 1 - Configurar acesso a impressora
color 0B

echo ==========================================================
echo   PASSO 1 de 3 - CONFIGURAR ACESSO
echo ==========================================================
echo.
echo Este passo cria uma "chave de acesso" no seu computador e
echo instala ela na impressora. Depois disso, os proximos passos
echo funcionam sozinhos, sem ficar pedindo senha.
echo.
echo Voce so precisa fazer isso UMA VEZ.
echo.
pause

call "%~dp0_comum.bat"
if errorlevel 1 exit /b 1

where ssh >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERRO: seu Windows nao tem o SSH instalado.
    echo Abra: Configuracoes ^> Aplicativos ^> Recursos opcionais
    echo Clique em "Adicionar recurso" e instale "Cliente OpenSSH".
    echo Depois rode este arquivo de novo.
    pause
    exit /b 1
)

echo.
echo --- Criando a chave de acesso ---
if not exist "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh"
if exist "%USERPROFILE%\.ssh\id_ed25519.pub" (
    echo Voce ja tem uma chave. Vou reaproveitar.
) else (
    ssh-keygen -t ed25519 -N "" -f "%USERPROFILE%\.ssh\id_ed25519"
)

echo.
echo --- Registrando a impressora como conhecida ---
ssh-keyscan -H %IP% >> "%USERPROFILE%\.ssh\known_hosts" 2>nul
echo Feito.

echo.
echo ==========================================================
echo   AGORA VAI PEDIR A SENHA DA IMPRESSORA
echo ==========================================================
echo.
echo A senha padrao e:  makerbase
echo.
echo IMPORTANTE: enquanto voce digita a senha, NADA aparece na
echo tela. Isso e normal, e proposital. Digite e aperte Enter.
echo.
pause
echo.

type "%USERPROFILE%\.ssh\id_ed25519.pub" | ssh mks@%IP% "mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"

echo.
echo --- Conferindo se funcionou ---
ssh -o BatchMode=yes -o ConnectTimeout=10 mks@%IP% "echo OK" >nul 2>&1
if errorlevel 1 (
    echo.
    echo NAO DEU CERTO.
    echo.
    echo Motivos mais comuns:
    echo   - A senha digitada estava errada. A padrao e: makerbase
    echo   - A senha da impressora foi trocada por voce ou por outro programa.
    echo   - O IP informado nao e o da impressora.
    echo.
    echo Rode este arquivo de novo e tente outra vez.
    pause
    exit /b 1
)

echo.
echo ==========================================================
echo   PRONTO! Acesso configurado.
echo ==========================================================
echo.
echo Agora rode o arquivo:  2-Verificar-Impressora.bat
echo.
pause
