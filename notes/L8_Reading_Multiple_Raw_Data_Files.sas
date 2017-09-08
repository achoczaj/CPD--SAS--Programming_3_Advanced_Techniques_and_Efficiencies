/*******************************************************************************

Reading Multiple Raw Data Files - a collection of snippets

from Summary of Lesson 8: Reading Multiple Raw Data Files
ECPG393R - SAS Programming 3 - Advanced Techniques and Efficiencies

- use the FILENAME statement create a SAS data set from multiple raw data files
- use the FILEVAR= option to create a SAS data set from multiple raw data files
*******************************************************************************/


/*******************************************************************************1. Flexible Programming: Combining Raw Data Files Vertically
*******************************************************************************
/*
Programs that run in a production environment should be as flexible as possible, requiring little or no editing before you submit the program. For example, if you need to combine three raw data files vertically in order to generate a report, you can use several methods.

You can concatenate the files using multiple INFILE statements.

You can also use a FILENAME statement that specifies multiple files. The FILENAME statement concatenates the raw data files by referencing more than one file. The files must all have the same layout. You have to edit the FILENAME statement if you want to reference a different raw data file, so using the FILENAME statement doesn't make your programs dynamic.
  FILENAME fielref ('external-file1'
                              'external-file2'
                              'external-filen');

For increased flexibility, you can use the FILEVAR= option in the INFILE statement to provide the name of your raw data files dynamically.
This option specifies a temporary character variable that contains the physical filename of the raw data file to read.
When the FILEVAR= variable changes value, the INFILE statement closes the current input file and opens a new one.
When the next INPUT statement executes, it reads from the new file that the FILEVAR= variable specifies.
  INFILE file-specification FILEVAR=variable);

To increment a date, time, or datetime value by a given interval or intervals, and return a date, time, or datetime value, you can use the INTNX function.
  INTNX(interval, start-from, increment<, alignment>)

For interval, you specify a character constant, variable, or expression that contains a time interval, such as WEEK, MONTH, QTR, or YEAR.

For start-from, you specify a SAS expression that represents a SAS date, time, or datetime value.

For increment, you specify a positive or negative integer that represents the number of intervals.

You can also optionally specify alignment, which controls the position of SAS dates within the interval, such as BEGINNING, MIDDLE, or END. The default alignment is BEGINNING, which works for our program.

Let's see some other examples.

Formatted Value of BeginDate: 04JUL2011

Examples of INTNX Function 		--> Formatted Value of EndDate
INTNX('year', BeginDate, -1) 	--> 01JAN2010
INTNX('year', BeginDate,  0) 	--> 01JAN2011
INTNX('year', BeginDate,  1) 	--> 01JAN2012

INTNX('month', BeginDate, -2) 	--> 01MAY2010
INTNX('month', BeginDate, -1) 	--> 01JUN2010
INTNX('month', BeginDate,  0) 	--> 01JUL2010
INTNX('month', BeginDate,  1) 	--> 01AUG2010
INTNX('month', BeginDate,  2) 	--> 01SEP2010

Here's a partially specified assignment statement that uses the INTNX function
to create the variable EndDate by incrementing the variable BeginDate.
Because we did not specify the optional alignment argument in the assignment statement, the default is to align to the beginning of the interval. 

In the first three examples, the interval is YEAR.
Therefore, EndDate is January 1 of each year.

In the next five examples, the interval is MONTH.
Therefore, EndDate is the first day of each month.

Question:
Which of the following code samples is more efficient?
	 a.
    MonNum=month(Today());
    MidMon=month(intnx('month', Today(), -1));
    LastMon=month(intnx('month', Today(), -2));
	 b.
    Today=today();
    MonNum=month(Today);
    MidMon=month(intnx('month', Today, -1));
    LastMon=month(intnx('month', Today, -2));

The second set of statements is more efficient because it executes the TODAY function one time only, storing the result in the variable TODAY, which is then referenced three times. Answer choice a is less efficient because it executes the TODAY function three times.
*/

/*******************************************************************************  Sample Programs
*******************************************************************************
/* 1. Using the FILENAME Statement to Combine Raw Data Files */
/*Create a rolling quarter report for the month of November.*/
filename MON ("&path/mon11.dat"
              "&path/mon10.dat"
              "&path/mon9.dat");

data quarter;
   infile MON dlm=',';
   input CustomerID OrderID OrderType
         OrderDate : date9. DeliveryDate : date9.;
run;

proc print data=quarter;
   title 'quarter';
run;
title;

/*Create a rolling quarter report for the month of March.*/
filename MON ("&path/mon3.dat"
              "&path/mon2.dat"
              "&path/mon1.dat");

data quarter;
   infile MON dlm=',';
   input CustomerID OrderID OrderType
         OrderDate : date9. DeliveryDate : date9.;
run;

proc print data=quarter;
   title 'quarter';
run;
title;

/* 2. Using the INFILE Statement to Combine Raw Data Files */
data rollingqtr;
   drop m;
   do m=11, 10, 9;
      NextFile=cats("&path/mon",m,".dat");
      infile ORD filevar=NextFile dlm=',';
      input CustomerID
            OrderID
            OrderType
            OrderDate : date9.
            DeliveryDate : date9.;
      output;
   end;
   stop;
run;

proc print data=rollingqtr;
   title 'rollingqtr';
run;
title;

/* 3. Using a Dynamic Program to Combine Raw Data Files */
data rollingqtr;
   drop m;
   MonNum=month(today());
   MidMon=month(intnx('month', today(), -1));
   LastMon=month(intnx('month', today(), -2));
   do m=MonNum, MidMon, LastMon;
      NextFile=cats("&path/mon", m, ".dat");
      infile ORD filevar=NextFile dlm=',' end=LastObs;
      do while (not LastObs);
         input CustomerID OrderID OrderType OrderData :date9. DeliveryData :date9.;
         output;
      end;
   end;
   stop;
run;

proc print data=rollingqtr;
   title 'rollingqtr';
run;
title;
