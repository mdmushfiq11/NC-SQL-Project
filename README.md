# NC-SQL-Project

The following step were taken in this project

Obtained raw dataset regarding North Carolina Covid 19 scenario which contains NC demographics, NC hospital, Covid 19 Cases, Covid 19 Deaths etc.

Raw dataset is then transformed into five relational tables using python. Table names and corresponding columns are as follows:

NC_Demographics (fips, Year, Race, Sex, agelo, agehi, count) : This table has fips which is a unique identifier of each NC county. Afterwards, starting from 2000 to 2020 population count is provided by race, sex, and age range.

NC_County (fips, Name, Region, COG, MSA): This table provides the name of each county, region, major service area, etc. This table is connected with NC_demographics through county identifier fips.

Covid19 (fips, Date, Cases, Death): Thsi table provides the number of cases and deaths occured in each county listed as fips for each date starting from January 2020 to August 2020. It is also connected with NC_demographics and NC_County through fips.

Hospital (Hid, Name, City, Beds, ICU, Discharge, PatientDays, Revenue) : This table has all hospital information of NC where Hid is a unique hospital identifier.

HospitalCounty (Hid, fips): This table connects hospital information to NC demographics, county information, and covid 19 information. One important thing to note, one county can have multiple hospitals, or some county might not have any hospital.

Processed tables created from python are then used in MS sql Server and explorative data analysis were performed which contains basic SQL concepts to advaned SQL concepts
