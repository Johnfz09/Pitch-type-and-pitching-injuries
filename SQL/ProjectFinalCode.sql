--Query 1: Shows each player and wheather or not they had Tommy John Surgery.
SELECT
    Player.Name,
    Injuries.TJS
FROM Player
JOIN Injuries
ON Player.Name = Injuries.Name;

--Query 2: Player Pitching profile. Main Dashbaord for quick look ups and facts
SELECT
    Player.Name,
    Injuries.Tjs,
    PitchStats.InningsPitched,
    PitchStats.Pitches
FROM Player
JOIN Injuries
ON player.Name= Injuries.Name
JOIN PitchStats
ON player.NAME = PitchStats.Name

--Query 3: Full joined player injury and pitch type data
SELECT
    Player.Name,
    Injuries.TJS,
    PitchTypes.PitchCode,
    PitchTypes.PitchName,
    PitchUsage.UsagePercentage
FROM Player
JOIN Injuries
On Player.Name = Injuries.Name
JOIN PitchUsage
On Player.Name = PitchUsage.PitcherName
JOIN PitchTypes
on PitchUsage.PitchType = PitchTypes.PitchCode;

--Query 4: Four-seam fastball usage vs Tommy John count
DECLARE @MinUsage DECIMAL (5,2);
SET @MinUsage = 30;

SELECT
    Player.Name,
    Injuries.TJS,
    PitchUsage.UsagePercentage
FROM Player
JOIN Injuries
ON Player.Name = Injuries.Name
JOIN PitchUsage
On Player.Name = PitchUsage.PitcherName
JOIN PitchTypes
ON PitchUsage.PitchType = PitchTypes.PitchCode
WHERE PitchTypes.PitchCode = 'FF'
AND PitchUsage.UsagePercentage >= @MinUsage;

--Query 5: Slider usage vs Tommy John count
SELECT
    Player.Name,
    Injuries.TJS,
    PitchUsage.UsagePercentage
FROM Player
JOIN Injuries
ON Player.Name = Injuries.Name
JOIN PitchUsage
ON Player.Name = PitchUsage.PitcherName
JOIN PitchTypes
ON PitchUsage.PitchType = PitchTypes.PitchCode
WHERE PitchTypes.PitchCode = 'SL'
ORDER BY PitchUsage.UsagePercentage DESC;

-- Query 6: Changeup usage vs Tommy John count
SELECT
    Player.Name,
    Injuries.TJS,
    PitchUsage.UsagePercentage
FROM Player
JOIN Injuries
ON Player.Name = Injuries.Name
JOIN PitchUsage
ON Player.Name= PitchUsage.PitcherName
JOIN PitchTypes
ON PitchUsage.PitchType = PitchTypes.PitchCode
WHERE PitchTypes.PitchCode = 'CH'
ORDER BY PitchUsage.UsagePercentage DESC;

/* Question 7: Is there a significant difference in Breaking Ball (Slider/Curveball) 
usage between injured and healthy pitchers? 
Purpose: To evaluate the impact of high-stress breaking pitches on TJS rates. */

SELECT 
    I.TJS AS Injury_Status,
    COUNT(I.TJS) AS Total_Pitchers,
    AVG(PU.UsagePercentage) AS Avg_Breaking_Ball_Usage
FROM Injuries I
JOIN PitchUsage PU ON I.Name = PU.PitcherName
WHERE PU.PitchType IN ('SL', 'CU', 'KC', 'ST')
GROUP BY I.TJS;

/* Question 8: Does relying heavily on Fastballs (Four-Seam/Sinker) correlate with 
higher instances of Tommy John Surgery? 
Purpose: To see if high-velocity fastball usage increases injury risk. */

SELECT 
    I.TJS AS Injury_Status,
    COUNT(I.TJS) AS Total_Pitchers,
    AVG(PU.UsagePercentage) AS Avg_Fastball_Usage
FROM Injuries I
JOIN PitchUsage PU ON I.Name = PU.PitcherName
WHERE PU.PitchType IN ('FF', 'SI', 'FC', 'FS')
GROUP BY I.TJS;

/* Question 9: How does the usage of offspeed pitches (Changeup/Splitter) relate to 
injury outcomes? 
Purpose: To investigate if specific offspeed selections are safer for the elbow. */

SELECT 
    I.TJS AS Injury_Status,
    COUNT(I.TJS) AS Total_Pitchers,
    AVG(PU.UsagePercentage) AS Avg_Offspeed_Usage
FROM Injuries I
JOIN PitchUsage PU ON I.Name = PU.PitcherName
WHERE PU.PitchType IN ('CH', 'FS')
GROUP BY I.TJS;

/* Question 10: Which pitch types are used on average more than 20% of the time 
by the group of pitchers who have undergone TJS? 
Purpose: To identify the primary pitch types favored by the injured population. */

SELECT 
    PU.PitchType,
    AVG(PU.UsagePercentage) AS AvgUsage
FROM PitchUsage PU
JOIN Injuries I ON I.Name = PU.PitcherName
WHERE I.TJS = 1
GROUP BY PU.PitchType
HAVING AVG(PU.UsagePercentage) > 20;

/* Question 11: Who are the pitchers that have had TJS, and what is the pitch 
they throw most frequently? 
Purpose: To use a subquery to filter for injured players and identify their 
primary pitch selection. */

SELECT 
    PU.PitcherName, 
    PU.PitchType, 
    PU.UsagePercentage
FROM PitchUsage PU
WHERE PU.PitcherName IN (SELECT Name FROM Injuries WHERE TJS = 1)
AND PU.UsagePercentage = (
    SELECT MAX(UsagePercentage) 
    FROM PitchUsage 
    WHERE PitcherName = PU.PitcherName
);

/* Question 12: Which pitch type has the highest average usage among the TJS group? 
Purpose: To demonstrate the use of a CTE to simplify the analysis of pitch 
usage within the injured population. */

WITH InjuredPitchers AS (
    SELECT PU.PitchType, PU.UsagePercentage
    FROM PitchUsage PU
    JOIN Injuries I ON I.Name = PU.PitcherName
    WHERE I.TJS = 1
)
SELECT 
    PitchType, 
    AVG(UsagePercentage) AS AvgUsageAmongInjured
FROM InjuredPitchers
GROUP BY PitchType
ORDER BY AvgUsageAmongInjured DESC;

/* Question 13: Which pitch type has the highest average usage among the TJS group? 
Purpose: To demonstrate the use of a CTE to simplify the analysis of pitch 
usage within the injured population. */

WITH VelocityStats AS (
    SELECT 
        I.TJS,
        PPS.avg_velocity
    FROM PlayerPitchStats PPS
    JOIN Injuries I ON I.Name = PPS.Name
)
SELECT 
    CASE WHEN TJS = 1 THEN 'Injured (TJS)' ELSE 'Healthy' END AS InjuryStatus,
    AVG(avg_velocity) AS AvgFastballVelocity,
    COUNT(*) AS PitcherCount
FROM VelocityStats
GROUP BY TJS;

/* Question 14: Which pitch type has the highest average usage among the TJS group? 
Purpose: To demonstrate the use of a CTE to simplify the analysis of pitch 
usage within the injured population. */

WITH SpinStats AS (
    SELECT 
        I.TJS,
        PPS.average_spin_rate
    FROM PlayerPitchStats PPS
    JOIN Injuries I ON I.Name = PPS.Name
)
SELECT 
    CASE WHEN TJS = 1 THEN 'Injured (TJS)' ELSE 'Healthy' END AS InjuryStatus,
    AVG(average_spin_rate) AS AvgTotalSpinRate,
    COUNT(*) AS PitcherCount
FROM SpinStats
GROUP BY TJS;

-- View
GO
CREATE VIEW vw_PlayerPitchSummary AS
SELECT
    Player.Name,
    Injuries.TJS,
    PitchTypes.PitchCode,
    PitchUsage.UsagePercentage
FROM Player
JOIN Injuries
ON Player.Name = Injuries.Name
JOIN PitchUsage
ON Player.Name = PitchUsage.PitcherName
JOIN PitchTypes
ON PitchUsage.PitchType = PitchTypes.PitchCode;
GO

-- Stored Procedure
CREATE PROCEDURE usp_FilterPlayersByPitchAndInjury
    @MinInjuryCount INT,
    @MinPitchPercent DECIMAL(5,2),
    @PitchCode VARCHAR(10)
AS
BEGIN
    IF @PitchCode IN ('FF', 'SL', 'CH', 'CU', 'SI', 'FC', 'FS', 'KC', 'ST')
    BEGIN
        SELECT
            Player.Name,
            Injuries.TJS,
            PitchTypes.PitchCode,
            PitchUsage.UsagePercentage
        FROM Player
        JOIN Injuries
            ON Player.Name = Injuries.Name
        JOIN PitchUsage
            ON Player.Name = PitchUsage.PitcherName
        JOIN PitchTypes
            ON PitchUsage.PitchType = PitchTypes.PitchCode
        WHERE Injuries.TJS >= @MinInjuryCount
          AND PitchUsage.UsagePercentage >= @MinPitchPercent
          AND PitchTypes.PitchCode = @PitchCode;
    END
    ELSE
    BEGIN
        SELECT 'Invalid Pitch Type' AS Message;
    END
END;