--提取了所有的Pao2,还有FiO2参数，但是这个表里的FiO2不是很全，只提取部分的，但是这里的最准确。
--后期还会从chartevents中提取，到时候两部分合并
--患者进入ICU前六小时和后7天的数据

DROP MATERIALIZED VIEW IF EXISTS po2sevenday CASCADE;
CREATE MATERIALIZED VIEW po2sevenday AS
with pvt as
( -- begin query that extracts the data
  select ie.subject_id, ie.hadm_id, ie.icustay_id
  -- here we assign labels to ITEMIDs
  -- this also fuses together multiple ITEMIDs containing the same data
      , case
        when itemid = 50815 then 'O2FLOW'
        when itemid = 50816 then 'FIO2'
        when itemid = 50821 then 'PO2'
        else null
        end as label
        , charttime
        , value
        -- add in some sanity checks on the values
        , case
          when valuenum <= 0 then null
          when itemid = 50815 and valuenum >  70 then null -- O2 flow
          when itemid = 50821 and valuenum > 800 then null -- PO2
           -- conservative upper limit
        else valuenum
        end as valuenum
    from icustays ie
    left join labevents le
      on le.subject_id = ie.subject_id and le.hadm_id = ie.hadm_id
      and le.charttime between (ie.intime - interval '6' hour) and (ie.intime + interval '7' day)
      and le.ITEMID in(50815, 50816,  50821)
)
select pvt.SUBJECT_ID, pvt.HADM_ID, pvt.ICUSTAY_ID, pvt.CHARTTIME
, max(case when label = 'O2FLOW' then valuenum else null end) as O2FLOW
, max(case when label = 'FIO2' then valuenum else null end) as FIO2
, max(case when label = 'PO2' then valuenum else null end) as PO2
from pvt
group by pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.CHARTTIME
order by pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.CHARTTIME
