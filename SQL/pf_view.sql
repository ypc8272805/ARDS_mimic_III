DROP MATERIALIZED VIEW IF EXISTS pf CASCADE;
CREATE MATERIALIZED VIEW pf AS
with stg_fio2 as (
select SUBJECT_ID, HADM_ID, ICUSTAY_ID, CHARTTIME
    -- pre-process the FiO2s to ensure they are between 21-100%
    , max(
        case
          when itemid = 223835
            then case
              when valuenum > 0 and valuenum <= 1
                then valuenum * 100
              -- improperly input data - looks like O2 flow in litres
              when valuenum > 1 and valuenum < 21
                then null
              when valuenum >= 21 and valuenum <= 100
                then valuenum
              else null end -- unphysiological
        when itemid in (3420, 3422)
        -- all these values are well formatted
            then valuenum
        when itemid = 190 and valuenum > 0.20 and valuenum < 1
        -- well formatted but not in %
            then valuenum * 100
      else null end
    ) as fio2_chartevents
  from CHARTEVENTS
  where ITEMID in
  (
    3420 -- FiO2
  , 190 -- FiO2 set
  , 223835 -- Inspired O2 Fraction (FiO2)
  , 3422 -- FiO2 [measured]
  )
  -- exclude rows marked as error
  and error IS DISTINCT FROM 1
  group by SUBJECT_ID, HADM_ID, ICUSTAY_ID, CHARTTIME
),stg1 AS (
    SELECT
      po2.*,
      fio2.fio2_chartevents,
      ROW_NUMBER()
      OVER (
        PARTITION BY po2.icustay_id, po2.charttime
        ORDER BY fio2.charttime DESC ) AS lastRowFiO2
    FROM po2sevenday po2
      LEFT JOIN stg_fio2 fio2
        ON po2.icustay_id = fio2.icustay_id
           AND fio2.charttime BETWEEN po2.charttime - INTERVAL '4' HOUR AND po2.charttime
),stg2 AS (
    SELECT
      stg1.*,
      CASE
      WHEN stg1.po2 IS NOT NULL
           AND coalesce(stg1.fio2, stg1.fio2_chartevents) IS NOT NULL
        THEN 100 * PO2 / (coalesce(stg1.fio2, stg1.fio2_chartevents))
      ELSE NULL
      END AS PF
    FROM stg1
    WHERE stg1.lastRowFiO2 = 1
    ORDER BY icustay_id, charttime
),stg3 AS (
  SELECT  subject_id,hadm_id,icustay_id
--  ,max(CASE WHEN stg2.PF>300 AND stg2.PF IS NULL THEN 1 ELSE 0 END)  AS exclusion_pf
  ,min(pf) AS minpf
FROM stg2
GROUP BY subject_id,hadm_id,icustay_id
)
SELECT stg3.*
  ,CASE
  WHEN  (minpf>300 OR minpf IS NULL ) THEN 1
   ELSE 0
   END AS exclusion_pf
  FROM stg3

