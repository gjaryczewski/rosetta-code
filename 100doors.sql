-- Transact-SQL

WITH    OneToTen (N)
AS  (   SELECT  N
        FROM (  VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)
                ) V(N)
        )
    ,   InitDoors (Num, IsOpen)
AS  (   SELECT  1
            +   1 * Units.N
            +   10 * Tens.N AS Num
            ,   CONVERT(Bit, 0) AS IsOpen
        FROM    OneToTen AS Units
        CROSS JOIN  OneToTen AS Tens
        ) -- This part could be easier with a tally table or equivalent table-valued function
    ,   States (NbStep, Num, IsOpen)
AS  (   SELECT  0 AS NbStep
            ,   Num
            ,   IsOpen
        FROM    InitDoors AS InitState
        UNION ALL
        SELECT  1 + NbStep
            ,   Num
            ,   CASE Num % (1 + NbStep)
                    WHEN 0 THEN ~IsOpen
                    ELSE IsOpen
                END
        FROM    States
        WHERE   NbStep < 100
        )
SELECT  Num AS DoorNumber
    ,   Concat( 'Door number ', Num, ' is '
            ,   CASE IsOpen
                    WHEN 1 THEN ' open'
                    ELSE ' closed'
                END ) AS RESULT -- Concat needs SQL Server 2012
FROM    States
WHERE   NbStep = 100
ORDER BY Num
; -- Fortunately, maximum recursion is 100 in SQL Server.
-- For more doors, the MAXRECURSION hint should be used.
-- More doors would also need an InitDoors with more rows.

-- SQL

DECLARE	@sqr INT,
		@i INT,
		@door INT;
 
SELECT @sqr =1,
	@i = 3,
	@door = 1;	
 
WHILE(@door <=100)
BEGIN
	IF(@door = @sqr)
	BEGIN
		PRINT 'Door ' + RTRIM(CAST(@door AS CHAR)) + ' is open.';
		SET @sqr= @sqr+@i;
		SET @i=@i+2;
	END
	ELSE
	BEGIN
		PRINT 'Door ' + RTRIM(CONVERT(CHAR,@door)) + ' is closed.';
	END
SET @door = @door + 1
END

-- PL/SQL

DECLARE
  TYPE doorsarray IS VARRAY(100) OF BOOLEAN;
  doors doorsarray := doorsarray();
BEGIN
 
doors.EXTEND(100);  --ACCOMMODATE 100 DOORS
 
FOR i IN 1 .. doors.COUNT  --MAKE ALL 100 DOORS FALSE TO INITIALISE
  LOOP
     doors(i) := FALSE;                    
  END LOOP;
 
FOR j IN 1 .. 100 --ITERATE THRU USING MOD LOGIC AND FLIP THE DOOR RIGHT OPEN OR CLOSE
 LOOP
      FOR k IN 1 .. 100
        LOOP
                  IF MOD(k,j)=0 THEN 
                     doors(k) := NOT doors(k); 
                  END IF;
        END LOOP;
 END LOOP;
 
FOR l IN 1 .. doors.COUNT  --PRINT THE STATUS IF ALL 100 DOORS AFTER ALL ITERATION
  LOOP
       DBMS_OUTPUT.PUT_LINE('DOOR '||l||' IS -->> '||CASE WHEN SYS.DBMS_SQLTCB_INTERNAL.I_CONVERT_FROM_BOOLEAN(doors(l)) = 'TRUE' 
                                                                THEN 'OPEN' 
                                                              ELSE 'CLOSED' 
                                                        END);
  END LOOP;
 
END;

-- MySQL

DROP PROCEDURE IF EXISTS one_hundred_doors;
 
DELIMITER |
 
CREATE PROCEDURE one_hundred_doors (n INT)
BEGIN
  DROP TEMPORARY TABLE IF EXISTS doors; 
  CREATE TEMPORARY TABLE doors (
    id INTEGER NOT NULL,
    open BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (id)
  );
 
  SET @i = 1;
  create_doors: LOOP
    INSERT INTO doors (id, open) values (@i, FALSE);
    SET @i = @i + 1;
    IF @i > n THEN
      LEAVE create_doors;
    END IF;
  END LOOP create_doors;
 
  SET @i = 1;
  toggle_doors: LOOP
    UPDATE doors SET open = NOT open WHERE MOD(id, @i) = 0;
    SET @i = @i + 1;
    IF @i > n THEN
      LEAVE toggle_doors;
    END IF;
  END LOOP toggle_doors;
 
  SELECT id FROM doors WHERE open;
END|
 
DELIMITER ;
 
CALL one_hundred_doors(100);

-- SQL PL

--#SET TERMINATOR @
 
SET SERVEROUTPUT ON @
 
BEGIN
 DECLARE TYPE DOORS_ARRAY AS BOOLEAN ARRAY [100];
 DECLARE DOORS DOORS_ARRAY;
 DECLARE I SMALLINT;
 DECLARE J SMALLINT;
 DECLARE STATUS CHAR(10);
 DECLARE SIZE SMALLINT DEFAULT 100;
 
 -- Initializes the array, with all spaces (doors) as false (closed).
 SET I = 1;
 WHILE (I <= SIZE) DO
  SET DOORS[I] = FALSE;
  SET I = I + 1;
 END WHILE;
 
 -- Processes the doors.
 SET I = 1;
 WHILE (I <= SIZE) DO
  SET J = 1;
  WHILE (J <= SIZE) DO
   IF (MOD(J, I) = 0) THEN
    IF (DOORS[J] = TRUE) THEN
     SET DOORS[J] = FALSE;
    ELSE
     SET DOORS[J] = TRUE;
    END IF;
   END IF;
   SET J = J + 1;
  END WHILE;
  SET I = I + 1;
 END WHILE;
 
 -- Prints the final status o the doors.
 SET I = 1;
 WHILE (I <= SIZE) DO
  SET STATUS = (CASE WHEN (DOORS[I] = TRUE) THEN 'OPEN' ELSE 'CLOSED' END);
  CALL DBMS_OUTPUT.PUT_LINE('Door ' || I || ' is '|| STATUS);
  SET I = I + 1;
 END WHILE;
END @