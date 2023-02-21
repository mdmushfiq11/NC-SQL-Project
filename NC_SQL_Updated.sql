

--Generate a table with the name, population, and region of all North Carolina counties in 2020.

with CTE AS
	(SELECT fips, SUM(Count) AS Population
	FROM NC_Demographics
	WHERE Year=2020
	GROUP BY fips)
SELECT c.Name AS County, c.Region AS Region, d.Population AS Population
FROM NC_County AS c
JOIN CTE AS d
ON c.fips = d.fips

--Generate a table with the name and number of hospital beds found in each North Carolina county.

with Hospital_Beds AS
	(SELECT NHC.fips, ISNULL(SUM(NH.Beds),0) AS Beds
	FROM NC_HospitalCounty AS NHC
	LEFT JOIN NC_Hospital AS NH
	ON NHC.Hid=NH.Hid
	GROUP BY NHC.fips)
SELECT c.Name AS County, b.Beds AS #Beds
FROM NC_County AS c
JOIN Hospital_Beds AS b
ON c.fips = b.fips

--Generate a table with each North Carolina County and the date of its first confirmed COVID-19 case.

WITH Covid_Case AS
	(SELECT fips, MIN(Date) AS first_Case
	FROM NC_Covid19
	WHERE Cases>0 AND fips<>0
	GROUP BY fips)
SELECT c.Name AS County, cc.first_Case AS Date
FROM NC_County AS c
JOIN Covid_Case AS cc
ON c.fips =cc.fips

--Generate a list of all North Carolina Counties and Hospital names in which there is more than one hospital; Sort by number of hospitals.

WITH Hospital_Count AS
	(SELECT NHC.fips, NH.Name, COUNT(NH.Name) OVER(PARTITION BY fips) AS #Hospitals
	FROM NC_HospitalCounty AS NHC
	LEFT JOIN NC_Hospital AS NH
	ON NHC.Hid=NH.Hid)
SELECT c.Name AS County, H.Name AS Hospital, H.#Hospitals
FROM Hospital_Count AS H
JOIN NC_County As c
ON H.fips=c.fips
WHERE #Hospitals>1
ORDER BY #Hospitals DESC

--Generate a sorted list, from high to low, of North Carolina county ratios of residents in the age range of 25 to 45 to
--their total population in 2020. The output should include the county's name, 25-45 population, total population and ratio.


WITH Population2545 AS
	(SELECT fips, SUM(Count) As pop
	FROM NC_Demographics
	WHERE agelo>=25 AND agehi<=45 AND Year=2020
	GROUP BY fips),
Population AS
	(SELECT fips, SUM(Count) As pop
	FROM NC_Demographics
	WHERE Year=2020
	GROUP BY fips)
SELECT c.Name, p2545.pop AS Pop_2545, (p2545.pop/p.pop) AS Ratio
FROM NC_County AS c
JOIN Population2545 AS p2545
ON c.fips=p2545.fips
JOIN Population AS p
ON c.fips=p.fips
ORDER BY Ratio DESC

--Generate a sorted list, from high to low, of the largest increase in North Carolina county ratios of residents in the age range
--of 25 to 45 to their total population in 2020 when compared to 2000. The output should include the county's name, 25-45 population ratio in 2020, and delta of ratio change.

WITH cool2020 AS
	(SELECT p.fips, p2545.pop AS Pop_2545, (p2545.pop/p.pop) AS Ratio
	FROM (SELECT fips, SUM(Count) As pop
		FROM NC_Demographics
		WHERE agelo>=25 AND agehi<=45 AND Year=2020
		GROUP BY fips) AS p2545
	JOIN (SELECT fips, SUM(Count) As pop
		FROM NC_Demographics
		WHERE Year=2020
		GROUP BY fips) AS p
	ON p2545.fips=p.fips),

	cool2000 As
	(SELECT p.fips, p2545.pop AS Pop_2545, (p2545.pop/p.pop) AS Ratio
	FROM (SELECT fips, SUM(Count) As pop
		FROM NC_Demographics
		WHERE agelo>=25 AND agehi<=45 AND Year=2000
		GROUP BY fips) AS p2545
	JOIN (SELECT fips, SUM(Count) As pop
		FROM NC_Demographics
		WHERE Year=2000
		GROUP BY fips) AS p
	ON p2545.fips=p.fips)

SELECT c.Name AS County, p2020.Ratio, (p2020.Ratio-p2000.Ratio) AS Delta_Ratio
FROM NC_County As c
JOIN cool2020 As p2020
ON c.fips=p2020.fips
JOIN cool2000 As p2000
ON c.fips=p2000.fips
ORDER BY Delta_Ratio DESC

--For each county, find the single day with the most COVID-19 deaths reported. Generate a list of each county, date, and the number of deaths.

WITH Max_Death AS
	(SELECT fips, Date, Death, ROW_NUMBER() OVER (PARTITION BY fips ORDER BY Death DESC, Date) AS Serial
	FROM NC_Covid19
	WHERE fips<>0)
SELECT c.Name, d.Date, d.Death
FROM NC_County As c
JOIN Max_Death As d
ON c.fips=d.fips
WHERE d.Serial=1


--On what single day were the most North Carolina COVID-19 deaths reported in the given reporting interval?
--For that day generate a list of each county, date, and the number of deaths. Include all counties, even those that did not report a death on the given date.

WITH Max_Death_Day AS
	(SELECT fips, Date, Death
	FROM NC_Covid19
	WHERE fips<>0 AND Date = (SELECT TOP 1 Date
								FROM NC_Covid19
								GROUP BY Date
								ORDER BY SUM(Death) DESC))
SELECT c.Name AS County, d.Date, d.Death
FROM NC_County AS c
JOIN Max_Death_Day AS d
ON c.fips=d.fips


--Generate a list of North Carolina counties where white females of voting age (? 18 years old) are the largest voting age demographic in 2020. 
--In your report, provide multiple rows for each county of voting age residents broken down by race and sex. 
--You should only include rows for countys in which the largest voting demographic is white and female.

WITH ft AS
		(SELECT fips, Race, Sex, SUM(Count) As Population
		FROM NC_Demographics
		WHERE Year=2020 AND agelo>=18 AND Race<>'Total'
		GROUP BY fips, Race, Sex),
	st AS
		(SELECT fips, Race, Sex, Population, DENSE_RANK() OVER(PARTITION BY fips ORDER BY Population DESC) AS rank
		FROM ft),
	tt AS
		(SELECT fips, Population
		FROM st
		WHERE Race='white' AND Sex='Female' AND rank=1)
SELECT c.Name As County, d.Race, d.Sex, SUM(d.Count) AS Total_Population
FROM NC_County AS c
JOIN NC_Demographics AS d
ON c.fips=d.fips
JOIN tt AS t
ON d.fips=t.fips
WHERE d.Race<>'Total'
GROUP BY c.Name, d.Race, d.Sex
ORDER BY c.Name, SUM(d.Count) DESC

--What is the difference in total population between the age group from 45 to 54 in 2020 and the age group from 25 to 34 in 2000 for each county?
--Your output should be a list of counties and differences sorted from smallest (could be negative) to largest.

WITH p1 AS
			(SELECT fips, SUM(Count) As p2020
			FROM NC_Demographics
			WHERE agelo>=45 AND agehi<=54 AND Year=2020
			GROUP BY fips),
	p2 AS
			(SELECT fips, SUM(Count) As p2000
			FROM NC_Demographics
			WHERE agelo>=25 AND agehi<=34 AND Year=2000
			GROUP BY fips),
	p3 AS
			(SELECT p1.fips, (p1.p2020-p2.p2000) AS Difference
			FROM p1
			JOIN p2
			ON p1.fips=p2.fips)
SELECT c.Name AS County, p3.Difference
FROM NC_County AS c
JOIN p3
ON c.fips=p3.fips
ORDER BY Difference

--What 10 counties have the highest percentage of residents over 65 years of age in 2020? Provide both the county's name and percentage.

 WITH ft AS
		(SELECT fips, SUM(Count) As p1
		FROM NC_Demographics
		WHERE agelo>=65 AND Year=2020
		GROUP BY fips),
	st AS
		(SELECT fips, SUM(Count) As p2
		FROM NC_Demographics
		WHERE Year=2020
		GROUP BY fips)
SELECT TOP 10 c.Name AS County, p1/p2 As pop_percetage
FROM NC_County AS c
JOIN ft
ON c.fips=ft.fips
JOIN st
ON ft.fips=st.fips
ORDER BY pop_percetage DESC

--What counties in North Carolina do not have a hospital? Provide each county's name, population, and non-white population percentage in 2020.



 WITH ft AS
		(SELECT fips, SUM(Count) As p1
		FROM NC_Demographics
		WHERE Race<>'White' AND Year=2020
		GROUP BY fips),
	st AS
		(SELECT fips, SUM(Count) As p2
		FROM NC_Demographics
		WHERE Year=2020
		GROUP BY fips)
SELECT c.Name AS County, st.p2 AS Population, (ft.p1/st.p2) AS Non_white_pctg
FROM NC_County As c
JOIN ft
ON c.fips=ft.fips
JOIN st
ON ft.fips=st.fips
WHERE c.fips IN (SELECT fips
				FROM NC_HospitalCounty
				WHERE Hid IS NULL)
ORDER BY County

--Which counties had the highest ratio of COVID-19 cases to hospital-bed capacity?
--Do not consider counties that do not have a hospital and hopitals that have no beds. Output the county's name, its cases-to-bed ratio.

WITH CaseTable AS
			(SELECT fips, SUM(Cases) AS c1
			FROM NC_Covid19
			GROUP BY fips),
	HospitalTable AS
			(SELECT HC.fips, SUM(H.Beds) As Bed
			FROM NC_Hospital As H
			JOIN NC_HospitalCounty HC
			ON H.Hid=HC.Hid
			GROUP BY HC.fips
			HAVING SUM(H.Beds)>0)
SELECT c.Name As County, (CT.c1/HT.Bed) AS Ratio
FROM NC_County AS c
JOIN CaseTable AS CT
ON c.fips=CT.fips
JOIN HospitalTable AS HT
ON HT.fips=CT.fips
ORDER BY Ratio DESC

			
 --Give a breakdown of COVID-19 cases, deaths, and hospitals by geographic region. For each of the geographic regions output the accumulated sum of COVID-19 cases
 --and deaths since January 22, 2020, as well as the number of hospital beds in that region.

 WITH covid As
			(SELECT fips, SUM(Cases) As #Cases, SUM(Death) AS #Deaths
			FROM NC_Covid19
			WHERE fips<>0
			GROUP BY fips),
	Hospital AS
			(SELECT HC.fips, ISNULL(SUM(H.Beds),0) As Bed
			FROM NC_HospitalCounty As HC
			LEFT JOIN NC_Hospital AS H
			ON H.Hid=HC.Hid
			GROUP BY HC.fips)
SELECT c.Region, SUM(cv.#Deaths) As RDeath, SUM(cv.#Cases) AS RCase, SUM(hp.Bed) AS RBeds
FROM NC_County As c
JOIN covid As cv
ON c.fips=cv.fips
JOIN Hospital As hp
ON cv.fips=hp.fips
GROUP BY c.Region








