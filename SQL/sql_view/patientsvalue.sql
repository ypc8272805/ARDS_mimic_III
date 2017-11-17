CREATE MATERIALIZED VIEW patientsvalue AS WITH allvalue AS (
  SELECT cha.subject_id AS subject_id_c
  ,cha.hadm_id AS hadm_id_c
  ,cha.icustay_id AS icustay_id_c
  ,cha.charttime AS charttime_c
  ,cha.spo2 AS spo2,cha.pao2 AS pao2_c
  ,cha.fio2 AS  fio2_c
  ,cha.hr AS hr,cha.temp AS temp,cha.nbps AS nbps,cha.nbpd AS nbpd,cha.nbpm AS nbpm,cha.abps AS abps,cha.abpd AS abpd,cha.abpm AS abpm
  ,cha.rr AS rr,cha.tv AS tv,cha.pip AS pip,cha.plap AS plap,cha.mv AS mv,cha.map AS map
  ,cha.peep AS peep_c

  ,lab.subject_id AS subject_id_l,lab.hadm_id AS hadm_id_l,lab.icustay_id AS icustay_id_l,lab.charttime AS charttime_l
  ,lab.po2 AS pao2_l,lab.fio2 AS fio2_l,lab.peep AS peep_l
FROM patientschart cha
FULL JOIN patientslab lab
  ON cha.icustay_id=lab.icustay_id AND cha.charttime=lab.charttime
)
SELECT coalesce(subject_id_c,subject_id_l) AS subject_id
,coalesce(hadm_id_c,hadm_id_l) AS hadm_id
,coalesce(icustay_id_c,icustay_id_l) AS icustay_id
,coalesce(charttime_c,charttime_l) AS charttime
,spo2
,coalesce(pao2_l,pao2_c) AS pao2,pao2_c,pao2_l
,coalesce(fio2_l,fio2_c) AS fio2,fio2_c,fio2_l
,hr,temp,nbps,nbpd,nbpm,abps,abpd,abpm,rr,tv,pip,plap,mv,map
,coalesce(peep_l,peep_c) AS peep,peep_c,peep_l
FROM allvalue


