/*******************************************************************************

Creating User-Defined Functions and Formats - a collection of snippets

from Summary of Lesson 7: Creating User-Defined Functions and Formats
ECPG393R - SAS Programming 3 - Advanced Techniques and Efficiencies

- list the reasons to use PROC FCMP
- create functions using PROC FCMP, and then use the functions in a program
- use functions to create formats
- use formats to create functions
- use formats to group data
*******************************************************************************/


/*******************************************************************************1. Creating User-Defined Functions
*******************************************************************************
/*
You can write your own functions using DATA step syntax.

The SAS Function Compiler procedure, or FCMP procedure, enables you to create, test, and store SAS functions, CALL routines, and subroutines. Later, you can more easily read, write, and maintain complex code with your library of independent and reusable functions and subroutines.

PROC FCMP uses DATA step syntax to build user-defined functions and subroutines
that are stored in a package within a SAS data set.
  PROC FCMP OUTLIB=libref.data-set.package;
          FUNCTION function-name(argument-1 <$>, ...,
                      argument-n <$>) <$> <length>;
                programming-statements;
                RETURN(expression);
          ENDSUB;
   QUIT;

User-defined PROC FCMP functions and subroutines are available with the WHERE statement, the DATA step, the Output Delivery System, and with many procedures.

Code Challenge:
Complete the FUNCTION statement below to create a function named tomorrow with the numeric input argument today.
  proc fcmp outlib=orion.functions.dates;
     function ....................... ;
        return(today+1);
     endsub;
  quit;

The correct answer is:
  proc fcmp outlib=orion.functions.dates;
     function tomorrow(today);
        return(today +1);
     endsub;
  quit;
You specify the name of the function, followed by the name of the argument in parentheses.


To use the function in a DATA step or supported PROC step, you use the CMPLIB= SAS system option to specify one or more SAS data sets that store user-defined functions and subroutines.
This option tells SAS where to look for previously compiled functions and subroutines.
  OPTIONS CMPLIB=libref.table | (libref.table-1...libref.table-n);

*/

/*******************************************************************************
2. Using Advanced Format Techniques
*******************************************************************************
/*
You can use functions to define your own formats. For example, after you define the necessary functions using PROC FCMP, you use PROC FORMAT to define the necessary formats, referencing the functions.

Here are the steps to create and use a function to format values:
1. Use PROC FCMP to create the function.
2. Use the OPTIONS statement and CMPLIB= to specify the location of the function.
3. Use PROC FORMAT to create a new format from the function.
You use square brackets to place the function name in the LABEL position.
  VALUE <$> format name other=[function name()];

4. Use the new format in your SAS program.

You can also use formats to define functions. After you create a format, you can use the format in a PROC FCMP step to create a function from it.


To group observations by formatted values, you can use the GROUPFORMAT option in the BY statement in combination with the FORMAT statement. This option tells SAS to use the formatted values instead of the stored values of the BY variables to determine where BY groups begin and end, and therefore, how FIRST.variable and LAST.variable are assigned. In other words, this option creates the groupings.
The GROUPFORMAT option for the BY statement is available only in the DATA step, and you must sort the observations in a data set based on the value of the BY variables before using the GROUPFORMAT option.
  BY GROUPFORMAT variable-name;

You can use an INVALUE statement in a PROC FORMAT step to create an informat for reading and converting raw data values.
  PROC FORMAT LIBRARY=libref.CATALOG;
          INVALUE name 'value1'=informatted-value-1
                                  'value2'=informatted-value-2
                                  'valuen'=informatted-value-n;
  RUN;
*/

/*******************************************************************************
  Sample Programs
*******************************************************************************/
/* 1. Creating and Using a User-Defined Function */

/* Which functions can be used to extract first name and last name values and combine them as shown below. Select all that apply.*/

The EmployeeName value in the table on the left is Abbott, Ray.
An arrow points from the table on the left to the table on the right, which shows the EmployeeName value Ray Abbott.

	 a.  SUBSTR
	 b.  LEFT
	 c.  CATX
	 d.  SCAN
	 e.  TRIM
You can use the LEFT, CATX, SCAN, and TRIM functions to extract first name and last name values and combine them. Here are some examples:
  trim(left(scan(EmployeeName,-1, ',')))||' '||left(scan(EmployeeName,1,','))
  compbl(scan(EmployeeName,2,',')||scan(EmployeeName,1,','))
  catx(' ',scan(EmployeeName,2,','),scan(EmployeeName,1,','))


/* Create the REVERSENAME function */
proc fcmp outlib=orion.functions.dev;
   function ReverseName(name $) $ 40;
   return(catx(' ',scan(name,2,','),scan(name,1,',')));
   endsub;
quit;


/* Use the REVERSENAME function */
options cmplib=orion.functions;

data work.emplist;
   set orion.employeeaddresses;
   FMLName=reversename(EmployeeName);
   keep EmployeeID EmployeeName FMLName;
run;

title 'Reverse Names Function in a Data Step';
proc print data=work.emplist (obs=10);
run;
title;

/* 2. Creating and Using a Function with Conditional Logic */
/* Create the MKT function */

proc fcmp outlib=orion.functions.Marketing;
   function MKT(ID, Date, Type) $ 40;
      if '01Jan2014'd - Date>90 then do;
         if Type=1 then return(catx(' - ',
            put(ID, z12.), 'Mail In-Store Coupon'));
         else if Type=2 then return(catx(' - ',
            put(ID, z12.), 'Send New Catalog'));
	       else return(catx(' - ',
            put(ID, z12.),'Send Email'));
      end;
      else return(catx(' - ', put(ID, z12.),
        'Wait to Contact'));
   endsub;
quit;

/* Use the MKT function */
options cmplib=orion.functions;

data ordercomments;
   set orion.orderfact;
   MarketingComment=MKT(CustomerID,DeliveryDate,OrderType);
run;

proc print data=ordercomments(obs=5) noobs;
   title 'Partial ordercomments Data Set';
   var CustomerID DeliveryDate OrderType MarketingComment;
run;
title;


/*3. Using Functions to Define Formats*/
/* Create the REVERSENAME function */
proc fcmp outlib=orion.functions.dev;
   function ReverseName(name $) $ 40;
   return(catx(' ',scan(name,2,','),scan(name,1,',')));
   endsub;
quit;

options cmplib=orion.functions;

/* use PROC FORMAT to create the new format from the function */
proc format fmtlib;
   value $FmtRevName (default=40)
                     ' '='Missing Name'
                     Other=[ReverseName()];
run;

/*use the $FMTREVNAME format in a report.*/
title1 'Reverse Name Function';
title2 'Applied using Format Statement';
proc print data=orion.employeeaddresses(obs=5) noobs;
   var EmployeeID EmployeeName City State
       PostalCode Country;
   format EmployeeName $FmtRevName.;
run;
title;


/* 4. Using Formats to Define Functions */
proc format;
   value $postabb  '1000'-'1999',
                   '2000'-'2599',
                   '2619'-'2898',
                   '2921'-'2999'='NSW'
                   '0200'-'0299',
                   '2600'-'2618',
                   '2900'-'2920'='ACT'
                   '3000'-'3999',
                   '8000'-'8999'='VIC'
                   '4000'-'4999',
                   '9000'-'9999'='QLD'
                   '5000'-'5799',
                   '5800'-'5999'='SA'
                   '6000'-'6797',
                   '6800'-'6999'='WA'
                   '7000'-'7799',
                   '7800'-'7999'='TAS'
                   '0800'-'0899',
                   '0900'-'0999'='NT';
run;

proc fcmp outlib=orion.functions.char;
   function StateProv(Country $,Code $) $ 4;
      if upcase(country) ='AU' then stpr=put(code,$postabb.);
      else if upcase(country)='US' then stpr=zipstate(code);
      else stpr=' ';
      return(stpr);
   endsub;
quit;

options cmplib=orion.functions;

data addresses;
   keep EmployeeID EmployeeName country PostalCode PC;
   set orion.employeeaddresses;
   PC=StateProv(country,PostalCode);
run;

proc print data=addresses(obs=10);
   var EmployeeID EmployeeName country PostalCode PC;
   title 'Employee Postal and State or Province Codes';
run;
title;


/* 5. Grouping Data in the DATA Step */
proc format;
   value salgrp   low-<30000='Under $30,000'
                30000-<35000='$30,000 to $35,000'
                35000-<50000='$35,000 to $50,000'
                  50000-high='Over $50,000';
run;

proc sort data=orion.employeepayroll
          out=sorted;
   by Salary;
run;

data highlowsal;
   set sorted;
   by groupformat Salary;
   format Salary salgrp.;
   SalGroup=put(Salary,salgrp.);
   if first.Salary or last.Salary;
run;

title 'Lowest and Highest Salary by Salary Group';
proc print data=highlowsal label;
   id SalGroup;
   by SalGroup notsorted;
   var Salary EmployeeID;
   format salary dollar9.;
   label SalGroup='Salary Group';
run;
title;


/* 6. Using Informats to Clean Data */
proc format;
   invalue $Gender (upcase) 'M'='Male'
                            'F'='Female';
   invalue quant 1-high=_same_
                 other=_error_;
   invalue $eval 'Excellent'=4
                 'Good'=3
                 'Fair'=2
                 'Poor'=1;

run;

data newcustomers;
   infile "&path/newcustomers.csv" dlm=',' dsd firstobs=2;
   input CustomerID : 2. CustomerGender : $Gender. CustomerName : $30.
         Quantity : quant. TotalRetailPrice Rating : $eval.;
   if _n_ > 6 then _ERROR_=0;
run;

proc print data=newcustomers(obs=5) noobs;
   title 'Using the INVALUE Statement';
run;
title;
