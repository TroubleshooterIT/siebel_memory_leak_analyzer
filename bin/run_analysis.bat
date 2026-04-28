@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Caminho para a raiz do projeto (um nível acima da pasta bin)
SET "PROJECT_ROOT=%~dp0.."

:: --- SEGURANÇA: LOGIN ---
:: Em vez de deixar a senha aqui, o script pergunta ao usuário (ou use variáveis de ambiente)
SET /P SIEBEL_USER="Usuario Siebel: "
SET /P SIEBEL_PWD="Senha: "
SET "LOGIN=%SIEBEL_USER%/%SIEBEL_PWD%@TNS_ORACLE"

:: --- MOMENTO 1: EXTRAÇÃO ---
echo [1/2] Baixando eScripts do Oracle...
:: Executa o SQL que agora está na pasta /sql/
sqlplus -S %LOGIN% @%PROJECT_ROOT%\sql\getlst_modern.sql %PROJECT_ROOT%\temp\

:: --- MOMENTO 2: ANÁLISE ---
echo [2/2] Analisando artefatos com Python...
:: Chama o Python que agora está na pasta /src/
python %PROJECT_ROOT%\src\analyzer.py

echo.
echo Processo Concluido! Verifique o arquivo resultado_leaks_siebel.csv na raiz.
pause
