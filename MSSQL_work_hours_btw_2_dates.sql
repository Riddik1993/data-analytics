

select [dbo].[WorkingHoursBetween2Dates]('06.18.2021','06.22.2021')

-------------------------------------------------------
create FUNCTION [dbo].[WorkingHoursBetween2Dates]
(
    @dtFrom datetime,
    @dtTo datetime
)
RETURNS INT
BEGIN
    DECLARE @tblDates AS TABLE (DateValue DATE)
    DECLARE @dFrom date = @dtFrom
    DECLARE @dTo date = @dtTo
    DECLARE @intDays int
    DECLARE @intHours int = 0
    DECLARE @dFromWorkday bit = CASE WHEN (DATENAME(WEEKDAY, @dFrom) IN ('Saturday','Sunday')) OR EXISTS (SELECT Holyday FROM dbo.Holidays WHERE Holyday = @dFrom) THEN 0 ELSE 1 END
    DECLARE @dToWorkday bit = CASE WHEN (DATENAME(WEEKDAY, @dTo) IN ('Saturday','Sunday')) OR EXISTS (SELECT Holyday FROM dbo.Holidays WHERE Holyday = @dTo) THEN 0 ELSE 1 END



    IF DATEPART(HOUR,@dtFrom) < 9
        SET @dtFrom = DATEADD(HOUR,9,CAST(CAST(@dtFrom AS DATE) AS DATETIME))
    ELSE
        IF DATEPART(HOUR,@dtFrom) > 17
            SET @dtFrom = DATEADD(HOUR,17,CAST(CAST(@dtFrom AS DATE) AS DATETIME))

    IF DATEPART(HOUR,@dtTo) < 9
        SET @dtTo = DATEADD(HOUR,9,CAST(CAST(@dtTo AS DATE) AS DATETIME))
    ELSE
        IF DATEPART(HOUR,@dtTo) > 17
            SET @dtTo = DATEADD(HOUR,17,CAST(CAST(@dtTo AS DATE) AS DATETIME))



    WHILE @dFrom <= @dTo
    BEGIN
        INSERT INTO @tblDates
        (
            DateValue
        )
            SELECT @dFrom
            WHERE NOT ((DATENAME(WEEKDAY, @dFrom) IN ('Saturday','Sunday')) OR EXISTS (SELECT Holyday FROM dbo.Holidays WHERE Holyday = @dFrom))
        
        SET @dFrom = DATEADD(DAY,1,@dFrom)
    END
    
    SET @intDays = CASE WHEN EXISTS(SELECT * FROM @tblDates) THEN (SELECT COUNT(*) FROM @tblDates) - 1 ELSE 0 END

    IF @intDays = 0
        BEGIN
            IF @dFromWorkday = 1
                IF DATEPART(HOUR,@dtFrom) < 17
                    BEGIN
                        IF DATEDIFF(DAY,@dtFrom,@dtTo)=0
                            SET @intHours = DATEDIFF(HOUR,@dtFrom,@dtTo)
                        ELSE
                            SET @intHours = DATEDIFF(HOUR,@dtFrom,DATEADD(HOUR,17,CAST(CAST(@dtFrom AS DATE) AS DATETIME)))
                    END

            IF @dToWorkday = 1 AND DATEDIFF(DAY,@dtFrom,@dtTo)<>0
                IF DATEPART(HOUR,@dtTo) >= 17
                    SET @intHours = @intHours + 8
                ELSE
                    IF DATEPART(HOUR,@dtTo) > 9
                        SET @intHours = @intHours + DATEPART(HOUR,@dtTo) - 9
        END
    ELSE
        BEGIN
            IF @dFromWorkday = 1
                IF DATEPART(HOUR,@dtFrom) < 17
                    BEGIN
                        SET @intHours = DATEDIFF(HOUR,@dtFrom,DATEADD(HOUR,17,CAST(CAST(@dtFrom AS DATE) AS DATETIME)))
                        SET @intDays = @intDays - 1
                    END

            IF DATEPART(HOUR,@dtTo) < 17
                SET @intHours = @intHours + (@intDays * 8) + CASE WHEN @dToWorkday = 1 THEN DATEDIFF(HOUR,DATEADD(HOUR,9,CAST(CAST(@dtTo AS DATE) AS DATETIME)), @dtTo) ELSE 0 END
            ELSE
                SET @intHours = @intHours + ((@intDays + 1) * 8)
        END

    RETURN (@intHours)
END