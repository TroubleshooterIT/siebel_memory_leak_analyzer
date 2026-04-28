# Siebel eScript Memory Leak Analyzer 🚀

[![Language: Portuguese](https://img.shields.io/badge/Language-Português-green.svg)](#português)
[![Language: English](https://img.shields.io/badge/Language-English-blue.svg)](#english)

---

<a name="português"></a>
## 🇧🇷 Português

Ferramenta de análise estática para identificar vazamentos de memória (*Memory Leaks*) no **Siebel CRM (IP17+)**. O analisador foca em objetos que foram instanciados mas não devidamente nulificados ou que sofrem bypass por interrupções de fluxo (`try/catch/return`).

### 🛠️ Como Funciona o Fluxo

O processo é dividido em dois momentos principais:

1.  **Extração SQL:** Utiliza o `sqlplus` para conectar ao Oracle Database, resolver as versões de Workspaces (MAIN) e exportar os scripts de Application, Applet, BC e Business Services para arquivos `.lst`.
2.  **Análise Python:** Um parser processa os arquivos extraídos, identifica declarações de variáveis e verifica se existe a limpeza correspondente no código, gerando um relatório consolidado em **CSV**.

### 📋 Pré-requisitos

Antes de rodar, garanta que você tem instalado:
* **Python 3.x**
* **Oracle SQL*Plus** (configurado no PATH)
* Conectividade com o Banco de Dados Siebel.

### 📦 Instalação

Instale as bibliotecas necessárias:
```bash
pip install requests google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client pandas
```

---

<a name="english"></a>
## 🇺🇸 English

A static code analysis tool to identify memory leaks in **Siebel CRM (IP17+)**. It scans the repository for objects (BusComps, BusObjects, etc.) that were instantiated but not properly nullified or are bypassed by control flow interruptions (`try/catch/return`).

### 🛠️ Workflow

The process is divided into two main stages:

1.  **SQL Extraction:** Uses `sqlplus` to connect to the Oracle Database, resolve Workspace versions (MAIN), and export Application, Applet, BC, and Business Service scripts into `.lst` files.
2.  **Python Analysis:** A custom parser processes the extracted files, identifies variable declarations, and verifies if the corresponding cleanup exists in the code, generating a consolidated **CSV** report.

### 📋 Prerequisites

Before running the tool, ensure you have the following installed:
* **Python 3.x**
* **Oracle SQL*Plus** (properly configured in your PATH)
* Network access to the Siebel Database.

### 📦 Installation

Install the required libraries using:
```bash
pip install requests google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client pandas
```

---

## 📂 Project Structure / Estrutura do Projeto

```text
siebel-leak-analyzer/
├── bin/              # Execution scripts / Scripts de execução (.bat)
├── sql/              # SQL extraction queries / Queries de extração (.sql)
├── src/              # Python source code / Código fonte Python (.py)
├── temp/             # Temporary .lst files / Arquivos temporários (Git ignored)
├── requirements.txt  # Python dependencies / Dependências
└── README.md
```

## ⚠️ Disclaimer / Aviso Legal

Este script realiza leitura direta em tabelas do Siebel (S_REPOSITORY, etc). Certifique-se de ter permissões de leitura (SELECT) e execute preferencialmente em ambiente de Desenvolvimento ou Homologação. 

*This script performs direct reads on Siebel tables (S_REPOSITORY, etc). Ensure you have SELECT permissions and preferably run it in Development or UAT environments.*
