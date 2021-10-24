# Automating Reconciliations
SQL is a great way to automate your reconciliations and relieve your Finance team of tedious, manual tasks. If you've ever tried to reconcile a subledger to the general ledger,
you know how time consuming it can be! The worst part is trying to identify what's off within sometimes tens of thousands of lines.  SQL can be a tremendous help in accomplishing this task.  I've put together a project below to show you how you can do this at your company to save yourself some time and effort.  Although, the table names and layouts will differ by database (NOTE: all table names have been changed to maintain confidentiality), most of the concepts outlined below will be transferrable!  Also, note that the syntax may differ slightly depending on the database management system (DBMS) you're using.  So, let's get started!

To give you some background, I'll be walking through the process of reconciling the accounts receivable subledger (incoming payments) to the general ledger (summarized version of your financial data).  A subledger is where you would store detailed transactional information such as invoice number, customer data, product data, and pricing.  Depending on the company, transactions posted in the subledger will be summarized at different levels (daily totals, weekly totals, aggregation by product, invoice, day, and so on).  For the purposes of this project, we'll make the following assumptions:

1) No customer or product information is posted to the general ledger.
2) Document numbers are 1-to-1 (every document created in the subledger will have the same document number in the general ledger)
3) Documents will be aggregated by document number and posted to the general ledger (meaning that one document number will be associated with one line item on the G/L.  Although, all subledger transactions will have at least two associated G/L accounts, we'll be focusing on the balance sheet account (A/R).
4) I'll be using Microsoft SQL Server syntax (which will differ slightly from PostgreSQL, mySQL, Oracle, etc).

Part One: Declaring Variables

You can use SQL to identify variables, similar to Python or another programming language. Declaring variables is a great way to save yourself some time, so you don't have to update information in multiple areas of your code later on!  In this query, we'll be declaring variables at the start of our code to outline the date range for our reconciliation.  We will refer back to this variable throughout our code (every time we use a filter in the WHERE clause to narrow the date range).  Defining the variable(s) at the start of our code will allow us to update the date(s) ONE TIME for each reconciliation.

To create a variable, use the DECLARE statement in Microsoft SQL Server.  Simply type DECLARE, name your variable (@ + name), and define the data type (INT, AS DATE, VARCHAR, and so on).  Since we'll be working with dates in this query, I'll define my variables with AS DATE.  Once you have defined your variable, you'll need to assign a value.  You can do this by using SET.  So, for example, if we want to SET the start date (@startDate) equal to 09/01/21; we'll type SET, name of variable (@startDate) = '09/01/21'.  The end result will look like this:

DECLARE @startDate AS DATE

DECLARE @endDate AS DATE

SET @startDate = '09/01/21'

SET @endDate = '09/30/21'

Part Two (a): Query General Ledger (G/L) transactions not in Subledger.

Once we have defined our variables, we'll need to start on the first section of our code!  We'll be working with two sets of data: one data set associated with the general ledger; and a second data set associated with the subledger. The first step of this process will be pulling a list of transactions that exist in the subledger, not the general ledger.  Transactions that exist in the general ledger, not the subledger, are usually caused by users posting journal entries to the account.  Adjustments to a general ledger account associated with a subledger should flow through a separate asset or liability account.  This will maintain a clean reconciliation process and allow users to more easily track manual journal entries (in a separate account).

To identify this initial list of transactions, we'll use the EXCEPT SELECT statement to compare all transaction ID's posted in the general ledger to associated transaction ID's in the subledger.  EXCEPT SELECT will return all unique values (that don't have a match). Note that EXCEPT SELECT works similarly to a UNION statement in that ALL column names in both data sets MUST match.

For this part of the process, I want to look at transaction IDs and entry numbers within each table (general ledger + subledger).  So, I'll SELECT these two columns FROM each table:

SELECT

[Transaction No]

[Entry No]

FROM [Subledger Entry]

WHERE...

EXCEPT SELECT

[Transaction No]

[Entry No]

FROM [G_L Entry]

WHERE...

I'll alias this new table as 'Per_GL_Not_Subledger' and refer to it in my outer query. The next step is to assign an amount! 

Part Two (b): Assign an amount.

Since the subledger, in this example, is split into two parts (Subledger Entry: summarized w/o amount that links to general ledger table; Subledger Detail: product detail, quantity, amount linking to the Subledger Entry table) we are not able to include 'Amount' in our EXCEPT SELECT statement.  So, _after_ we match the transaction IDs, we'll need to pull in the amount for each transaction.  We're looking at entries recorded in our general ledger, not the subledger, so we'll pull the amount from the GL table using an INNER JOIN.  This will pull amounts ONLY for the transactions we've identified in our Per_GL_Not_Subledger table.

Part Three (a): Query Subledger transactions not in G/L.

Now, we'll want to look at the other side of the equation!  We'll be pulling all subledger transactions that DO NOT exist in the general ledger.  Transactions that exist in the subledger, not the general ledger, are usually caused by unposted transactions.  Daily transactions posted in the subledger will always need to be 'pushed' to the general ledger either by _manually_ posting the transactions OR by setting up a job to _automatically_ transfer these transactions to the general ledger.  Sometimes transactions will fail to post to the general ledger, so users will need to research and correct.

Similar to the last step, we'll use an EXCEPT SELECT statement to identify a unique list of transactions existing in the subledger not the general ledger.

SELECT

[Transaction No]

[Subledger Entry No] AS 'Entry No'

FROM [Detailed Subledger Entry]

WHERE...

EXCEPT SELECT

[Transaction No]

[Entry No]

FROM [Subledger Entry]

WHERE...

I'll alias this new table as 'Per_Subledger_Not_GL' and refer to it in my outer query. The next step is to assign an amount!  

Part Three (b): Assign an amount.

Since the subledger, in this example, is split into two parts (Subledger Entry: summarized w/o amount that links to general ledger table; Subledger Detail: product detail, quantity, amount linking to the Subledger Entry table) we are not able to include 'Amount' in our EXCEPT SELECT statement.  So, _after_ we match the transaction IDs, we'll need to pull in the amount for each transaction.  We're looking at entries recorded in our subledger, not the general ledger, so we'll pull the amount from the detailed subledger entry table using an INNER JOIN.  This will pull amounts ONLY for the transactions we've identified in our Per_Subledger_Not_GL table.

Part Four: Outer Queries

The fourth and FINAL STEP is to SELECT the columns we want to include in our query!  Since we'll be looking for transactions that exist in one set of data, not the other, we'll want to first pull in our transaction ID and entry number.  It will also be good to know when the transaction was posted, the document number and type of document it is for research purposes, as well as the amount so we can assess the materiality of the difference.  

We'll use a UNION statement to pull both queries together (transactions in the general ledger, not subledger AND transactions in the subledger, not general ledger).  Note that with a UNION statement, both sets of columns need to be the same!  If you have a column in one set of data that doesn't exist in the other, your final query WON'T WORK!  One way to get around this is to create a column with a set value OR alias your column headers so the columns in both sets have the same name.

For example, say we want to pull in the general ledger account from the chart of accounts.  This is a field that ONLY exists in the general ledger table.  So, to make our UNION statement work, we'll need to create a column header for our 'Per_Subledger_Not_GL' query.  For the 'Per_GL_Not_Subleger' side, we'll reference column [G_L Account No]; so the 'Per_Subledger_Not_GL' query will need to reference the same column header.  We'll do this by typing [G_L Account No] and using '=' to assign a value. The result looks like this:

SELECT

[G_L Account No] = 'Review'

Click here to see the full query! [AutomatingReconciliations.txt](https://github.com/crystal2108/AccountingProjects/files/7406165/AutomatingReconciliations.txt)

