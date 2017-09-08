/*******************************************************************************

Controlling I/O Processing and Memory - a collection of snippets

from Summary of Lesson 2: Controlling I/O Processing and Memory
ECPG393R - SAS Programming 3 - Advanced Techniques and Efficiencies


*******************************************************************************/


/*******************************************************************************
1. Understanding I/O
*******************************************************************************/
/*
Before you can choose techniques for reducing I/O, you first need to understand where I/O occurs when SAS processes data. In DATA step processing for input raw data, your raw data is stored in an external file. By default, SAS reads and writes data through the operating environment file cache, not by direct I/O. File caching is beneficial if you use the same data more than once, but file caching adds overhead to sequential I/O. If all the data can fit in the file cache, subsequent steps using the same data don’t have to move the data from disk to memory. This reduces both I/O and CPU time considerably, because the data is already in memory.

Wherever the raw data is, SAS copies a block of records to a buffer in memory. This is where the input part of I/O is measured. SAS moves one file block of raw data at a time into memory. SAS reads a single record into the input buffer. Next, SAS loads one record at a time from the input buffer into the PDV, and converts the data from external format to SAS format. After processing the current observation in the PDV, SAS writes it to an output buffer. When the output buffer is full, SAS writes out its contents. This is where the output part of I/O is measured.

In DATA step processing for input SAS data, SAS reads data from the physical disk, or from the file cache, into buffers in memory. This is where the input part of I/O is measured. A key concept here is the SAS data set page. A data set page is the unit of data transfer between the storage device or file cache and SAS buffers in memory. When SAS creates a data set, it sets the page size permanently, either to the default value or to a value that you specify.

SAS reads data sequentially from the page buffer, one observation at a time, directly into the PDV. There's no need to convert numeric data, so the process is much faster. After processing the current observation in the PDV, SAS writes it to an output buffer. When the buffer is full, SAS writes its contents to the output SAS data set. I/O is measured between the SAS buffer and either the file system caches or the physical disk. Processing continues until SAS reaches the end-of-file marker for the input data set.

Controlling I/OReal time correlates highly with I/O. To improve program performance and conserve resources, especially when working with large files, you can:

Reduce the amount of data that is processed.
Reduce the length of numeric variables.
Compress data files.
Use SAS views.
Reducing the Amount of Data That Is ProcessedTo reduce I/O by reducing the amount of data that SAS processes, you can use one of the following techniques.

Minimize the number of variables and observations that SAS processes. The amount of I/O you save depends on the size of the subset your SAS program processes.

For reducing the number of variables:
DROP or KEEP statements

DROP= or KEEP= data set options

For reducing the number of observations:
WHERE statement

WHERE= data set option

OBS= and FIRSTOBS= data set options

Reduce the number of times data is processed. For example, rather than use a DATA step to subset data for a single report, you can use a PROC step to read a data set, subset it, and create the report in one step. By avoiding the extra DATA step for subsetting, you save I/O.

Use the SASFILE global statement to process a small SAS data set repeatedly. If a program reads the same data set multiple times, you can use the SASFILE statement to reduce I/O. The first SASFILE statement allocates buffers and loads the SAS data set into memory in its entirety, one page at a time. You specify the keyword SASFILE, the data set to load into memory, and the LOAD argument. If you specify the OPEN argument instead, SAS opens the data set and allocates the buffers, but defers reading the data into memory until a procedure, statement or application is executed. Once the data is read into memory, SAS uses the in-memory version whenever the data set is requested for processing.

SASFILE SAS-data-set LOAD;

To close the data set and free the SAS buffers, you submit a second SASFILE statement with the CLOSE argument.

SASFILE SAS-data-set CLOSE;

Use the SAS options BUFSIZE= and BUFNO= to increase the size and number of buffers. I/O is measured between the SAS buffers and either the file system caches or the physical disk. Increasing buffer size can decrease I/O because more data can be processed for each I/O operation. As a data set option, BUFSIZE= controls the output buffer size for a specific data set.

SAS-data-set (BUFSIZE=n | nK | nM | nG | nT | hexX | MAX)

As a system option, BUFSIZE= controls the output buffer size for all data sets.

OPTIONS BUFSIZE=n | nK | nM | nG | nT | hexX | MAX;

You can use the BUFNO= system option or data set option to specify the number of buffers to be allocated for processing SAS data sets. The number of buffers is not a permanent attribute of the data set and is valid only for the current SAS session. As a data set option, BUFNO= controls the number of buffers that are available for specific data sets.

SAS-data-set (BUFNO=n | nK | hexX | MIN | MAX)

As a system option, BUFNO= controls the number of buffers that are available for all data sets.

OPTIONS BUFNO=n | nK | hexX | MIN | MAX;

Reducing the Length of Numeric Variables
Another way to reduce I/O is to reduce the size of a data set. One way to reduce the size of a data set is by reducing the length of numeric variables (integers only). Using a LENGTH statement, you can reduce the length of a numeric variable when you create a data set. To decrease the length of all numeric variables, you can use the DEFAULT= option in the LENGTH statement.
LENGTH variable(s) <$> length;

Reducing the length of numeric variables is appropriate only for integers. Changing the length of non-integer numeric variables is not recommended.

To avoid problems in reducing the length of numeric variables, you should carefully determine the correct number of bytes for the largest current or future variable value by following the recommendations for your platform.
Compressing Data Files
Another way to improve program performance and reduce I/O is by compressing SAS data files. Compressed SAS data files usually require less data storage space. On the other hand, it takes more CPU time to prepare a compressed observation for I/O. Overall, though, compressed SAS data files require fewer I/O operations. If you can compress large SAS data sets, your savings in I/O and elapsed time greatly outweigh the increase in CPU time.

To create compressed SAS data files, you can choose between two standard compression algorithms: the RLE (Run-Length Encoding) algorithm and the RDC (Ross Data Compression) algorithm. The optimal algorithm depends on the characteristics of your data. You can specify the COMPRESS= option as a data set option or as a system option. You can use the COMPRESS= option with the REUSE= data set option or system option, and with and the POINTOBS= data set option. REUSE=YES and POINTOBS=YES are mutually exclusive; that is, they cannot be used together. If you specify both, REUSE=YES takes precedence.

SAS-data-set (COMPRESS=NO | YES | CHAR | BINARY)

OPTIONS COMPRESS=NO | YES | CHAR | BINARY;

SAS-data-set (REUSE=NO | YES)

OPTIONS REUSE=NO | YES;

SAS-data-set (POINTOBS=YES | NO)

If you use RLE to compress the data using COMPRESS=CHAR, it reduces consecutive repeating blanks, binary zeros, and repeating characters to a single byte. If you use RDC to compress the data using COMPRESS=BINARY, it uses both Run-Length Encoding, which handles the repeated values, and sliding-window compression, which handles the patterns of values.

Before you decide to compress a SAS data file, you need to be aware of some dependencies and trade-offs.

Some data sets don’t compress well or at all. Because each observation has higher overhead when compressed, a data file can occupy more space in compressed form than in uncompressed form. Conversely, SAS data files generally do compress well if they have many missing values or many observations with few bytes in long character variables.

Typically, you should compress data sets only when compression savings are greater than compression overhead. When you use the COMPRESS= option, if the maximum size of the observation is less than the overhead introduced by compression, SAS does not compress the file. Instead, SAS disables compression and creates an uncompressed data set.
Using SAS ViewsYou can also use SAS views to reduce I/O and improve program performance. There are two types of SAS data sets: SAS data files and SAS views. A SAS view is a type of virtual SAS data set that is named and stored for later use. A view contains no data; it merely describes or defines data that is stored elsewhere. Instead of storing the actual data values, a SAS view stores the code that can retrieve the data from one or more other files. The stored code can be a DATA step, a PROC SQL query, or a PROC ACCESS step.
To create a view using the DATA step, you specify a forward slash and the VIEW= option in the DATA statement. The VIEW= option tells SAS to create the output data set as a view. The view-name in the VIEW= option must match an output data set name specified earlier in the DATA statement. Although one DATA step can create multiple data sets, only one of the output data sets can be a view. Also, if a view and a data file are in the same SAS library, they must have distinct names.

A view can contain any DATA step statement. For example, this syntax shows that you can read data using the INFILE and INPUT statements, the SET statement, or the MERGE statement.

DATA SAS-date-set(s) / VIEW=view-name;
      <INFILE fileref;>
      <INPUT variable(s);>
      <SET or MERGE statement(s);>
RUN;

To retrieve program source code from a DATA step view, you use the DESCRIBE statement. You specify view=view-name directly after the DATA keyword; you do not specify the name of the data set.

DATA VIEW=view-name;
      DESCRIBE;
RUN;

Views can help you avoid creating intermediate copies of data. By using views, you can avoid the I/O and data storage space required to write and read temporary data sets. You also reduce the real time required to complete a job by eliminating one or more I/O-bound segments. However, using views doesn't reduce the CPU time required to complete the task.

You can also use PROC SQL to create a SAS view. Like a DATA step view, a PROC SQL view stores the code that retrieves data from one or more other files. Specifically, a PROC SQL view stores an SQL query. The advantage of using the DATA step is that you can create a view from raw data files. PROC SQL requires that you read SAS data sets or relational database tables. You can use the CREATE VIEW statement to create PROC SQL views.

CREATE VIEW PROC-SQL-view AS query-expression;

You can embed a LIBNAME statement in a PROC SQL view by specifying the USING clause. The USING clause enables you to store SAS libref information in the view.

USING LIBNAME-clause;

By following some guidelines for creating and using views, you can help ensure that you're using the most efficient approach. Use the guidelines in the following table when you choose between a view and a data file:

Task	Technique
Use the same data many times in one program	SAS data file
Read files with structures that often change	SAS data file
Process time-sensitive data	SAS data view
Have limited storage space	SAS data view

Use the guidelines in the following table when you choose between DATA step views and PROC SQL views:

Task	Technique
Perform complex conditional processing	DATA step view
Update data in place	PROC SQL view
Read data in various file formats	DATA step view
Subset data before processing	PROC SQL view
Assign a libref in the view	PROC SQL view
Use subqueries in WHERE processing	PROC SQL view
Read data from a DBMS	either type of view


Sample Programs

Viewing the Page Size of a SAS Data Set
ods select enginehost;

proc contents data=orion.saleshistory;
run;

Reducing the Length of Numeric Variables
proc sort data=orion.employeephones out=employeephones_sort;
   by EmployeeID;
run;

proc sort data=orion.employeeaddresses out=employeeaddresses_sort;
   by EmployeeID;
run;

data emps;
   merge employeeaddresses_sort
         orion.employeeorganization
         orion.employeepayroll
         employeephones_sort;
   by EmployeeID;
run;

data empsshortlength;
   length StreetID 6 EmployeeID ManagerID
          StreetNumber EmployeeHireDate
          EmployeeTermDate BirthDate 4
          Dependents 3;
   merge employeeaddresses_sort
         orion.employeeorganization
         orion.employeepayroll
         employeephones_sort;
   by EmployeeID;
run;

data empsshortlength2;
   merge employeeaddresses_sort
         orion.employeeorganization
         orion.employeepayroll
         employeephones_sort;
   by EmployeeID;
   length StreetID 6 EmployeeID ManagerID
          StreetNumber EmployeeHireDate
          EmployeeTermDate BirthDate 4
          Dependents 3;
run;

proc compare data=emps compare=empsshortlength2;
run;

Creating and Using a DATA Step View
filename MON ("&path/mon3.dat"
              "&path/mon2.dat"
              "&path/mon1.dat");

data orion.quarter;
   infile MON dlm=',';
   input CustomerID OrderID OrderType
         OrderDate :date9. DeliveryDate :date9.;
   time=time();
   format time timeAMPM.;
run;

proc print data=orion.quarter(obs=5);
   title 'Orion.Quarter';
   format OrderDate DeliveryDate date9.;
run;
title;

filename MON ("&path/mon3.dat"
              "&path/mon2.dat"
              "&path/mon1.dat");

data orion.quarterv / view=orion.quarterv;
   infile MON dlm=',';
   input CustomerID OrderID OrderType
         OrderDate :date9. DeliveryDate :date9.;
   time=time();
   format time timeAMPM.;
run;

proc print data=orion.quarterv(obs=5);
   title 'orion.quarterv';
   format OrderDate DeliveryDate date9.;
run;
title;

proc contents data=orion.quarterv;
run;

data view=orion.quarterv;
   describe;
run;

data orion.annualv / view=orion.annualv;
   infile MON12 dlm=',';
   input CustomerID OrderID OrderType
         OrderDate :date9. DeliveryDate :date9.;
   time=time();
   format time timeAMPM.;
run;

Creating and Using a PROC SQL View
proc sql;
   create view orion.namesview as
   select e.EmployeeID, e.EmployeeName,
          ManagerID,
          m.EmployeeName as ManagerName
       from orion.staff,
            orion.employeeaddresses as e,
	         orion.employeeaddresses as m
       where e.EmployeeID=staff.EmployeeID and
             m.EmployeeID=staff.ManagerID;
quit;

proc sql;
   describe view orion.namesview;
quit;

title "Fred Benyami's Employees";

proc sql;
select EmployeeID,
       EmployeeName
   from orion.namesview
   where ManagerName='Benyami, Fred';
quit;
title;
