-- The aim of this query is to pivot entries related to blood gases and
-- chemistry values which were found in LABEVENTS

-- things to check:
--  when a mixed venous/arterial blood sample are taken at the same time, is the store time different?

DROP MATERIALIZED VIEW IF EXISTS patientschart CASCADE;
create materialized view patientschart as
WITH allpatients AS (
  SELECT select_patient.subject_id,select_patient.hadm_id,select_patient.icustay_id,select_patient.intime,select_patient.outtime
  ,select_patient.exclusion_age,select_patient.exclusion_chest,select_patient.exclusion_first_stay,select_patient.exclusion_los,select_patient.exclusion_vent,pf.exclusion_pf
FROM select_patient
LEFT JOIN pf
  ON select_patient.icustay_id=pf.icustay_id
),my_patients AS (
SELECT *
  FROM allpatients
  WHERE exclusion_pf=0
  AND exclusion_vent=0
  AND exclusion_los=0
  AND exclusion_first_stay=0
  AND exclusion_chest=0
  AND exclusion_age=0
),chart_value AS (
  -- begin query that extracts the data
    SELECT
      ie.subject_id,
      ie.hadm_id,
      ie.icustay_id
      -- here we assign labels to ITEMIDs
      -- this also fuses together multiple ITEMIDs containing the same data
      ,
      CASE
      WHEN itemid IN (220277, 646)
        THEN 'SPO2'
      WHEN itemid IN (220224, 779)
        THEN 'PAO2'
      WHEN itemid IN (190, 3420, 223835, 3422)
        THEN 'FIO2'
      WHEN itemid IN (211, 220045)
        THEN 'HR'
      WHEN itemid IN (223762, 676, 677, 223761, 678, 679)
        THEN 'TEMP'
      WHEN itemid IN (442, 455, 220179)
        THEN 'NBPS'
      WHEN itemid IN (8440, 8441, 220180)
        THEN 'NBPD'
      WHEN itemid IN (456, 443, 220181)
        THEN 'NBPM'
      WHEN itemid IN (615, 618, 220210, 224690)
        THEN 'RR'
      WHEN itemid IN (681, 682, 2400, 2408, 2534, 2420, 224685)
        THEN 'TV'
      WHEN itemid IN (507, 535, 224695)
        THEN 'PIP'
      WHEN itemid IN (543, 224696)
        THEN 'PLAP'
      WHEN itemid IN (445, 448, 450, 224687)
        THEN 'MV'
      WHEN itemid IN (444, 3502, 3503, 224697)
        THEN 'MAP'
      WHEN itemid IN (506, 220339)
        THEN 'PEEP'
      ELSE NULL
      END AS label,
      intime,
      outtime,
      charttime,
      itemid,
      value
      -- add in some sanity checks on the values
      ,
      CASE
      WHEN valuenum <= 0
        THEN NULL
      WHEN itemid IN (220277, 646) AND valuenum > 100
        THEN NULL -- spo2
      WHEN itemid IN (220224, 779) AND valuenum > 800
        THEN NULL -- pao2
      --fio2
      WHEN itemid = 223835
        THEN CASE
             WHEN valuenum > 0 AND valuenum <= 1
               THEN valuenum * 100
             WHEN valuenum > 1 AND valuenum < 21
               THEN NULL
             WHEN valuenum >= 21 AND valuenum <= 100
               THEN valuenum
             ELSE NULL END
      WHEN itemid IN (3420, 3422)
        THEN valuenum
      WHEN itemid = 190 AND valuenum > 0.2 AND valuenum <= 1
        THEN valuenum * 100
      --temp
      WHEN itemid IN (223762, 676, 677)
        THEN valuenum -- celsius
      WHEN itemid IN (223761, 678, 679)
        THEN (valuenum - 32) * 5 / 9 --fahrenheit

      -- conservative upper limit
      ELSE valuenum
      END AS valuenum,
      valueuom
    FROM my_patients ie
      LEFT JOIN chartevents le
        ON le.subject_id = ie.subject_id AND le.hadm_id = ie.hadm_id AND ie.icustay_id = le.icustay_id
           AND le.charttime BETWEEN ie.intime AND ie.outtime
           AND le.ITEMID IN
               -- 我需要的参数
               (
                 220277, 646--spo2
                 , 220224, 779--pao2
                 , 190, 3420, 3422, 223835--fio2
                 , 211, 220045--hr
                 , 223762, 676, 677, 223761, 678, 679--temp
                 , 442, 455, 220179--nbps
                 , 8440, 8441, 220180--nbpd
                 , 456, 443, 220181--nbpm
                 , 615, 618, 220210, 224690--rr
                 , 681, 682, 2400, 2408, 2534, 2420, 224685--tv
                 , 507, 535, 224695--pip
                 , 543, 224696--plap
                 , 445, 448, 450, 224687--mv
                 , 444, 3502, 3503, 224697--map
                 , 506, 220339--peep
               )
)
select pvt.SUBJECT_ID, pvt.HADM_ID, pvt.ICUSTAY_ID, pvt.CHARTTIME
, max(case when label = 'SPO2' then value else null end) as SPO2
, max(case when label = 'PAO2' then valuenum else null end) as PAO2
, max(case when label = 'FIO2' then valuenum else null end) as FIO2
, max(case when label = 'HR' then valuenum else null end) as HR
, max(case when label = 'TEMP' then valuenum else null end) as TEMP
, max(case when label = 'NBPS' then valuenum else null end) as NBPS
, max(case when label = 'NBPD' then valuenum else null end) as NBPD
, max(case when label = 'NBPM' then valuenum else null end) as NBPM
, max(case when label = 'RR' then valuenum else null end) as RR
, max(case when label = 'TV' then valuenum else null end) as TV
, max(case when label = 'PIP' then valuenum else null end) as PIP
, max(case when label = 'PLAP' then valuenum else null end) as PLAP
, max(case when label = 'MV' then valuenum else null end) as MV
, max(case when label = 'MAP' then valuenum else null end) as MAP
, max(case when label = 'PEEP' then valuenum else null end) as PEEP

from chart_value pvt
group by pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.CHARTTIME
order by pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.CHARTTIME
