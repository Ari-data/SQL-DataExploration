SELECT Location, date, total_cases, total_deaths, population
FROM CovidDeaths_v1
ORDER BY strftime('%Y-%m-%d', date)

-- total_deaths/total_cases causes error due to integer division. Must CAST as FLOAT first.
SELECT Location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/total_cases)*100 AS DeathPercentage
FROM CovidDeaths_v1
ORDER BY Location, strftime('%Y-%m-%d', date)

-- to look at USA
SELECT Location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/total_cases)*100 AS DeathPercentage
FROM CovidDeaths_v1
WHERE Location like '%states%'
ORDER BY Location, strftime('%Y-%m-%d', date)

-- looking at Total Cases vs population
SELECT Location, date, total_cases, Population, total_deaths, (CAST(total_cases AS FLOAT)/population)*100 AS CasePercentage
FROM CovidDeaths_v1
WHERE Location like '%states%'
ORDER BY Location, strftime('%Y-%m-%d', date)

-- Looking at Countries with Highest Infection rate as compared to polulation
SELECT Location, MAX(total_cases) as HighestInfectionCount, Population, total_deaths, MAX((CAST(total_cases AS FLOAT)/population))*100 AS CasePercentage
FROM CovidDeaths_v1
GROUP BY Location, Population
ORDER BY CasePercentage DESC

-- Countries with highest death count per population
SELECT Location, MAX(CAST(Total_deaths AS INTEGER)) as TotalDeathCount
FROM CovidDeaths_v1
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- to remove the "Asia", "World" , etc from the Location field. (-- not working satisfactorily)
SELECT Location, MAX(CAST(Total_deaths AS INTEGER)) as TotalDeathCount
FROM CovidDeaths_v1
WHERE Continent is NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- by continent ( using IS NULL - gives wrong data)

SELECT Continent, MAX(CAST(Total_deaths AS INTEGER)) as TotalDeathCount
FROM CovidDeaths_v1
WHERE Continent is not NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC

-- Global Numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INTEGER)) AS total_deaths, SUM(CAST(new_deaths AS INTEGER))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths_v1
WHERE Continent IS NOT NULL
GROUP BY DATE
ORDER BY strftime('%Y-%m-%d', date), 2

--Global Number - grand total
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INTEGER)) AS total_deaths, SUM(CAST(new_deaths AS INTEGER))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths_v1
WHERE Continent IS NOT NULL
--GROUP BY DATE
ORDER BY strftime('%Y-%m-%d', date), 2

-- JOIN 
SELECT *
FROM CovidDeaths_v1 dea
JOIN CovidVaccinations_v1 vac
ON dea.location = vac.location
AND dea.date = vac.date

-- Total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidDeaths_v1 dea
JOIN CovidVaccinations_v1 vac
ON dea.location = vac.location
AND dea.date = vac.date
ORDER BY 1,2,3

AI for step SQLite (step-by-step query)

-- Step 1: Drop and Create Table
DROP TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TABLE PercentPopulationVaccinated (
    Continent TEXT,
    Location TEXT,
    Date TEXT,
    Population NUMERIC,
    NewVaccinations NUMERIC, 
    RollingPeopleVaccinated NUMERIC
);

-- Step 2: Insert Data (with subquery for SUM and strftime date formatting)
INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    strftime('%Y-%m-%d', dea.date) AS formatted_date,  -- Format the date properly
    dea.population, 
    vac.new_vaccinations, 
    RollingPeopleVaccinated
FROM 
    CovidDeaths_v1 dea
JOIN 
    CovidVaccinations_v2 vac
    ON dea.location = vac.location
    AND dea.date = vac.date
LEFT JOIN (
    -- Subquery to calculate the Rolling People Vaccinated
    SELECT 
        location,
        date,
        SUM(CAST(new_vaccinations AS INTEGER)) OVER (PARTITION BY location ORDER BY date) AS RollingPeopleVaccinated
    FROM 
        CovidVaccinations_v2
) AS subquery
    ON dea.location = subquery.location
    AND dea.date = subquery.date
WHERE dea.continent IS NOT NULL;

-- Step 3: Select Data with percentage calculation
SELECT 
    Continent, 
    Location, 
    Date, 
    Population, 
    NewVaccinations, 
    RollingPeopleVaccinated,
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM 
    PercentPopulationVaccinated;








