--提取了所有的Pao2,还有FiO2参数，但是这个表里的FiO2不是很全，只提取部分的，但是这里的最准确。
--后期还会从chartevents中提取，到时候两部分合并
--患者进入ICU前六小时和后7天的数据

DROP MATERIALIZED VIEW IF EXISTS patientslab CASCADE;
CREATE MATERIALIZED VIEW patientslab AS
WITH allpatients AS (
         SELECT select_patient.subject_id,
            select_patient.hadm_id,
            select_patient.icustay_id,
            select_patient.intime,
            select_patient.outtime,
            select_patient.exclusion_age,
            select_patient.exclusion_chest,
            select_patient.exclusion_first_stay,
            select_patient.exclusion_los,
            select_patient.exclusion_vent,
            pf.exclusion_pf
           FROM (mimiciii.select_patient
             LEFT JOIN mimiciii.pf ON ((select_patient.icustay_id = pf.icustay_id)))
        ), my_patients AS (
         SELECT allpatients.subject_id,
            allpatients.hadm_id,
            allpatients.icustay_id,
            allpatients.intime,
            allpatients.outtime,
            allpatients.exclusion_age,
            allpatients.exclusion_chest,
            allpatients.exclusion_first_stay,
            allpatients.exclusion_los,
            allpatients.exclusion_vent,
            allpatients.exclusion_pf
           FROM allpatients
          WHERE ((allpatients.exclusion_pf = 0) AND (allpatients.exclusion_vent = 0) AND (allpatients.exclusion_los = 0) AND (allpatients.exclusion_first_stay = 0) AND (allpatients.exclusion_chest = 0) AND (allpatients.exclusion_age = 0))
        ),pvt as
( -- begin query that extracts the data
  select ie.subject_id, ie.hadm_id, ie.icustay_id
  -- here we assign labels to ITEMIDs
  -- this also fuses together multiple ITEMIDs containing the same data
      , case
        when itemid = 50819 then 'PEEP'
        when itemid = 50816 then 'FIO2'
        when itemid = 50821 then 'PO2'
        else null
        end as label
        , charttime
        , value
        -- add in some sanity checks on the values
        , case
          when valuenum <= 0 then null

          when itemid = 50821 and valuenum > 800 then null -- PO2
          when itemid = 50816 and valuenum > 100 AND valuenum<21 then null -- FiO2
           -- conservative upper limit
        else valuenum
        end as valuenum
    from my_patients ie
    left join labevents le
      on le.subject_id = ie.subject_id and le.hadm_id = ie.hadm_id
      and le.charttime between ie.intime  and ie.outtime
      and le.ITEMID in(50819, 50816,  50821)
)
select pvt.SUBJECT_ID, pvt.HADM_ID, pvt.ICUSTAY_ID, pvt.CHARTTIME
, max(case when label = 'PEEP' then valuenum else null end) as PEEP
, max(case when label = 'FIO2' then valuenum else null end) as FIO2
, max(case when label = 'PO2' then valuenum else null end) as PO2
from pvt
group by pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.CHARTTIME
order by pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.CHARTTIME
