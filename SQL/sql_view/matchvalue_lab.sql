DROP MATERIALIZED VIEW IF EXISTS matchvalue_lab CASCADE;
CREATE MATERIALIZED VIEW matchvalue_lab AS
WITH pao2 AS (
  SELECT subject_id,hadm_id,icustay_id,charttime
  ,pao2_l AS pao2
  FROM patientsvalue
  WHERE pao2_l is NOT NULL
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
),nbpd AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,nbpd
  FROM patientsvalue
  WHERE patientsvalue.nbpd IS NOT NULL
),nbpm AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,nbpm
  FROM patientsvalue
  WHERE patientsvalue.nbpm IS NOT NULL
),abps AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,abps
  FROM patientsvalue
  WHERE patientsvalue.abps IS NOT NULL
),abpd AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,abpd
  FROM patientsvalue
  WHERE patientsvalue.abpd IS NOT NULL
),abpm AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,abpm
  FROM patientsvalue
  WHERE patientsvalue.abpm IS NOT NULL
),rr AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,rr
  FROM patientsvalue
  WHERE patientsvalue.rr IS NOT NULL
),tv AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,tv
  FROM patientsvalue
  WHERE patientsvalue.tv IS NOT NULL
),pip AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,pip
  FROM patientsvalue
  WHERE patientsvalue.pip IS NOT NULL
),plap AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,plap
  FROM patientsvalue
  WHERE patientsvalue.plap IS NOT NULL
),mv AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,mv
  FROM patientsvalue
  WHERE patientsvalue.mv IS NOT NULL
),map AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,map
  FROM patientsvalue
  WHERE patientsvalue.map IS NOT NULL
),peep AS (
 SELECT subject_id,hadm_id,icustay_id,charttime
  ,peep
  FROM patientsvalue
  WHERE patientsvalue.peep IS NOT NULL
),patvalue AS (
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
),stg4 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowNbps
,s2.nbps
FROM stg3 pat
  LEFT JOIN nbps s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowTemp=1
),stg5 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowNbpd
,s2.nbpd
FROM stg4 pat
  LEFT JOIN nbpd s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowNbps=1
),stg6 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps,pat.nbpd
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowNbpm
,s2.nbpm
FROM stg5 pat
  LEFT JOIN nbpm s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowNbpd=1
),stg7 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps,pat.nbpd
,pat.nbpm
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowAbps
,s2.abps
FROM stg6 pat
  LEFT JOIN abps s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowNbpm=1
),stg8 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps,pat.nbpd
,pat.nbpm,pat.abps
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowAbpd
,s2.abpd
FROM stg7 pat
  LEFT JOIN abpd s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowAbps=1
),stg9 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps,pat.nbpd
,pat.nbpm,pat.abps,pat.abpd
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowAbpm
,s2.abpm
FROM stg8 pat
  LEFT JOIN abpm s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowAbpd=1
),stg10 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps,pat.nbpd
,pat.nbpm,pat.abps,pat.abpd,pat.abpm
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowRR
,s2.rr
FROM stg9 pat
  LEFT JOIN rr s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowAbpm=1
),stg11 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps,pat.nbpd
,pat.nbpm,pat.abps,pat.abpd,pat.abpm,pat.rr
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowTV
,s2.tv
FROM stg10 pat
  LEFT JOIN tv s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowRR=1
),stg12 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps,pat.nbpd
,pat.nbpm,pat.abps,pat.abpd,pat.abpm,pat.rr,pat.tv
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowPIP
,s2.pip
FROM stg11 pat
  LEFT JOIN pip s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowTV=1
),stg13 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps,pat.nbpd
,pat.nbpm,pat.abps,pat.abpd,pat.abpm,pat.rr,pat.tv,pat.pip
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowPLAP
,s2.plap
FROM stg12 pat
  LEFT JOIN plap s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowPIP=1
),stg14 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps,pat.nbpd
,pat.nbpm,pat.abps,pat.abpd,pat.abpm,pat.rr,pat.tv,pat.pip,pat.plap
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowMV
,s2.mv
FROM stg13 pat
  LEFT JOIN mv s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowPLAP=1
),stg15 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps,pat.nbpd
,pat.nbpm,pat.abps,pat.abpd,pat.abpm,pat.rr,pat.tv,pat.pip,pat.plap,pat.mv
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowMAP
,s2.map
FROM stg14 pat
  LEFT JOIN map s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowMV=1
),stg16 AS (
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps,pat.nbpd
,pat.nbpm,pat.abps,pat.abpd,pat.abpm,pat.rr,pat.tv,pat.pip,pat.plap,pat.mv,pat.map
,row_number() OVER (PARTITION BY pat.icustay_id,pat.charttime ORDER BY s2.charttime DESC ) AS lastRowPEEP
,s2.peep
FROM stg15 pat
  LEFT JOIN peep s2
  ON s2.icustay_id=pat.icustay_id
  AND s2.charttime BETWEEN pat.charttime-INTERVAL '4' HOUR AND pat.charttime
WHERE pat.lastRowMAP=1
)
SELECT pat.subject_id,pat.hadm_id,pat.icustay_id,pat.charttime,pat.pao2,pat.spo2,pat.fio2,pat.hr,pat.temp,pat.nbps,pat.nbpd
,pat.nbpm,pat.abps,pat.abpd,pat.abpm,pat.rr,pat.tv,pat.pip,pat.plap,pat.mv,pat.map,pat.peep
FROM stg16 pat
WHERE pat.lastRowPEEP=1








