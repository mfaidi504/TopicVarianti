/*
Task varianti without spending there Video 
Topic: varianti (changes/addenda/modifications)
Top 10 varianti by highest Spending (amount/expenditure)


Varianti opened between 20/01/2026 and 10/02/2026


Number of varianti in the Lazio region


Number of varianti for the company Sielte


Distribution of varianti by status (stato)


Number of warnings that do not have a linked variante


Which varianti tables come from ETL1? And in which tables should I extract these results?

*/
/*

*/

/*
1) Top 10 varianti by highest spending
❌ Not possible with these two tables.
sap_dm_contratti_importo_ordinato and sap_dm_contratti_importo_attuale are SAP contract amounts, not “varianti”, and they don’t contain a variante id.
✅ If you meant “Top 10 contracts by ordered amount” (using num_ordinato):

*/

SELECT cod_doc_acquisto,
       des_fornitore,
       num_ordinato
FROM l3_qlik.sap_dm_contratti_importo_ordinato
ORDER BY num_ordinato DESC
LIMIT 10;

/*
2) Varianti opened between 20/01/2026 and 10/02/2026
❌ Not possible with these two tables as “varianti”.
They don’t have “variante open date”. Only dtt_documento exists in importo_attuale (as string).
✅ If you meant “contracts with document date in that range” (assuming dtt_documento is YYYY-MM-DD):
*/

SELECT cod_doc_acquisto,
       dtt_documento,
       des_fornitore,
       num_contrattualizzato
FROM l3_qlik.sap_dm_contratti_importo_attuale
WHERE CAST(dtt_documento AS TIMESTAMP) >= CAST('2026-01-20' AS TIMESTAMP)
  AND CAST(dtt_documento AS TIMESTAMP) < CAST('2026-02-11' AS TIMESTAMP);
 
 /*
 4) Number of varianti for company Sielte
❌ Not possible as “varianti”.
But you can count contracts for Sielte because you have des_fornitore.
✅ Contracts for Sielte (ordered):
 */

SELECT COUNT(*) AS num_contratti_sielte
FROM l3_qlik.sap_dm_contratti_importo_ordinato
WHERE UPPER(des_fornitore) LIKE '%SIELTE%';


/*
 num_contratti_sielte 3445 

✅ Contracts for Sielte (actual):

*/

SELECT COUNT(*) AS num_contratti_sielte
FROM l3_qlik.sap_dm_contratti_importo_attuale
WHERE UPPER(des_titolare_contratto) LIKE '%SIELTE%'
  OR UPPER(cod_titolare_contratto) LIKE '%SIELTE%';

/*
num_contratti_sielte 2681

✅ Contracts for Sielte (actual):
(Use whichever column actually contains the supplier name in your data — usually des_fornitore exists only in the “ordinato” table.)


*/

/*
6) Number of warnings that do NOT have a linked variante ✅ (Solved)
Use the warning tables you shared earlier:
warnings_without_variante 3230

*/

SELECT COUNT(DISTINCT w.cod_id) AS warnings_without_variante
FROM l3_qlik.pni_dm_warning_variante w
LEFT JOIN l3_qlik.pni_dm_rel_warning_progetto_variante r
ON w.cod_id = r.cod_warning_id
WHERE r.cod_warning_id IS NULL;

/*
The two sap_dm_contratti_* tables are contracts, not varianti.
One quick question (yes/no)
Do you mean varianti = SAP contracts in your context?
If YES, I’ll rewrite all KPIs #1–#5 using sap_dm_contratti_importo_*.
If NO, run the SHOW TABLES ... '*variante*' commands above and paste results, and I’ll write the exact varianti queries.


*/


/*

REAL ANSWER 
The 10 variants with the highest spending amount


Variants opened between 20/01/2026 and 10/02/2026


*/





SELECT
  cod_id AS cod_progetto_variante_id,
  des_nome_progetto_variante,
  des_stato,
  dtt_data_apertura_variante
FROM l3_qlik.pni_dm_progetto_variante
WHERE dtt_data_apertura_variante >= CAST('2026-01-20' AS TIMESTAMP)
  AND dtt_data_apertura_variante <  CAST('2026-02-11' AS TIMESTAMP);
  


/*Se vuoi solo quelle “APERTE” (dipende dai valori reali in des_stato):
AND UPPER(des_stato) IN ('APERTO','OPEN','IN_CORSO');

*/

/*
Number of variants in Lazio
Qui possiamo farlo tramite elementi warning, perché lì hai cod_comune_istat e/o des_regione.
Versione consigliata (robusta): usando ISTAT (cod_comune_istat → regione)


*/


SELECT
  COUNT(DISTINCT pv.cod_id) AS num_varianti_lazio
FROM l3_qlik.pni_dm_progetto_variante pv
JOIN l3_qlik.pni_dm_rel_warning_progetto_variante r
  ON pv.cod_id = r.cod_progetto_variante_id
JOIN l3_qlik.pni_dm_dettaglio_elementi_warning d
  ON r.cod_warning_id = d.cod_id_warning_variante
JOIN l3_qlik.dmt_dwh_dm_anagrafica_comune_istat c
  ON d.cod_comune_istat = c.cod_comune_istat
WHERE UPPER(c.des_regione) = 'LAZIO';
/*
Versione veloce (se ti fidi di des_regione già in dettaglio warning)
SQL

*/


SELECT
COUNT(DISTINCT pv.cod_id) AS num_varianti_lazio
FROM l3_qlik.pni_dm_progetto_variante pv
JOIN l3_qlik.pni_dm_rel_warning_progetto_variante r
ON pv.cod_id = r.cod_progetto_variante_id
JOIN l3_qlik.pni_dm_dettaglio_elementi_warning d
ON r.cod_warning_id = d.cod_id_warning_variante
WHERE UPPER(d.des_regione) = 'LAZIO';
/*

Number of variants of the company Sielte
4) Numero di varianti dell’impresa Sielte
❌ Non disponibile con le tabelle che hai fornito
Motivo: non c’è alcuna colonna tipo impresa/fornitore collegata a cod_id (variante).
✅ Serve una tabella con:
cod_progetto_variante_id/cod_id + impresa o fornitore
Distribution of the number of variants by status
5) Distribuzione numero varianti per stato
Usiamo l3_qlik.pni_dm_progetto_variante.des_stato
*/



SELECT
  des_stato,
  COUNT(*) AS num_varianti
FROM l3_qlik.pni_dm_progetto_variante
GROUP BY des_stato
ORDER BY num_varianti DESC;

/*
Number of warnings that do not have an associated variant
6) Numero di warning che non hanno una variante associata 
Base warning: pni_dm_warning_variante
Link: pni_dm_rel_warning_progetto_variante

*/



SELECT
  COUNT(DISTINCT w.cod_id) AS num_warning_senza_variante
FROM l3_qlik.pni_dm_warning_variante w
LEFT JOIN l3_qlik.pni_dm_rel_warning_progetto_variante r
  ON w.cod_id = r.cod_warning_id
WHERE r.cod_warning_id IS NULL;


/*
CARINA ANSWERS 


*/


SELECT cod_id,
       des_vwpj232n4rpt_variante_spe_sav,
       MAX(num_vwpj232n4rpt_progressivo) AS progresso_massino 
       FROM l3_qlik.pni_dm_report_progetti_variante RP 
WHERE UPPER(RP.des_vwpj232n4rpt_variante_spe_sav) = "SAVING"
GROUP BY cod_id,  des_vwpj232n4rpt_variante_spe_sav
ORDER BY progresso_massino ASC
LIMIT 10;



SELECT RP.cod_id,
RP.des_vwpj232n4rpt_variante_spe_sav,
SUM(RP.num_vwpj232n4rpt_importo_variante_corrente) AS totalSAVING
FROM l3_qlik.pni_dm_report_progetti_variante AS RP
WHERE UPPER(RP.des_vwpj232n4rpt_variante_spe_sav) = "SAVING"
GROUP BY
RP.cod_id,
RP.des_vwpj232n4rpt_variante_spe_sav;



WITH base AS (
SELECT
RP.cod_id,
RP.des_vwpj232n4rpt_variante_spe_sav,
SUM(RP.num_vwpj232n4rpt_importo_variante_corrente) AS total_SAVING
FROM l3_qlik.pni_dm_report_progetti_variante AS RP
WHERE UPPER(RP.des_vwpj232n4rpt_variante_spe_sav)= "SAVING"
GROUP BY 
RP.cod_id,
RP.des_vwpj232n4rpt_variante_spe_sav
)

SELECT ROW_NUMBER() OVER ( PARTITION BY des_vwpj232n4rpt_variante_spe_sav 
ORDER BY  total_SAVING ASC
) AS rn,
cod_id,
des_vwpj232n4rpt_variante_spe_sav,
total_SAVING
FROM base
LIMIT 10;


Mancano solo 2 cose per chiudere anche (1) e (4)
SELECT * FROM l3_qlik.pni_dm_report_progetti_variante AS PV
LEFT JOIN l3_qlik.dmt_dwh_dm_anagrafica_comune_istat AS AC ON PV.des_vwpj232n4rpt_codice_istat = AC.cod_comune_istatLEFT JOIN l3_qlik.pni_dm_area_consuntivazione_foto_aperta AS AFA ON PV.des_vwpj232n4rpt_comune = AFA.des_comuneWHERE PV.des_vwpj232n4rpt_numero_ldo = '5600003316';

SELECT * FROM l3_qlik.pni_dm_report_progetti_variante AS PV LEFT JOIN l3_qlik.dmt_dwh_dm_anagrafica_comune_istat AS AC ON PV.des_vwpj232n4rpt_codice_istat = AC.cod_comune_istat LEFT JOIN l3_qlik.pni_dm_area_consuntivazione_foto_aperta AS AFA ON PV.des_vwpj232n4rpt_comune = AFA.des_comune WHERE PV.des_vwpj232n4rpt_numero_ldo = '5600003316' LIMIT 100;

select id_vwpj232n4rpt_id_variante SUM (num_vwpj232n4rpt_importo_variante_corrente) AS TOTAL_SPENDING
from l3_qlik.pplus_dm_vw_pj232_n004_rpt_stato_variante_ag_snapshot
group by id_vwpj232n4rpt_id_variante 
order by num_vwpj232n4rpt_importo_variante_corrente DESC
LIMIT 10;
 

SELECT id_vwpj232n4rpt_id_variante, SUM(num_vwpj232n4rpt_importo_variante_corrente) AS TOTAL_SPENDING
FROM l3_qlik.pplus_dm_vw_pj232_n004_rpt_stato_variante_ag_snapshot
GROUP BY id_vwpj232n4rpt_id_variante
ORDER BY TOTAL_SPENDING DESC
LIMIT 10;
 


SELECT id_vwpj232n4rpt_id_variante,
num_vwpj232n4rpt_importo_variante_corrente
FROM l3_qlik.pplus_dm_vw_pj232_n004_rpt_stato_variante_ag_snapshot
LIMIT 10; 
 
SELECT 
id_vwpj232n4rpt_id_variante, 
SUM(num_vwpj232n4rpt_importo_variante_corrente) AS TOTAL_SPENDING
FROM l3_qlik.pplus_dm_vw_pj232_n004_rpt_stato_variante_ag_snapshot
GROUP BY id_vwpj232n4rpt_id_variante
ORDER BY TOTAL_SPENDING DESC
LIMIT 10;
  
SELECT 
id_vwpj232n4rpt_id_variante, des_vwpj232n4rpt_comune, 
SUM(num_vwpj232n4rpt_importo_variante_corrente) AS TOTAL_SPENDING FROM
l3_qlik.pplus_dm_vw_pj232_n004_rpt_stato_variante_ag_snapshot
GROUP BY id_vwpj232n4rpt_id_variante, des_vwpj232n4rpt_comune
ORDER BY TOTAL_SPENDING DESC
LIMIT 10;
 
 
 
SELECT 
id_vwpj232n4rpt_id_variante, des_vwpj232n4rpt_provincia ,des_vwpj232n4rpt_comune, 
SUM(num_vwpj232n4rpt_importo_variante_corrente) AS TOTAL_SPENDING
FROM l3_qlik.pplus_dm_vw_pj232_n004_rpt_stato_variante_ag_snapshot
GROUP BY id_vwpj232n4rpt_id_variante, des_vwpj232n4rpt_comune, des_vwpj232n4rpt_provincia
ORDER BY TOTAL_SPENDING DESC
LIMIT 10;
 if(des_tipologia_variante = 'VARIANTE SEMPLICE',des_impresa  , NULL() )            as [Impresa], 
from [lib://Root_FS/ETL_CONS_PASS_AG/1.QVD/1.Extract/1_report_progetti_variante.qvd] (qvd)
 SELECT COUNT(DISTINCT id_vwpj232n4rpt_id_variante) AS num_varianti_sielteFROM table name WHERE des_impresa = 'SIELTE';
 SELECT COUNT(DISTINCT id_vwpj232n4rpt_id_variante) AS num_varianti_sielte FROM l3_qlik.pni_dm_report_progetti_variante WHERE des_impresa = 'SIELTE';
 


WITH base AS (
    SELECT
        RP.cod_10,
        RP.des_vwp1232narpt_variante_spe_sav,
        MAX(RP.progressivo) AS progresso_massimo,
        SUM(RP.importo_variante_corrente) AS total_spending
    FROM 13_Alik.pni_On_report_progetti_varlente RP
    WHERE UPPER(RP.des_vwp1232narpt_variante_spe_sav) LIKE '%SPENDING%'
    GROUP BY
        RP.cod_10,
        RP.des_vwp1232narpt_variante_spe_sav
),
ranked AS (
    SELECT
        cod_10,
        des_vwp1232narpt_variante_spe_sav,
        progresso_massimo,
        total_spending,
        ROW_NUMBER() OVER (
            PARTITION BY cod_10
            ORDER BY progresso_massimo DESC
        ) AS rn
    FROM base
)
SELECT
    cod_10,
    des_vwp1232narpt_variante_spe_sav,
    progresso_massimo,
    total_spending
FROM ranked
WHERE rn = 1
ORDER BY total_spending DESC
LIMIT 107;



WITH base AS (
    SELECT
        RP.cod_id,
        SP.des_variante_spe_sav,
        MAX(RP.progressivo) AS progresso_massimo,
        SUM(RP.importo_variante_corrente) AS total_spending
    FROM 33_q11k.pnd_on_report_progetti_varlante RP
    JOIN some_table SP ON RP.cod_id = SP.cod_id  -- adjust this join if needed
    WHERE UPPER(SP.des_variante_spe_sav) = 'SPENDING'
    GROUP BY
        RP.cod_id,
        SP.des_variante_spe_sav
),
ranked AS (
    SELECT
        cod_id,
        des_variante_spe_sav,
        progresso_massimo,
        total_spending,
        ROW_NUMBER() OVER (
            PARTITION BY cod_id
            ORDER BY progresso_massimo DESC
        ) AS rn
    FROM base
)
SELECT
    cod_id,
    des_variante_spe_sav,
    progresso_massimo,
    total_spending
FROM ranked
WHERE rn = 1
ORDER BY total_spending DESC
LIMIT 18;


