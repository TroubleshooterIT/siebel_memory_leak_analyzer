#!/bin/bash

# 1. Localiza a raiz do projeto (um nível acima da pasta bin)
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)

# 2. Define os caminhos dos componentes
VENV_PATH="$PROJECT_ROOT/.venv"
PYTHON_SCRIPT="$PROJECT_ROOT/src/analyzer.py"

echo "--- Siebel eScript Analyzer (Linux Version) ---"

# 3. Verifica se o ambiente virtual existe
if [ ! -d "$VENV_PATH" ]; then
    echo "[ERRO] Ambiente virtual não encontrado em $VENV_PATH"
    echo "Por favor, execute: python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"
    exit 1
fi

# 4. Executa o script usando o Python do ambiente virtual
echo "[*] Iniciando análise..."
"$VENV_PATH/bin/python3" "$PYTHON_SCRIPT"

# 5. Verifica o status da execução
if [ $? -eq 0 ]; then
    echo "[SUCESSO] Análise concluída. Verifique o arquivo CSV na raiz do projeto."
else
    echo "[ERRO] Ocorreu um problema durante a execução do script Python."
fi
