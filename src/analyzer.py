import os
import re
from datetime import datetime

# ==============================================================================
# CONFIGURAÇÕES INICIAIS
# ==============================================================================
# Pega o caminho de onde o script está (dentro de /src) e sobe um nível
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Define os caminhos relativos ao projeto
DIR_BUSCA = os.path.join(BASE_DIR, 'temp')
ARQUIVO_OUTPUT = os.path.join(BASE_DIR, 'resultado_leaks_siebel.csv')
# ==============================================================================

def format_siebel_date(date_str):
    if not date_str: return ""
    try:
        months = {'JAN':'01','FEB':'02','MAR':'03','APR':'04','MAY':'05','JUN':'06',
                  'JUL':'07','AUG':'08','SEP':'09','OCT':'10','NOV':'11','DEC':'12'}
        parts = date_str.strip().split('-')
        if len(parts) == 3:
            return f"{parts[0].zfill(2)}/{months.get(parts[1].upper(), '01')}/20{parts[2]}"
        return date_str
    except:
        return date_str

def radical_clean(text):
    return text.replace('#', '').strip() if text else ""

def parse_lst_files():
    if not os.path.exists(DIR_BUSCA):
        print(f"[AVISO] Pasta {DIR_BUSCA} não encontrada. Criando pasta...")
        os.makedirs(DIR_BUSCA)
        return
      
    obj_types = ['this.BusComp', 'ActiveBusComp', 'GetBusComp', 'GetAssocBusComp',
                 'GetPicklistBusComp', 'this.BusObject', 'ActiveBusObject',
                 'GetBusObject', 'GetService', 'NewPropertySet']
    
    grouped_leaks = {}
    current_meta = ["", "", "", ""] 
    current_method_code = []
    in_block_comment = False

    files = [f for f in os.listdir(directory) if f.lower().endswith('.lst')]

    for filename in files:
        file_path = os.path.join(directory, filename)
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
            
            active_vars = {} 
            confirmed_leaks = set()
            in_try = False

            for i, line in enumerate(lines):
                raw_line = line.strip()

                # --- 1. HEADER / FIM DE FUNÇÃO ---
                if raw_line.startswith('Siebel Repository') or i == len(lines) - 1:
                    if i == len(lines) - 1 and not raw_line.startswith('Siebel Repository'):
                        current_method_code.append(line)

                    for v_name, v_type in active_vars.items():
                        confirmed_leaks.add(f"{v_name} / {v_type} (Não nulificada)")

                    if confirmed_leaks:
                        key = (current_meta[0], current_meta[1], current_meta[2])
                        full_code = "".join(current_method_code).replace('"', '""')
                        if key not in grouped_leaks:
                            grouped_leaks[key] = {'date': format_siebel_date(current_meta[3]), 'leaks': [], 'code': f'"{full_code}"'}
                        grouped_leaks[key]['leaks'].extend(list(confirmed_leaks))

                    if i == len(lines) - 1 and not raw_line.startswith('Siebel Repository'): break

                    header_clean = raw_line.replace('Siebel Repository', '').replace('#', '')
                    parts = [p.strip() for p in re.split(r'\t|\s{2,}', header_clean) if p.strip()]
                    while len(parts) < 4: parts.append("")
                    current_meta = [radical_clean(p) for p in parts[:4]]
                    current_method_code, active_vars, confirmed_leaks = [], {}, set()
                    in_try = False
                    continue

                current_method_code.append(line)

                # --- 2. COMENTÁRIOS ---
                if '/*' in raw_line and '*/' not in raw_line: in_block_comment = True; continue
                if '*/' in raw_line: in_block_comment = False; continue
                if in_block_comment or raw_line.startswith('//'): continue

                # --- 3. MAPEAMENTO DE TRY ---
                if 'try' in raw_line: in_try = True
                if 'finally' in raw_line: in_try = False

                # --- 4. IDENTIFICAÇÃO DE VARIÁVEIS ---
                for obj_type in obj_types:
                    if re.search(rf"=\s*.*{re.escape(obj_type)}\s*\([^)]*\)(?!\s*\.)", raw_line):
                        v_name = radical_clean(re.sub(r'[:\(\)\{\}\[\]\t;]', '', re.sub(r'[ \t]*=.*', '', re.sub(r'^[ \t]*var[ \t]+', '', raw_line))))
                        if v_name and not any(x in v_name for x in ['if', 'return', 'while', 'throw']):
                            active_vars[v_name] = obj_type

                # --- 5. LIMPEZA (null / "" / '') ---
                if re.search(r'=[ \t]*(null|""|\'\')', raw_line):
                    v_null = radical_clean(re.sub(r'[\[\]\t;]', '', re.sub(r'[ \t]*=[ \t]*(null|""|\'\').*', '', re.sub(r'^[ \t]*var[ \t]+', '', raw_line))))
                    if v_null in active_vars:
                        del active_vars[v_null]

                # --- 6. INTERRUPÇÃO (return / throw / RaiseError) ---
                # RaiseErrorText e RaiseError funcionam como throw
                if re.search(r'\b(return|throw|RaiseError|RaiseErrorText)\b', raw_line):
                    # Se houver uma interrupção, as variáveis ativas no momento podem ser leaks
                    # a menos que o código esteja em um try (pois o finally cuidará delas)
                    if not in_try:
                        for v_name, v_type in active_vars.items():
                            confirmed_leaks.add(f"{v_name} / {v_type} (Bypass por Interrupção de Fluxo)")

    # --- ESCRITA FINAL COM FILTRO DE CONFIANÇA ---
    try:
        with open(ARQUIVO_OUTPUT, 'w', encoding='utf-8-sig') as csv_out:
            csv_out.write("Object Type;Object Name;Function;Change Date;Variable Names / Assignment Methods;Full_Code_Snippet\n")
            for (ot, on, fn), data in grouped_leaks.items():
                final_list = []
                for leak in data['leaks']:
                    name = leak.split(' / ')[0]
                    # Se a variável é nulificada em qualquer lugar do snippet (ex: no finally),
                    # removemos apenas o alerta de "Bypass", mas mantemos se ela NUNCA for nulificada.
                    has_cleanup = re.search(rf"{name}\s*=\s*(null|\"\"|'')", data['code'])
                    
                    if "(Bypass" in leak and has_cleanup:
                        continue
                    final_list.append(leak)
                
                if final_list:
                    csv_out.write(";".join([ot, on, fn, data['date'], f"\"{chr(10).join(set(final_list))}\"", data['code']]) + "\n")
        print(f"\n[SUCESSO] Analise concluida!")
    except PermissionError:
        print(f"\n[ERRO] O arquivo CSV está aberto.")

if __name__ == "__main__":
    parse_lst_files()
