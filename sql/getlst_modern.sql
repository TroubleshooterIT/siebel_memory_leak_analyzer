set termout off
set colsep "#"
set head off verify off feedback off
set linesize 2000 trimspool on pagesize 9999 longchunksize 2000 long 1000000000
set serveroutput on size unlimited

col repository_name format a120
col application_name format a120
col applet_name format a120
col bc_name format a120
col service_name format a120
col script_name format a120
col last_upd format a40
col obj_type format a40

column app new_value _app
column applet new_value _applet
column bc new_value _bc
column bs new_value _bs
column ws_id_val new_value _ws_id

-- Definição dos nomes dos arquivos de saída
select '&1' || 'application.lst' app from dual;
select '&1' || 'applet.lst' applet from dual;
select '&1' || 'bc.lst' bc from dual;
select '&1' || 'bs.lst' bs from dual;

-- 1. Recupera o ID do Workspace MAIN
-- A lógica busca o Workspace MAIN associado ao Siebel Repository
SELECT ws.row_id as ws_id_val
  FROM siebel.s_workspace ws, siebel.s_repository rep
 WHERE ws.repository_id = rep.row_id
   AND rep.name = 'Siebel Repository'
   AND ws.name = 'MAIN';

-- ===========================================================================
-- APPLICATION SCRIPTS
-- ===========================================================================
spool '&_app'
SELECT 
    rep.name as repository_name, 
    'Application' as obj_type, 
    ap.name as application_name, 
    aps.name as script_name, 
    aps.last_upd, 
    aps.script
FROM
    -- Resolução de Versão para S_APPLICATION
    (SELECT TBL1.* FROM 
        (SELECT * FROM SIEBEL.S_APPLICATION WHERE WS_ID = '&_ws_id') TBL1 
        LEFT OUTER JOIN (SELECT * FROM SIEBEL.S_APPLICATION WHERE WS_ID = '&_ws_id') TBL2 
        ON (TBL1.WS_SRC_ID = TBL2.WS_SRC_ID AND TBL1.WS_OBJ_VER < TBL2.WS_OBJ_VER) 
        WHERE TBL2.WS_SRC_ID IS NULL AND TBL1.WS_DELETE_FLG = 'N'
    ) ap,
    -- Resolução de Versão para S_APPL_SCRIPT
    (SELECT TBL1.* FROM 
        (SELECT * FROM SIEBEL.S_APPL_SCRIPT WHERE WS_ID = '&_ws_id') TBL1 
        LEFT OUTER JOIN (SELECT * FROM SIEBEL.S_APPL_SCRIPT WHERE WS_ID = '&_ws_id') TBL2 
        ON (TBL1.WS_SRC_ID = TBL2.WS_SRC_ID AND TBL1.WS_OBJ_VER < TBL2.WS_OBJ_VER) 
        WHERE TBL2.WS_SRC_ID IS NULL AND TBL1.WS_DELETE_FLG = 'N'
    ) aps,
    siebel.s_repository rep
WHERE
    aps.repository_id = rep.row_id
    AND aps.application_id = ap.WS_SRC_ID -- Join pelo Source ID em Workspaces
    AND rep.name = 'Siebel Repository'
    AND ap.INACTIVE_FLG = 'N'
    AND aps.INACTIVE_FLG = 'N'
    AND aps.last_upd > to_date('01.01.2009','DD.MM.RRRR');
spool off

-- ===========================================================================
-- APPLET SCRIPTS
-- ===========================================================================
spool '&_applet'
SELECT 
    rep.name as repository_name, 
    'Applet' as obj_type, 
    a.name as applet_name, 
    aps.name as script_name, 
    aps.last_upd, 
    aps.script
FROM            
    -- Resolução de Versão para S_APPL_WEBSCRPT
    (SELECT TBL1.* FROM 
        (SELECT * FROM SIEBEL.S_APPL_WEBSCRPT WHERE WS_ID = '&_ws_id') TBL1 
        LEFT OUTER JOIN (SELECT * FROM SIEBEL.S_APPL_WEBSCRPT WHERE WS_ID = '&_ws_id') TBL2 
        ON (TBL1.WS_SRC_ID = TBL2.WS_SRC_ID AND TBL1.WS_OBJ_VER < TBL2.WS_OBJ_VER) 
        WHERE TBL2.WS_SRC_ID IS NULL AND TBL1.WS_DELETE_FLG = 'N'
    ) aps,
    -- Resolução de Versão para S_APPLET
    (SELECT TBL1.* FROM 
        (SELECT * FROM SIEBEL.S_APPLET WHERE WS_ID = '&_ws_id') TBL1 
        LEFT OUTER JOIN (SELECT * FROM SIEBEL.S_APPLET WHERE WS_ID = '&_ws_id') TBL2 
        ON (TBL1.WS_SRC_ID = TBL2.WS_SRC_ID AND TBL1.WS_OBJ_VER < TBL2.WS_OBJ_VER) 
        WHERE TBL2.WS_SRC_ID IS NULL AND TBL1.WS_DELETE_FLG = 'N'
    ) a, 
    siebel.s_repository rep 
WHERE
    aps.repository_id = rep.row_id
    AND aps.applet_id = a.WS_SRC_ID -- Join pelo Source ID
    AND rep.name = 'Siebel Repository'    
    AND a.INACTIVE_FLG = 'N'
    AND aps.INACTIVE_FLG = 'N'
    AND aps.last_upd > to_date('01.01.2009','DD.MM.RRRR');
spool off

-- ===========================================================================
-- BUSINESS COMPONENT SCRIPTS
-- ===========================================================================
spool '&_bc'
SELECT      
    rep.name as repository_name, 
    'Business Component' as obj_type, 
    b.name as bc_name, 
    bs.name as script_name, 
    bs.last_upd, 
    bs.script
FROM
    -- Resolução de Versão para S_BUSCOMP_SCRIPT
    (SELECT TBL1.* FROM 
        (SELECT * FROM SIEBEL.S_BUSCOMP_SCRIPT WHERE WS_ID = '&_ws_id') TBL1 
        LEFT OUTER JOIN (SELECT * FROM SIEBEL.S_BUSCOMP_SCRIPT WHERE WS_ID = '&_ws_id') TBL2 
        ON (TBL1.WS_SRC_ID = TBL2.WS_SRC_ID AND TBL1.WS_OBJ_VER < TBL2.WS_OBJ_VER) 
        WHERE TBL2.WS_SRC_ID IS NULL AND TBL1.WS_DELETE_FLG = 'N'
    ) bs,
    -- Resolução de Versão para S_BUSCOMP
    (SELECT TBL1.* FROM 
        (SELECT * FROM SIEBEL.S_BUSCOMP WHERE WS_ID = '&_ws_id') TBL1 
        LEFT OUTER JOIN (SELECT * FROM SIEBEL.S_BUSCOMP WHERE WS_ID = '&_ws_id') TBL2 
        ON (TBL1.WS_SRC_ID = TBL2.WS_SRC_ID AND TBL1.WS_OBJ_VER < TBL2.WS_OBJ_VER) 
        WHERE TBL2.WS_SRC_ID IS NULL AND TBL1.WS_DELETE_FLG = 'N'
    ) b,
    siebel.s_repository rep
WHERE
    bs.repository_id = rep.row_id
    AND bs.buscomp_id = b.WS_SRC_ID -- Join pelo Source ID
    AND rep.name = 'Siebel Repository'
    AND b.INACTIVE_FLG = 'N'
    AND bs.INACTIVE_FLG = 'N'
    AND bs.last_upd > to_date('01.01.2009','DD.MM.RRRR');
spool off

-- ===========================================================================
-- BUSINESS SERVICE SCRIPTS
-- ===========================================================================
spool '&_bs'
SELECT          
    rep.name as repository_name, 
    'Business Service' as obj_type, 
    s.name as service_name, 
    ss.name as script_name, 
    ss.last_upd, 
    ss.script
FROM
    -- Resolução de Versão para S_SERVICE_SCRPT
    (SELECT TBL1.* FROM 
        (SELECT * FROM SIEBEL.S_SERVICE_SCRPT WHERE WS_ID = '&_ws_id') TBL1 
        LEFT OUTER JOIN (SELECT * FROM SIEBEL.S_SERVICE_SCRPT WHERE WS_ID = '&_ws_id') TBL2 
        ON (TBL1.WS_SRC_ID = TBL2.WS_SRC_ID AND TBL1.WS_OBJ_VER < TBL2.WS_OBJ_VER) 
        WHERE TBL2.WS_SRC_ID IS NULL AND TBL1.WS_DELETE_FLG = 'N'
    ) ss,
    -- Resolução de Versão para S_SERVICE
    (SELECT TBL1.* FROM 
        (SELECT * FROM SIEBEL.S_SERVICE WHERE WS_ID = '&_ws_id') TBL1 
        LEFT OUTER JOIN (SELECT * FROM SIEBEL.S_SERVICE WHERE WS_ID = '&_ws_id') TBL2 
        ON (TBL1.WS_SRC_ID = TBL2.WS_SRC_ID AND TBL1.WS_OBJ_VER < TBL2.WS_OBJ_VER) 
        WHERE TBL2.WS_SRC_ID IS NULL AND TBL1.WS_DELETE_FLG = 'N'
    ) s,
    siebel.s_repository rep
WHERE
    rep.name = 'Siebel Repository'
    AND ss.repository_id = rep.row_id
    AND ss.service_id = s.WS_SRC_ID -- Join pelo Source ID
    AND s.INACTIVE_FLG = 'N'
    AND ss.INACTIVE_FLG = 'N'
    AND ss.last_upd > to_date('01.01.2009','DD.MM.RRRR');
spool off

exit 
