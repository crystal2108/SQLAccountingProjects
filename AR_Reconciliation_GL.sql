-- Part One: Declaring Variables

DECLARE @startDate AS DATE -- Define Datatype
DECLARE @endDate AS DATE

SET @startDate = '09/01/21' -- Set Value
SET @endDate = '09/30/21'

-- Part Two (a): Query General Ledger (G/L) transactions not in Subledger.

-- Select your columns

SELECT
     Per_GL_Not_Subledger.[Transaction No] -- Foreign key linking Subledger to G/L
    ,Per_GL_Not_Subledger.[Entry No] -- Foreign key linking Subledger to G/L
    ,GL_Detail.[Posting Date]
    ,GL_Detail.[G_L Account No]
    
    ,CASE   WHEN GL_Detail.[Document Type] = '1' THEN 'Payment'
            WHEN GL_Detail.[Document Type] = '2' THEN 'Invoice'
            WHEN GL_Detail.[Document Type] = '3' THEN 'Credit Memo'
            WHEN GL_Detail.[Document Type] = '4' THEN 'Deduction'
            ELSE '' END AS 'Document Type'
    
    ,GL_Detail.[Document No]
    ,[Description] = 'Per G/L not in Subledger' -- Created column
    ,GL_Detail.[Amount] AS 'G/L Amount'
    ,[Subledger Amount] = 0 

/* Since we're looking for transactions that exist in the G/L, but not the Subledger
for this portion of the code, we'll set the value of the A/P Subledger to 0 */

-- Create a subquery to compare the G/L table to the Subledger table with EXCEPT SELECT

FROM (
    SELECT
         [Transaction No] 
        ,[Entry No]
    FROM [G_L Entry]
    WHERE 
        [Posting Date] BETWEEN @startDate AND @endDate -- Reference previously declared variable
    AND [G_L Account No] IN (
             '12010' -- General A/R
            ,'12015' -- Affiliate A/R
            ,'12030' -- Intercompany A/R
    )

    EXCEPT SELECT
         [Transaction No]
        ,[Entry No]
    FROM [Subledger Entry]
    WHERE [Posting Date] BETWEEN @startDate AND @endDate
) Per_GL_Not_Subledger

-- Part Two (b): Assign an amount.

INNER JOIN (
        SELECT*
        FROM [G_L Entry]
        WHERE 
            [Posting Date] BETWEEN @startDate AND @endDate
        AND [G_L Account No] IN (
             '12010' -- General A/R
            ,'12015' -- Affiliate A/R
            ,'12020' -- Intercompany A/R            
        )
) GL_Detail  ON Per_GL_Not_Subledger.[Entry No] = GL_Detail.[Entry No]

-- Part Three: Query Subledger transactions not in G/L.

UNION

SELECT
     Per_Subledger_Not_GL.[Transaction No]
    ,Per_Subledger_Not_GL[Entry No]
    ,Subledger_Detail.[Posting Date]
    ,[G_L Account No] = 'Review' -- Subledger does not have G/L account numbers

    ,CASE   WHEN Subledger_Detail.[Document Type] = '1' THEN 'Payment'
            WHEN Subledger_Detail.[Document Type] = '2' THEN 'Invoice'
            WHEN Subledger_Detail.[Document Type] = '3' THEN 'Credit Memo'
            WHEN Subledger_Detail.[Document Type] = '4' THEN 'Deduction'
            ELSE '' END AS 'Document Type'
    
    ,Subledger_Detail.[Document No]
    ,[Description] = 'Per Subledger not in G/L' -- Created column
    ,[G/L Amount] = 0
    ,Subledger_Detail.[Subledger Amount]

/* Since we're looking for transactions that exist in the Subledger, but not the G/L
for this portion of the code, we'll set the value of the G/L to 0 */

FROM (
    SELECT  
         [Transaction No]
        ,[Subledger Entry No] AS 'Entry No'

    FROM [Detailed Subledger Entry]
    WHERE 
        [Posting Date] BETWEEN @startDate AND @endDate

    EXCEPT SELECT
         [Transaction No]
        ,[Entry No] AS 'Entry No'

    FROM [Subledger Entry]
    WHERE 
        [Posting Date] BETWEEN @startDate AND @endDate
) Per_Subledger_Not_GL

/* Entries posted in the Detailed Customer Ledger Entry table are summarized in the
Subledger Entry table.  So, this EXCEPT SELECT statement is meant to capture any
transactions that were not picked up in the interim table linking the Detailed Customer Ledger
to the G/L. */

INNER JOIN (
    SELECT DISTINCT
         [Subledger Entry No]
        ,[Transaction No]
	,[Posting Date]
	,[Document No]
        ,SUM([Amount]) AS 'Subledger Amount'
    FROM [Detailed Subledger Entry]
    WHERE
        [Posting Date] BETWEEN @startDate AND @endDate
    AND [Entry Type] <> '2'
    GROUP BY
         [Subledger Entry No]
        ,[Transaction No]
	,[Posting Date]
	,[Document No]
) Subledger_Detail  ON Per_Subledger_Not_GL.[Entry No] = Subledger_Detail.[Subledger Entry No]
            AND Per_Subledger_Not_GL.[Transaction No] = Subledger_Detail.[Transaction No]
ORDER BY [G_L Account No], [Transaction No]