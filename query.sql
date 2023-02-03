/*
 Data Exploration - Covid Deaths and Vaccinations
 */

SELECT * FROM CovidDeaths ORDER BY 3,4;

-- Covert column type

ALTER TABLE CovidVaccinations
ADD
    COLUMN formatted_date date AFTER location;

UPDATE CovidVaccinations
set
    formatted_date = STR_TO_DATE(date, '%d/%m/%Y')
ALTER TABLE
    CovidVaccinations DROP COLUMN date;

ALTER TABLE CovidVaccinations CHANGE COLUMN formatted_date date date;

-- Set EMPTY cell to NULL

UPDATE CovidDeaths
SET continent = NULL
WHERE
    continent = '' -- Select data we're going to use
SELECT
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM CovidDeaths;

-- Total Cases vs Total Deaths

-- Showing likelihood of dying if contract COVID in Thailand

SELECT
    location,
    date,
    total_cases,
    total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE location = 'Thailand'
ORDER BY 1, 2;

-- Total Cases vs Population

-- Showing percentage of Thai who got COVID

SELECT
    location,
    date,
    population,
    total_cases, (total_cases / population) * 100 AS PercentThaiInfect
FROM CovidDeaths
WHERE location = 'Thailand'
ORDER BY 1, 2;

-- Showing countries with highest infection rate

SELECT
    location,
    MAX(total_cases) AS HighestInfect,
    MAX( (total_cases / population)) * 100 AS PercentPopulationInfect
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 3 DESC;

-- Showing countries with highest death count

SELECT
    location,
    MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY LOCATION
ORDER BY 2 DESC;

-- Showing death count by continent

SELECT
    continent,
    MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;

-- Global Number

SELECT
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_deaths,
    SUM(new_deaths) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Total Population vs Vaccinations

-- Showing Percentage of people who got at least 1 vaccination

SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location
        ORDER BY
            dea.location,
            dea.Date
    ) AS RollingPeopleVaccinated
FROM CovidDeaths dea
    JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY 2, 3;

-- From previous query, showing Percentage of them

-- Method 1: Using CTE

WITH
    PopvsVac (
        continent,
        location,
        date,
        population,
        new_vaccinations,
        RollingPeopleVaccinated
    ) AS (
        SELECT
            dea.continent,
            dea.location,
            dea.date,
            dea.population,
            vac.new_vaccinations,
            SUM(vac.new_vaccinations) OVER (
                PARTITION BY dea.location
                ORDER BY
                    dea.location,
                    dea.Date
            ) AS RollingPeopleVaccinated
        FROM CovidDeaths dea
            JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
        WHERE
            dea.continent IS NOT NULL
    )
SELECT
    *, (
        RollingPeopleVaccinated / population
    ) * 100 AS PopulationVaccinatedPercentage
FROM PopvsVac;

-- Method 2: Using Temp Table

DROP TABLE
    IF EXISTS PercentPopulationVaccinated CREATE TEMPORARY
TABLE
    PercentPopulationVaccinated (
        continent VARCHAR(255),
        location VARCHAR(255),
        date date,
        population numeric,
        new_vaccinations numeric,
        RollingPeopleVaccinated numeric
    );

INSERT INTO
    PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location
        ORDER BY
            dea.location,
            dea.Date
    ) AS RollingPeopleVaccinated
FROM CovidDeaths dea
    JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY 2, 3;

SELECT
    *, (
        RollingPeopleVaccinated / population
    ) * 100 AS PopulationVaccinatedPercentage
FROM
    PercentPopulationVaccinated;

-- Create View to store data for later visualizations

CREATE VIEW PERCENTPOPULATIONVACCINATED AS 
	SELECT
	    dea.continent,
	    dea.location,
	    dea.date,
	    dea.population,
	    vac.new_vaccinations,
	    SUM(vac.new_vaccinations) OVER (
	        PARTITION BY dea.Location
	        ORDER BY
	            dea.location,
	            dea.Date
	    ) AS RollingPeopleVaccinated
	FROM CovidDeaths dea
	    JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
