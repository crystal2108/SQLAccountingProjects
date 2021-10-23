# Automating Reconciliations
SQL is a great way to automate your reconciliations and relieve your Finance team of tedious, manual tasks. If you've ever tried to reconcile a subledger to the general ledger,
you know how time consuming it can be! The worst part is trying to identify what's off within sometimes tens of thousands of lines.  SQL can be a tremendous help in accomplishing 
this task.  I've put together a project below to show you how you can do this at your company to save yourself some time and effort.  Although, the table names and layouts will
differ by database, most of the concepts outlined below should be transferrable!  Also, note that the syntax may differ slightly depending on the database management system (DBMS)
you're using.  So, let's get started!

To give you some background, I'll be walking through the process of reconciling the accounts receivable subledger (incoming payments) to the general ledger (summarized version of
your financial data).  A subledger is where you would store detailed transactional information such as an invoice number, customer data, product data, and pricing.  Depending on
the company, transactions posted in the subledger will be summarized at different levels (daily totals, weekly totals, aggregation by product, invoice, day, and so on).  For the
purposes of this project, we'll make the following assumptions:

1) No customer or product information is posted to the general ledger.
2) Document numbers are 1-to-1 (every document created in the subledger will have the same document number in the general ledger)
3) Documents will be aggregated by document number and posted to the general ledger (meaning that one document number will be associated with one line item on the G/L.  Although,
   all subledger transactions will have at least two associated G/L accounts, we'll be focusing on the balance sheet account (A/R).
4) I'll be using the syntax associated with Microsoft SQL Server (which will differ slightly from PostgreSQL, mySQL, Oracle, etc).

Part One: Declaring Variables

You can use SQL to identify variables similar to Python or another programming language. Declaring variables is a great way to save yourself some time, so you don't have to update
information in multiple areas of your code later on!  In this query, we'll be declaring variables to set our date range.  Since this will be updated monthly for our monthly
reconciliation, we want to define this ONE TIME at the start of our code, then create references to those variables later on.

Part Two (a): Query General Ledger (G/L) transactions not in Subledger.

Part Two (b): Assign an amount.

Part Three (a): Query Subledger transactions not in G/L.

Check out my code here:
[AutomatingReconciliations.txt](https://github.com/crystal2108/AccountingProjects/files/7402171/AutomatingReconciliations.txt)
