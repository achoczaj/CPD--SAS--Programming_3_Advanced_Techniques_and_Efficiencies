/*******************************************************************************

Combining Data Horizontally for Table Lookups - a collection of snippets

from Summary of Lesson 6: Combining Data Horizontally for Table Lookups
ECPG393R - SAS Programming 3 - Advanced Techniques and Efficiencies

- use the DATA step with a MERGE statement to combine two or more SAS data sets
- use PROC SQL to join SAS data sets
- describe the differences between the DATA step MERGE statement and the PROC SQL inner join
- use the SET statement with the KEY= option to combine two or more SAS data sets
- use the automatic variable _IORC_ to determine whether an index search is successful
- create an output SAS data set that contains summary statistics from PROC SUMMARY
- use PROC SQL to combine summary and detail data
- use PROC SQL to calculate the summary statistic and combine it with every observation in the data set
- use the DATA step to calculate the summary statistic and combine it with every observation in the data set
- combine data conditionally using multiple SET statements and using PROC SQL
*******************************************************************************/


/*******************************************************************************
1. Combining Data Horizontally
*******************************************************************************/
/*
When you combine data horizontally, you retrieve data from one or more lookup tables based on the values of key variables in base tables. Lookup tables can be SAS data sets, and you can access them during a DATA step merge or PROC SQL join to combine data sets horizontally, and match rows based on key columns or conditions. You can also perform lookups using multiple SET statements and the KEY= option. The lookup table resides on disk with these techniques.

A DATA step merge is a sequential process, which means that SAS reads every row in every input data set from top to bottom. When you combine data sets using the MERGE statement, SAS includes both the matches and the nonmatches in the results by default. Both the base data set and the lookup data set must be sorted or indexed on the BY variables.

You can use PROC SQL to create a table from the results of an inner join. Just as with a DATA step, in a PROC SQL inner join, you can choose the specific columns from each input data set that you want to include in the new data set . The input data sets don't need to contain a common variable, nor do they need to be sorted or indexed.

Although a DATA step match-merge and a PROC SQL inner join can sometimes produce identical results, these two processes are very different.
*/

/*******************************************************************************
2. Using an Index to Combine Data
*******************************************************************************/
/*
You can use multiple SET statements in a DATA step to combine observations from multiple SAS data sets. SAS combines the observations one-to-one.

By default, processing stops when SAS encounters the end-of-file marker on any data set, even if there is more data in the other data sets. Therefore, by default, the output data set contains the same number of observations as the smallest input data set.

You can perform table lookups using multiple SET statements and the KEY= option.
An index points to observations based on the values of one or more key index variables, which means that you can access a particular observation directly, without reading all of the preceding observations.
This can save I/O and CPU time.

When you specify the index name in the KEY= option, processing changes from sequential to direct access, and SAS reads only the observation that satisfies the lookup.
  DATA data-set-name;
       SET SAS-data-set;
       SET SAS-data-set KEY=index-name</UNIQUE>;
  RUN;

When you use the KEY= option in a SET statement, SAS creates the automatic variable _IORC_, which is an acronym for input/output return code.
The value of _IORC_ is a numeric return code, and you use this value to determine whether the index search is successful.
If the value of _IORC_ is 0, SAS found a matching key value.
A nonzero value indicates that SAS didn't find a match.

If you have duplicate values for the key variable in the base data set or lookup data sets, you can use the UNIQUE suboption for the KEY= option to indicate that SAS should ignore the duplicates.
*/

/*******************************************************************************
3. Combining Summary and Detail Data
*******************************************************************************/
/*
You can combine summary data and detail data to create a summary data set using PROC SQL, the DATA step, and PROC SUMMARY.

PROC SUMMARY generates descriptive statistics by default, and you can route these statistics to a SAS data set.
The data set will contains the sum of the values of the variable you specify.
  PROC SUMMARY <option(s)><statistic-keyword(s)>;
         VAR variable(s);
         OUTPUT <OUT=SAS-data-set>
         <output-statistic-specification(s)>;
  RUN;

Another method of combining summary data and detail data is to use a PROC SQL inner join, because it takes advantage of the default Cartesian product. You can write a single-step solution that doesn't require the PROC SUMMARY step or an intermediate data set.

When you use the DATA step to combine summary data and detail data, you can write a single-step solution using multiple SET statements.

Question
Which of the following statements completes this DATA step to create the new variable TotalExp, which records the total of the values contained in the variable Expenses from sasuser.expenses?
  data exspndat;
     if _N_=1 then
        do until(LastObs);
           set sasuser.expenses(keep=Expenses)
               end=LastObs;
           __________________________________
        end;
     set sasuser.expenses;
     PctRev=Expenses/TotalExp;
  run;

OK -> a.  TotalExp+Expenses;
	 b.  TotalExp=Expenses+LastObs
	 c.  TotalExp/Expenses

You use a SUM statement inside the DO loop to create the accumulator variable named TotalExp.
*/

/*******************************************************************************
5. Combining Data Conditionally
*******************************************************************************/
/*
You can use multiple SET statements in a DATA step to conditionally combine data. Both of the input data sets must be sorted. This is an efficient technique because SAS will read sequentially down through both data sets.

Another option for conditionally combining data sets is to use PROC SQL. The PROC SQL code is much easier to understand than the DATA step code, but depending on the size of data, it might not be as efficient. Also, neither of the input data sets needs to be sorted.

Finally, you can also use a hash iterator object to produce the same results for your task. The DATA step code for the hash object is more complex than a straight sequential read of both data sets, and probably isn't as efficient.
*/

/*******************************************************************************
  Sample Programs
*******************************************************************************/
/* 1. Combining Data Horizontally Using a DATA Step Merge */
proc sort data=orion.employeeaddresses
              (keep=EmployeeID EmployeeName)
          out=addresses_sort;
   by EmployeeID;
run;

data temp1;
   keep EmployeeName EmployeeID ManagerID;
   merge orion.staff(in=S keep=EmployeeID ManagerID)
         addresses_sort(in=A);
   by EmployeeID;
   if S and A; /* Matches only */
run;

proc sort data=temp1;
   by ManagerID;
run;

data names;
   merge temp1(in=T)
         addresses_sort(rename=(EmployeeID=ManagerID
                               EmployeeName=ManagerName) in=A);
   by ManagerID;
   if A and T;
run;

proc print data=names;
   title 'Names Data Set';
run;
title;

/* 2. Combining Data Horizontally Using PROC SQL */
proc sql;
create table namessql as
select e.EmployeeID,
       e.EmployeeName,
       ManagerID,
       m.EmployeeName as ManagerName
   from orion.staff,
        orion.employeeaddresses as e,
        orion.employeeaddresses as m
   where e.EmployeeID=staff.EmployeeID
         and m.EmployeeID=staff.ManagerID
   order by ManagerID,
            EmployeeID;
quit;

proc print data=namessql(obs=10) noobs;
   title 'Employee and Manager Names';
run;

title;

/* 3. Processing Multiple SET Statements */
data catalogcustomers (keep=CustomerID OrderID Quantity TotalRetailPrice
                            CustomerCountry CustomerGender CustomerName
                            CustomerAge);
   set orion.catalog(keep=CustomerID OrderID
                            Quantity TotalRetailPrice);
   set orion.customerdimmore key=CustomerID;
   if _IORC_=0 then output catalogcustomers;
run;

data catalogcustomers (keep=CustomerID OrderID Quantity TotalRetailPrice
                            CustomerCountry CustomerGender CustomerName
                            CustomerAge)
      errors(keep=CustomerID);
   set orion.catalog(keep=CustomerID OrderID
                            Quantity TotalRetailPrice);
   set orion.customerdimmore key=CustomerID;
   if _IORC_=0 then output catalogcustomers;
   else do;
      _ERROR_=0;
      output errors;
   end;
run;

proc print data=catalogcustomers;
run;

proc print data=errors;
run;

/* 4. Using Multiple SET Statements with KEY= Options */
proc sql;
create index CustomerID
   on orion.customerdim(CustomerID);
quit;

data cataloginternet others;
   keep CustomerID OrderID Quantity
        TotalRetailPrice CustomerName
        IntOrderID IntTotPrice IntQuant
        In_Dim In_Int In_Cat;
   label IntTotPrice='Total Retail Price for Internet Orders'
         IntQuant='Quantity of Internet Orders'
         TotalRetailPrice='Total Retail Price for Catalog Orders'
         Quantity='Quantity of Catalog Orders'
         OrderID='Catalog Order ID'
         IntOrderID='Internet Order ID'
         InDim='In CustomerDim data'
         InInt='In Internet data'
         InCat='In Catalog data';
   set orion.catalog(keep=CustomerID OrderID
                          Quantity TotalRetailPrice in=InCat);
   set orion.customerdim(in=InDim) key=CustomerID;
   set orion.internet(in=InInt rename=
                               (OrderID=IntOrderID
                                TotalRetailPrice=IntTotPrice
                                Quantity=IntQuant)) key=CustomerID;
   In_Dim=InDim;
   In_Int=InInt;
   In_Cat=InCat;
   if _IORC_=0 then output cataloginternet;
   else do;
      _ERROR_=0;
      output others;
   end;
run;

proc print data=cataloginternet(obs=5) noobs label;
   title 'Customers Who Ordered from Both Catalog and Internet';
run;

proc print data=others(obs=5) noobs label;
   title 'Customers Who Ordered from the Catalog Only';
   title2 'and the Customers Who Ordered from the Catalog';
   title3 'but Were Not in orion.customerdim';
run;
title;

proc sql;
drop index CustomerID
   from orion.customerdim;
quit;

/* 5. Using PROC SUMMARY to Create the Summary Data Set */
proc summary data=orion.totalsalaries;
   var DeptSal;
   output out=summary sum=GrandTot;
run;

proc print data=work.summary;
run;

/* 6. Using PROC SQL to Combine Summary and Detail Data */
proc summary data=orion.totalsalaries;
   var DeptSal;
   output out=summary sum=GrandTot;
run;

proc sql;
create table percentsql as
select ManagerID,
       DeptSal,
       GrandTot,
       DeptSal/GrandTot as Percent format=percent8.2
   from orion.totalsalaries, summary;
quit;

proc print data=percentsql;
run;

proc sql;
create table percentsql2 as
select ManagerID,
       DeptSal,
       sum(DeptSal) as GrandTot,
       DeptSal / calculated GrandTot
                 as Percent format=percent8.2
   from orion.totalsalaries;
quit;

proc print data=percentsql2;
run;

/* 6. Using a Single DATA Step Solution */
data percent(drop=i);
   if _N_=1 then
      do i=1 to TotObs;
         set orion.totalsalaries(keep=DeptSal)
             nobs=TotObs;
         GrandTot+DeptSal;
      end;
   set orion.totalsalaries;
   Percent=DeptSal/GrandTot;
   format Percent percent8.2;
run;

proc print data=percent(obs=10);
run;

/* 7. Using Multiple SET Statements to Combine Data Conditionally */
data euros;
   set orion.orderfact(where=(OrderDate between
                      '01SEP2011'd and '30SEP2011'd)
                       keep=CustomerID OrderDate
                            ProductID
                            TotalRetailPrice);
   do while (not(SDate le OrderDate le EDate));
      set orion.rates;
   end;
   EuroPrice=TotalRetailPrice*AvgRate;
   format EuroPrice Euro10.2;
run;

proc print data=euros noobs;
  title 'work.euros Data Set';
run;
title;

/* Using PROC SQL to Combine Data Conditionally */
proc sql;
	create table euros  as
		select CustomerID, OrderDate, ProductID,
               TotalRetailPrice, SDate, EDate, AvgRate,
               TotalRetailPrice * AvgRate as EuroPrice format=Euro10.2
          from orion.orderfact, orion.rates
          where OrderDate between SDate and EDate;

     title 'work.EUROS SQL Data Set';
     select * from euros (obs=5);
quit;

/* 8. Using a Hash Iterator Object to Combine Data Conditionally */
data euros;
   length SDate EDate AvgRate 8 ;
   drop rc;
   format SDate EDate OrderDate date9. EuroPrice Euro10.2;
   if _N_=1 then do;
      declare hash H(dataset: 'orion.rates', ordered: 'ascending');
      H.definekey('SDate');
      H.definedata('SDate', 'EDate', 'AvgRate');
      H.definedone();
      call missing(SDate, EDate, AvgRate);
      declare hiter E('H');
   end;
   set orion.orderfact(where=(OrderDate between '01SEP2011'd and
                              '30SEP2011'd)
                       keep=CustomerID OrderDate ProductID
                            TotalRetailPrice);
   E.first();
   do until (rc ne 0);
      if SDate <= OrderDate <= EDate then do;
         EuroPrice=TotalRetailPrice * AvgRate;
         output;
         leave;
      end;
      else if SDate > OrderDate then leave;
      rc=E.next();
   end;
run;

proc print data=euros(obs=10) label noobs;
   title 'euros Hash Data Set';
   var CustomerID OrderDate ProductID TotalRetailPrice SDate EDate AvgRate EuroPrice;
run;

title;
