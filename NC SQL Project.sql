

--Generate a table with the name, population, and region of all North Carolina counties in 2020.

SELECT C.Name, C.Region, D1.Population
FROM NC_County AS C
JOIN
(SELECT fips, SUM(Count) As Population
FROM NC_Demographics
WHERE Year = 2020
GROUP BY fips) AS D1
ON C.fips = D1.fips

--Generate a table with the name and number of hospital beds found in each North Carolina county.


SELECT C.Name, HHC.#Hospital_Beds As Bed
FROM NC_County AS C
JOIN
(SELECT HC.fips, ISNULL(SUM(H.Beds),0) As #Hospital_Beds
FROM NC_HospitalCounty AS HC
LEFT JOIN NC_Hospital AS H
ON HC.Hid = H.Hid
GROUP BY HC.fips) AS HHC
ON C.fips = HHC.fips

--Generate a table with each North Carolina County and the date of its first confirmed COVID-19 case.

SELECT C.Name, c19.First_Case_Date
FROM NC_County AS C
JOIN
(SELECT fips, MIN(Date) As First_Case_Date
FROM NC_Covid19
WHERE Cases<>0 AND fips<>0
GROUP BY fips) AS c19
ON c.fips = c19.fips

--Generate a list of all North Carolina Counties and Hospital names in which there is more than one hospital; Sort by number of hospitals.

SELECT C.Name, H1.#Hospital As Hospitals
FROM NC_County AS C
JOIN
(SELECT HC.fips, ISNULL(Count(H.Name),0) As #Hospital
FROM NC_HospitalCounty AS HC
LEFT JOIN NC_Hospital AS H
ON HC.Hid = H.Hid
GROUP BY HC.fips
HAVING Count(H.Name)>1) AS H1
ON C.fips = H1.fips
ORDER BY Hospitals DESC

--Generate a sorted list, from high to low, of North Carolina county ratios of residents in the age range of 25 to 45 to
--their total population in 2020. The output should include the county's name, 25-45 population, total population and ratio.

SELECT C.Name, FP.Pop2545 AS CoolPeople, TP.TotalPop AS CountyPop, (1.0*FP.Pop2545)/TP.TotalPop As Ratio
FROM NC_County AS C
JOIN 
(SELECT fips, SUM(Count) AS Pop2545
FROM NC_Demographics
WHERE Year = 2020 AND agelo>=25 AND agehi<=45
GROUP BY fips) AS FP
ON C.fips = FP.fips
JOIN
(SELECT fips, SUM(Count) AS TotalPop
FROM NC_Demographics
WHERE Year = 2020
GROUP BY fips) AS TP
ON C.fips = TP.fips


--Generate a sorted list, from high to low, of the largest increase in North Carolina county ratios of residents in the age range
--of 25 to 45 to their total population in 2020 when compared to 2000. The output should include the county's name, 25-45 population ratio in 2020, and delta of ratio change.

SELECT Pop2020.Name As County, Pop2020.Ratio As Ratio2020, Pop2000.Ratio AS Ratio2000, (Pop2020.Ratio-Pop2000.Ratio) AS Delta_Ratio

FROM 

(SELECT C.Name, FP.Pop2545 AS CoolPeople, TP.TotalPop AS CountyPop, (1.0*FP.Pop2545)/TP.TotalPop As Ratio
FROM NC_County AS C
JOIN 
(SELECT fips, SUM(Count) AS Pop2545
FROM NC_Demographics
WHERE Year = 2020 AND agelo>=25 AND agehi<=45
GROUP BY fips) AS FP
ON C.fips = FP.fips
JOIN
(SELECT fips, SUM(Count) AS TotalPop
FROM NC_Demographics
WHERE Year = 2020
GROUP BY fips) AS TP
ON C.fips = TP.fips) AS Pop2020

JOIN

(SELECT C.Name, FP.Pop2545 AS CoolPeople, TP.TotalPop AS CountyPop, (1.0*FP.Pop2545)/TP.TotalPop As Ratio
FROM NC_County AS C
JOIN 
(SELECT fips, SUM(Count) AS Pop2545
FROM NC_Demographics
WHERE Year = 2000 AND agelo>=25 AND agehi<=45
GROUP BY fips) AS FP
ON C.fips = FP.fips
JOIN
(SELECT fips, SUM(Count) AS TotalPop
FROM NC_Demographics
WHERE Year = 2000
GROUP BY fips) AS TP
ON C.fips = TP.fips) AS Pop2000

ON Pop2020.Name = Pop2000.Name
ORDER BY Delta_Ratio DESC


--For each county, find the single day with the most COVID-19 deaths reported. Generate a list of each county, date, and the number of deaths.


SELECT c.Name, d.Date, d.Death
FROM NC_County AS c
JOIN
(SELECT rn.fips, rn.Date, rn.Death
FROM
(SELECT fips, Date, Death,
           ROW_NUMBER() OVER(PARTITION BY fips ORDER BY Death DESC) AS RowNum
    FROM NC_Covid19
) AS rn
WHERE rn.RowNum = 1 AND rn.fips <> 0) AS d
ON c.fips = d.fips

--On what single day were the most North Carolina COVID-19 deaths reported in the given reporting interval?
--For that day generate a list of each county, date, and the number of deaths. Include all counties, even those that did not report a death on the given date.

--SELECT Date, ROW_NUMBER() OVER(ORDER BY Total_Death DESC) AS r
--FROM
--(

SELECT c.Name, d.Date, d.Death
FROM NC_County AS c
JOIN
(SELECT c19.fips, c19.Date, c19.Death
FROM 
(SELECT f.Date, f.TD AS Max_Death
FROM
(SELECT Date, TD, ROW_NUMBER() OVER(ORDER BY TD DESC) AS rn
FROM
(SELECT Date, SUM(Death) AS TD
FROM NC_Covid19
GROUP BY Date
) AS c19d) AS f
WHERE f.rn=1) AS j
LEFT JOIN
NC_Covid19 AS c19
ON c19.Date = j.Date
WHERE c19.fips<>0) AS d
ON c.fips = d.fips


--Generate a list of North Carolina counties where white females of voting age (? 18 years old) are the largest voting age demographic in 2020. 
--In your report, provide multiple rows for each county of voting age residents broken down by race and sex. 
--You should only include rows for countys in which the largest voting demographic is white and female.

SELECT fips, race, sex, SUM(Count) AS Population
FROM NC_Demographics
WHERE agelo>=18 AND Year = 2020 AND Race<>'Total' AND fips IN (SELECT fips
FROM
(SELECT fips, Race, Sex, pop, DENSE_RANK() OVER(PARTITION BY fips ORDER BY pop DESC) AS RowNum
FROM
(SELECT fips, Race, Sex, SUM(Count) As pop
FROM NC_Demographics
WHERE Year = 2020 AND agelo >=18 AND Race<>'Total'
GROUP BY fips, Race, Sex) AS ft) As st
WHERE RowNum=1 AND Race = 'white' AND Sex = 'female')
GROUP BY fips, race, sex
ORDER BY fips,race,sex


--What is the difference in total population between the age group from 45 to 54 in 2020 and the age group from 25 to 34 in 2000 for each county?
--Your output should be a list of counties and differences sorted from smallest (could be negative) to largest.

SELECT c.Name As County, ft.PopDifference
FROM NC_County As c
JOIN
(SELECT t1.fips, (t1.pop-t2.pop) AS PopDifference
FROM
(SELECT fips, SUM(Count) As pop
FROM NC_Demographics
WHERE agelo>=45 AND agehi<=54 AND Year = 2020
GROUP BY fips) AS t1
JOIN
(SELECT fips, SUM(Count) As pop
FROM NC_Demographics
WHERE agelo>=25 AND agehi<=34 AND Year = 2000
GROUP BY fips) AS t2
ON t1.fips=t2.fips) As ft
ON c.fips=ft.fips
ORDER BY ft.PopDifference


--What 10 counties have the highest percentage of residents over 65 years of age in 2020? Provide both the county's name and percentage.

SELECT TOP 10 c.Name As County, ft.pctg65
FROM
NC_County As c
JOIN
(SELECT t1.fips, (t2.pop65/t1.pop) AS pctg65
FROM
(SELECT fips, SUM(Count) AS pop
FROM NC_Demographics
WHERE Year = 2020
Group BY fips) AS t1
JOIN
(SELECT fips, SUM(Count) AS pop65
FROM NC_Demographics
WHERE Year = 2020 AND agelo>=65
Group BY fips) AS t2
ON t1.fips=t2.fips) AS ft
ON c.fips = ft.fips
ORDER BY ft.pctg65 DESC


--What counties in North Carolina do not have a hospital? Provide each county's name, population, and non-white population percentage in 2020.

SELECT c.Name AS County, t1.pop, (t2.popnw/t1.pop) AS nwpctg
FROM NC_County As c
JOIN
(SELECT fips, SUM(Count) AS pop
FROM NC_Demographics
WHERE Year = 2020 AND fips IN 
(SELECT fips
FROM NC_HospitalCounty
WHERE Hid IS NULL)
GROUP BY fips) AS t1
ON c.fips = t1.fips
JOIN
(SELECT fips, SUM(Count) AS popnw
FROM NC_Demographics
WHERE Year = 2020 AND Race<>'White' AND fips IN 
(SELECT fips
FROM NC_HospitalCounty
WHERE Hid IS NULL)
GROUP BY fips) As t2
ON c.fips = t2.fips


--Which counties had the highest ratio of COVID-19 cases to hospital-bed capacity?
--Do not consider counties that do not have a hospital and hopitals that have no beds. Output the county's name, its cases-to-bed ratio.

SELECT c.Name AS County, ft.Ratio AS ChRatio
FROM NC_County As c
JOIN
(SELECT b.fips, (c.Cases/b.Total_Beds) AS Ratio
FROM
(SELECT HC.fips, SUM(H.Beds) As Total_Beds
FROM NC_HospitalCounty AS HC
JOIN
NC_Hospital AS H
ON HC.Hid = H.Hid
WHERE H.Beds<>0
GROUP BY HC.fips) AS b
JOIN
(SELECT fips, SUM(Cases) AS Cases
FROM NC_Covid19
WHERE fips<>0
GROUP BY fips) AS c
ON b.fips=c.fips) AS ft
ON c.fips =ft.fips
ORDER BY ChRatio DESC




 --Give a breakdown of COVID-19 cases, deaths, and hospitals by geographic region. For each of the geographic regions output the accumulated sum of COVID-19 cases
 --and deaths since January 22, 2020, as well as the number of hospital beds in that region.


SELECT c.Region, SUM(ft.CaseC) As RCase, SUM(ft.DeathC) As RDeath, SUM(ft.HBeds) As TBeds
FROM NC_County AS c
JOIN
(SELECT c19.fips, c19.CaseC, c19.DeathC, hb.HBeds
FROM
(SELECT fips, SUM(Cases) AS CaseC, SUM(Death) AS DeathC
FROM NC_Covid19
WHERE fips<>0
GROUP BY fips) AS c19
JOIN
(SELECT HC.fips, ISNULL(SUM(H.Beds),0) AS HBeds
FROM NC_HospitalCounty As HC
LEFT JOIN NC_Hospital As H
ON HC.Hid = H.Hid
GROUP BY HC.fips) AS hb
ON c19.fips=hb.fips) AS ft
ON c.fips = ft.fips
GROUP BY Region