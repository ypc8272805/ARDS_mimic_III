--此文件用于初步筛选病人群体的作用，对于ARDS的具体研究还要限制，患者进入ICU前七天是否有发生PF<300的情况，此文件不包含此内容
WITH icu_info as(
SELECT icu.subject_id,icu.hadm_id,icu.icustay_id,icu.intime,icu.outtime
  ,vent.vent
  ,pat.gender
,EXTRACT(EPOCH FROM icu.outtime - icu.intime)/60/60/24 as icu_length_of_stay --在ICU停留时间
,EXTRACT(EPOCH FROM  icu.intime-pat.dob)/60/60/24/365.242 AS age --显示年龄
,rank() OVER (PARTITION BY icu.subject_id ORDER BY icu.intime) AS icustay_id_order
FROM icustays icu
  INNER JOIN patients pat
  ON icu.subject_id = pat.subject_id
  LEFT JOIN ventfirstday vent--用这个表判断患者是否在ICU期间机械通气
  ON icu.icustay_id=vent.icustay_id
)
--在上面的临时表中查询
SELECT
  icu_info.subject_id,icu_info.hadm_id,icu_info.icustay_id,age,icu_info.gender,icu_info.intime,icu_info.outtime
--第一个限制条件，在ICU停留超过1天
,case
  when icu_info.icu_length_of_stay<1 then 1
  ELSE  0 END
AS exclusion_los
--限制年龄要大于16岁 为成年
,CASE
  WHEN icu_info.age<16 THEN 1
  ELSE 0 END
AS exclusion_age
--第一次进入ICU的患者
,CASE
  WHEN icu_info.icustay_id_order!=1 then 1
  ELSE 0 END
AS exclusion_first_stay
--在ICU中是否有机械通气
,CASE
  WHEN icu_info.vent=0 then 1
  ELSE 0 END
AS exclusion_vent
FROM icu_info
--LIMIT 10
