USE rosettacode;
GO

SET NOCOUNT ON;
GO

CREATE TABLE dbo.numbers (n INT PRIMARY KEY);
GO

-- NOTE If you want to play more than 10000 games, you need to extend the query generating the numbers table by adding
-- next cross joins. Now the table contains enough values to solve the task and it takes less processing time.

WITH sample100 AS (
    SELECT TOP(100) object_id
    FROM master.sys.objects
)
INSERT numbers
    SELECT ROW_NUMBER() OVER (ORDER BY A.object_id) AS n
    FROM sample100 AS A
        CROSS JOIN sample100 AS B;
GO

CREATE TABLE dbo.randoms (n INT PRIMARY KEY, random INT);
GO

CREATE TABLE dbo.drawers (drawer INT PRIMARY KEY, card INT);
GO

CREATE TABLE dbo.results (strategy VARCHAR(10), game INT, result BIT, PRIMARY KEY (game, strategy));
GO

CREATE FUNCTION dbo.randomStrategy(@prisoner INT, @card INT)
RETURNS INT
AS BEGIN
    -- Simulate the game where the prisoners randomly open drawers.

    DECLARE @random INT = (SELECT random FROM randoms WHERE n = @prisoner);

    RETURN (SELECT TOP(1) card FROM drawers WHERE drawer = @random);
END
GO

CREATE FUNCTION dbo.optimalStrategy(@prisoner INT, @card INT)
RETURNS INT
AS BEGIN
    -- Simulate the game where the prisoners use the optimal strategy mentioned in the Wikipedia article.

    -- First opening the drawer whose outside number is his prisoner number.
    -- If the card within has his number then he succeeds...
    if (@card IS NULL)
        RETURN (SELECT TOP(1) card FROM drawers WHERE drawer = @prisoner);
   
    -- ...otherwise he opens the drawer with the same number as that of the revealed card.
    RETURN (SELECT TOP(1) card FROM drawers WHERE drawer = @card);
END
GO

CREATE PROCEDURE dbo.shuffle
AS BEGIN
    SET NOCOUNT ON;

    DECLARE @i INT = 1;
    DECLARE @max INT = (SELECT COUNT(*) FROM drawers);
    WHILE @i <= @max BEGIN
        DECLARE @j INT = ROUND(RAND() * (@max - @i), 0) + @i;
        IF @i <> @j
            UPDATE drawers
            SET card = CASE drawer WHEN @i THEN @j ELSE @i END
            WHERE drawer IN (@i, @j);

        SET @i = @i + 1;
    END
END
GO

CREATE PROCEDURE dbo.initDrawers @prisonersCount INT
AS BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT * FROM drawers)
        INSERT drawers (drawer, card)
        SELECT n AS drawer, n AS card
        FROM numbers
        WHERE n <= @prisonersCount;
    ELSE
        UPDATE drawers
        SET card = drawer
        FROM drawers;

    EXECUTE shuffle;
END
GO

CREATE PROCEDURE dbo.initRandoms @prisonersCount INT
AS BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT * FROM randoms)
        INSERT randoms (n, random)
        SELECT n AS drawer, n AS random
        FROM numbers
        WHERE n <= @prisonersCount;

    DECLARE @n INT = 1;
    WHILE @n < @prisonersCount BEGIN
        UPDATE randoms
        SET random = ROUND(RAND() * (@prisonersCount - 1), 0) + 1
        WHERE n = @n;

        SET @n = @n + 1;
    END
END
GO

CREATE FUNCTION dbo.computeProbability(@strategy VARCHAR(10))
RETURNS decimal (18, 2)
AS BEGIN
    RETURN (
        SELECT (SUM(CAST(result AS INT)) * 10000 / COUNT(*)) / 100
        FROM results
        WHERE strategy = @strategy
    );
END
GO

CREATE FUNCTION dbo.find(@prisoner INT, @strategy VARCHAR(10))
RETURNS BIT
AS BEGIN
    -- A prisoner can open no more than 50 drawers.
    DECLARE @openMax INT = (SELECT COUNT(*) / 2 FROM drawers);

    -- Prisoners start outside the room.
    DECLARE @card INT = 1;
    DECLARE @open INT = 1;
    WHILE @open < @openMax BEGIN
        -- A prisoner tries to find his own number.
        IF @strategy = 'random'
            SET @card = dbo.randomStrategy(@prisoner, @card);
        ELSE IF @strategy = 'optimal'
            SET @card = dbo.optimalStrategy(@prisoner, @card);
        ELSE
            SET @card = NULL;

        -- A prisoner finding his own number is then held apart from the others.
        IF @card = @prisoner
            BREAK;

        SET @open = @open + 1;
    END

    RETURN (CASE WHEN @card = @prisoner THEN 1 ELSE 0 END);
END
GO

CREATE PROCEDURE dbo.playGame @gamesCount INT, @strategy VARCHAR(10), @prisonersCount INT = 100
AS BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT * FROM results WHERE strategy = @strategy)
        DELETE results WHERE strategy = @strategy;
    
    INSERT results (strategy, game, result)
    SELECT @strategy AS strategy, n AS game, 0 AS result
    FROM numbers
    WHERE n <= @gamesCount;

    DECLARE @game INT = 1;
    WHILE @game <= @gamesCount BEGIN
        -- A room having a cupboard of 100 opaque drawers numbered 1 to 100, that cannot be seen from outside.
        -- Cards numbered 1 to 100 are placed randomly, one to a drawer, and the drawers all closed; at the start.
        EXECUTE initDrawers @prisonersCount;
        EXECUTE initRandoms @prisonersCount;

        -- A prisoner tries to find his own number.
        -- Prisoners start outside the room.
        -- They can decide some strategy before any enter the room.
        DECLARE @matchCount INT;
        WITH findings AS (
            SELECT n AS prisoner, dbo.find(n, @strategy) AS result
            FROM numbers
            WHERE n <= @prisonersCount
        )
        SELECT @matchCount = COUNT(*) FROM findings WHERE result = 1;

        -- If all 100 findings find their own numbers then they will all be pardoned. If any don't then all sentences stand.
        UPDATE results
        SET result = CASE WHEN @matchCount = @prisonersCount THEN 1 ELSE 0 END
        WHERE strategy = @strategy AND game = @game;
    
        SET @game = @game + 1;
    END
END
GO

-- Simulate several thousand instances of the game:
DECLARE @gamesCount INT = 2;

-- ...where the prisoners randomly open drawers.
EXECUTE playGame @gamesCount, 'random';

-- ...where the prisoners use the optimal strategy mentioned in the Wikipedia article.
EXECUTE playGame @gamesCount, 'optimal';

-- Show and compare the computed probabilities of success for the two strategies.
DECLARE @log VARCHAR(max);
SET @log = CONCAT('Games count: ', @gamesCount);
RAISERROR (@log, 0, 1) WITH NOWAIT;
SET @log = CONCAT('Probability of success with "random" strategy: ', dbo.computeProbability('random'));
RAISERROR (@log, 0, 1) WITH NOWAIT;
SET @log = CONCAT('Probability of success with "optimal" strategy: ', dbo.computeProbability('optimal'));
RAISERROR (@log, 0, 1) WITH NOWAIT;
GO

DROP PROCEDURE dbo.playGame;
DROP FUNCTION dbo.find;
DROP FUNCTION dbo.computeProbability;
DROP PROCEDURE dbo.initRandoms;
DROP PROCEDURE dbo.initDrawers;
DROP PROCEDURE dbo.shuffle;
DROP FUNCTION dbo.optimalStrategy;
DROP FUNCTION dbo.randomStrategy;
DROP TABLE dbo.results;
DROP TABLE dbo.drawers;
DROP TABLE dbo.randoms;
DROP TABLE dbo.numbers;
GO