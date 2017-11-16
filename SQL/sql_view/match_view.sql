WITH pao2 AS (
  SELECT subject_id,hadm_id,icustay_id,charttime
  ,pao2
  FROM patientsvalue
  WHERE pao2 is NOT NULL
),spo2 AS (
  SELECT subject_id,hadm_id,icustay_id,charttime
  ,spo2
  FROM patientsvalue
  WHERE patientsvalue.spo2 IS NOT NULL
),fio2 AS (
  SELECT subject_id,hadm_id,icustay_id,charttime
  ,fio2
  FROM patientsvalue
  WHERE fio2 IS NOT NULL
),hr AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,hr
  FROM patientsvalue
  WHERE hr IS NOT NULL
),temp AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,temp
  FROM patientsvalue
  WHERE patientsvalue.temp IS NOT NULL
),nbps AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,nbps
  FROM patientsvalue
  WHERE patientsvalue.nbps IS NOT NULL
)
  ,patvalue AS (
--以pao2为标准，匹配2小时以前的spo2数据，如果没有就为空，如果有多条，选择最近的一条，也就是选择lastRowSpO2=1的就OK了
 SELECT pao2.subject_id,pao2.hadm_id,pao2.icustay_id,pao2.charttime,pao2.pao2
,row_number() OVER (PARTITION BY pao2.icustay_id,pao2.charttime ORDER BY spo2.charttime DESC ) AS lastRowSpO2
,spo2.spo2
FROM pao2
LEFT JOIN spo2
  ON pao2.icustay_id=spo2.icustay_id
  AND spo2.charttime BETWEEN pao2.charttime-INTERVAL '2' HOUR AND pao2.charttime
),stg1 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY fio2.charttime DESC ) AS lastRowFiO2
,fio2.fio2
FROM patvalue pat
  LEFT JOIN fio2
  ON fio2.icustay_id=pat.icustay_id
  AND fio2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowSpO2=1
),stg2 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowHR
,s2.hr
FROM stg1 pat
  LEFT JOIN hr s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowFiO2=1
),stg3 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowTemp
,s2.temp
FROM stg2 pat
  LEFT JOIN temp s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowHR=1
)
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowNbps
,s2.nbps
FROM stg3 pat
  LEFT JOIN nbps s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowTemp=1








