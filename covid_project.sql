USE Covid19;


SELECT *
FROM coviddeaths;

SELECT *
FROM covidvaccinations;


-- Total Cases vs Population
-- Chances of getting infected with Covid

SELECT
	location,
	date,
	Population,
	new_cases,
	(new_cases / population) * 100 AS PercentPopulationInfected
FROM coviddeaths
WHERE continent IS NOT NULL -- remove enntries with continent names present in location columns
ORDER BY Location, date;


-- Total Cases vs Total Deaths
-- Chances of dying if getting covid in your country


SELECT 
	Location,
	date,
	total_cases,
	total_deaths,
	(total_deaths / total_cases) * 100 AS DeathPercentage
FROM 
	coviddeaths
WHERE continent IS NOT NULL
-- AND location LIKE 'India'
ORDER BY Location, date;



-- Countries with Highest Infection Rate compared to Population


SELECT
	Location,
	Population,
	MAX(total_cases) AS TotalInfections,
	MAX((total_cases / population)) * 100 AS InfectionRate
FROM 
	coviddeaths
WHERE continent IS NOT NULL
GROUP BY
	Location,
	Population
ORDER BY InfectionRate DESC;



-- Countries with Highest Death Count per Population


SELECT
	Location,
	population,
	MAX(CAST(Total_deaths AS INT)) AS TotalDeaths,
	MAX((total_deaths / population)) * 100 AS DeathRate
FROM 
	coviddeaths
WHERE continent IS NOT NULL
GROUP BY
	Location,
	Population
ORDER BY DeathRate DESC;


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population


SELECT 
	continent,
	SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM 
	coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;



-- GLOBAL NUMBERS TILL DATE

SELECT
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS int)) / SUM(New_Cases) * 100 AS DeathPercentage
FROM 
	coviddeaths
WHERE continent IS NOT NULL;



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine


SELECT
	cd.continent,
	cd.location,
	cd.date,
	cd.population,
	cv.new_vaccinations,
	SUM(CAST(cv.new_vaccinations as bigint)) OVER (Partition by cd.Location Order by cd.location,cd.Date) as RollingPeopleVaccinated
FROM 
	coviddeaths cd
JOIN 
	covidvaccinations cv
ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY
	cd.location,
	cd.date;




-- Using CTE to perform Calculation on Partition By in previous query


WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT
	cd.continent,
	cd.location,
	cd.date,
	cd.population,
	cv.new_vaccinations,
	SUM(CONVERT(bigint,cv.new_vaccinations)) OVER (Partition by cd.Location Order by cd.location, cd.Date) as RollingPeopleVaccinated
FROM 
	coviddeaths cd
JOIN 
	covidvaccinations cv
On cd.location = cv.location
	and cd.date = cv.date
WHERE cd.continent IS NOT NULL 
-- order by cd.location,cd.date
)

SELECT *,
	(RollingPeopleVaccinated/Population)*100
FROM PopvsVac;



-- Using Temp Table to perform Calculation on Partition By in previous query


DROP Table if exists #PercentPopulationVaccinated;
  
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

Insert into #PercentPopulationVaccinated

SELECT
	cd.continent,
	cd.location,
	cd.date,
	cd.population,
	cv.new_vaccinations,
	SUM(CONVERT(bigint,cv.new_vaccinations)) OVER (Partition by cd.Location Order by cd.location, cd.Date) as RollingPeopleVaccinated
FROM 
	coviddeaths cd
JOIN 
	covidvaccinations cv
On cd.location = cv.location
	and cd.date = cv.date
WHERE cd.continent IS NOT NULL;
-- order by cd.location,cd.date


Select *,
	(RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated;




-- Creating View to store data for later visualizations


CREATE VIEW PercentPopulationVaccinated as

SELECT
	cd.continent,
	cd.location,
	cd.date,
	cd.population,
	cv.new_vaccinations,
	SUM(CONVERT(bigint,cv.new_vaccinations)) OVER (Partition by cd.Location Order by cd.Date) as RollingPeopleVaccinated,
	((SUM(CONVERT(bigint,cv.new_vaccinations)) OVER (Partition by cd.Location Order by cd.Date))/population)*100 as VaccinationPerc
FROM 
	coviddeaths cd
JOIN 
	covidvaccinations cv
ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;


Select * from PercentPopulationVaccinated;


-- Countries with maximum percentage of fully vaccinated people 

SELECT
	cd.continent,
	cd.Location,
	MAX((cv.total_boosters / cd.population)) * 100 AS PercPopVacc
FROM 
	coviddeaths cd
JOIN 
	covidvaccinations cv
ON cd.location = cv.location
	and cd.date = cv.date
WHERE cd.continent is not null
GROUP BY
	cd.location,cd.continent
ORDER BY PercPopVacc DESC;


