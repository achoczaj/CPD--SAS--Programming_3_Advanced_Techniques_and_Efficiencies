/*******************************************************************************

Using DATA Step Hash and Hiter Objects for Table Lookups - a collection of snippets

from Summary of Lesson 5: Using DATA Step Hash and Hiter Objects for Table Lookups
ECPG393R - SAS Programming 3 - Advanced Techniques and Efficiencies

- describe hash objects as a table lookup technique
- use hash object methods to load data into a hash object
- use hash object methods to return data values
- use hash object methods to load a hash object from a SAS data set
- describe hash iterator objects
- use hash iterator object methods to return hash object values
*******************************************************************************/


/*******************************************************************************
1. Using a Hash Object as an In-Memory Lookup Table
*******************************************************************************/
/*
Lookup tables can be hash objects that are accessed with the FIND method. A hash object is an in-memory lookup table that is available only within the DATA step.

A hash object resembles a table with rows and columns with a key component and a data component. Each row represents the data associated with a key, and each column represents either a key or a data component.

Unlike arrays, whose subscript values must be numeric, hash objects can use any combination of numeric and character keys.

You can load a hash object with hardcoded values or from a SAS data set. You can also download from a hash object to a SAS data set. When you load a hash object from a data set, the data set doesn't need to be sorted or indexed.
*/


/*******************************************************************************
2. Using Hash Object Methods to Define a Hash Object
*******************************************************************************/
/*
You follow four steps to define a hash object: declare the hash object, define the key variables, define the data variables, and complete the definition.

You use the DECLARE statement to create and name the hash object.
  DECLARE object object-reference <(argument_tag: value-1 argument_tag-n: value-n )>;

Hash and hiter (hash iterator) objects use object dot notation to execute a method on an object. A method is an operation you want to perform.
  object.method (<argument_tag: value-1 <,... argument_tag-n: value-n>>);

The DEFINEKEY method defines the key variables for the hash object, the DEFINEDATA method defines the data variables for the hash object, and the DEFINEDONE method declares that all key and data definitions are complete.
To load the hash object with key and data values, you use the ADD method, which also uses object dot notation syntax.

You use the FIND method to return the data values based on key values.
The FIND method also returns a numeric code that indicates whether the lookup succeeded or failed. A return code 0 indicates success.
You can use conditional logic to ensure that the FIND method finds a key value in the hash object.
Optionally, you can assign the return code to a variable.
  rc=object.FIND (<KEY: keyvalue-1,..., KEY: keyvalue-n>);

If a program creates variables, but doesn't populate them with values, SAS issues notes in the log stating that the variables are uninitialized.
To avoid producing these notes, you can add the CALL MISSING routine to your program to initialize variables to missing.
  CALL MISSING(varname1<,varname2, ...>);
*/

/*******************************************************************************
3. Loading a Hash Object with Data from a SAS Data Set
*******************************************************************************/
/*
You can load a hash object with data from a SAS data set. In the DECLARE statement, you specify the DATASET argument and the name of the data set to load the values from. The data set appears in the DATASET argument, but not in a SET statement. You could use a LENGTH statement to manually add its variables to the PDV.

Alternatively, you can use a non-executing SET statement to add existing variables to the PDV. This technique is efficient and convenient.

It's efficient because the SET statement doesn't execute. However, it uses slightly more memory because SAS adds additional, unnecessary variables from the data set to the PDV.

It's convenient because you don't need to run PROC CONTENTS or type a LENGTH statement to manually add the variables to the PDV. Also, when you use a non-executing SET statement, you no longer need the CALL MISSING routine. The variables come into the PDV from a SAS data set, so no uninitialized variable note is written to the log.

You can use the OUTPUT method to download data from a hash object to a data set. As with the ADD and FIND methods, the OUTPUT method creates a return code. A return code 0 indicates success.
When specifying the name of the output data set, you can optionally use SAS data set options in the DATASET argument tag.
  rc=object.OUTPUT(DATASET: 'dataset-1 <datasetoption)>'
  <, ...<DATASET: 'dataset-n>'> ('datasetoption <(datasetoption)>');

You can use the MULTIDATA: 'YES' argument tag in the DECLARE statement to allow multiple rows per key value.
You can use the ORDERED argument in the DECLARE statement to return data in either ascending or descending key-value order.
*/


/*******************************************************************************
4. Using the DATA Step Hiter Object
*******************************************************************************/
/*
You can use a hash iterator (hiter) object to retrieve the hash object data in either ascending key order or descending key order.

The hash iterator object is an ordered view of the hash object. Instead of finding a value according to a key, you can use hash iterator object methods to jump to the top or bottom of the hiter object view, as well as move backwards and forwards.
You must declare the hash object before you declare a hash iterator object.

You use the DECLARE method to declare the hash iterator object.
After the keyword, you specify HITER and then the name of the hash iterator object. Next you specify the hash object name in single or double quotation marks. This must be the name of the previously defined hash object.
  DECLARE HITER iterator-name('hash-object-name');

With the hash iterator object, you can select from four methods that return values based on the position of the rows in the hash object.
These four methods, FIRST, LAST, NEXT, and PREV, also use dot notation syntax.
*/


/*******************************************************************************
  Sample Programs
*******************************************************************************/
/* 1. Using a Hash Object as a Lookup Table */
data newcountry;
   if _n_=1 then
      do;
         declare hash ContName();
         ContName.definekey('ContinentID');
         ContName.definedata('ContinentName');
         ContName.definedone();

         ContName.add(key:91, data:'North America');
         ContName.add(key:93, data:'Europe');
         ContName.add(key:94, data:'Africa');
         ContName.add(key:95, data:'Asia');
         ContName.add(key:96, data:'Australia/Pacific');
      end;
   set orion.country(keep=ContinentID Country CountryName);
   rc=ContName.find(key:ContinentID);
run;

/*v_2*/
data newcountry;
   length ContinentName $ 30;
   if _n_=1 then
      do;
         declare hash ContName();
         ContName.definekey('ContinentID');
         ContName.definedata('ContinentName');
         ContName.definedone();

         ContName.add(key:91, data:'North America');
         ContName.add(key:93, data:'Europe');
         ContName.add(key:94, data:'Africa');
         ContName.add(key:95, data:'Asia');
         ContName.add(key:96, data:'Australia/Pacific');
      end;
   set orion.country(keep=ContinentID Country CountryName);
   rc=ContName.find(key:ContinentID);
run;

/*v_3*/
data newcountry;
   length ContinentName $ 30;
   if _n_=1 then
      do;
         call missing(ContinentName);
         declare hash ContName();
         ContName.definekey('ContinentID');
         ContName.definedata('ContinentName');
         ContName.definedone();

         ContName.add(key:91, data:'North America');
         ContName.add(key:93, data:'Europe');
         ContName.add(key:94, data:'Africa');
         ContName.add(key:95, data:'Asia');
         ContName.add(key:96, data:'Australia/Pacific');
      end;
   set orion.country(keep=ContinentID Country CountryName);
   rc=ContName.find(key:ContinentID);
run;

proc print data=work.newcountry;
run;

/* 2. Loading a Hash Object from a SAS Data Set: Processing */
data newcountry;
   drop rc;
   length ContinentName $ 30;
   if _n_=1 then
      do;
         call missing(ContinentName);
         declare hash ContName(dataset:'orion.continent');
         ContName.definekey('ContinentID');
         ContName.definedata('ContinentName');
         ContName.definedone();
      end;
   set orion.country (keep=ContinentID Country CountryName);
   rc=ContName.find(key:ContinentID);
   if rc=0;
run;

proc print data=newcountry;
run;

/* 3. Viewing the OUTPUT Method Results */
data _null_;
   if 0 then set orion.continent;
   if _n_=1 then
      do;
         declare hash ContName(dataset:'orion.continent');
         ContName.definekey('ContinentID');
         ContName.definedata('ContinentName');
         ContName.definedone();

         declare hash C(multidata: 'Yes', ordered: 'ascending');
         C.definekey('ContinentID');
         C.definedata('ContinentID','ContinentName','Country',
                      'CountryName', 'Population');
         C.definedone();
      end;
   set orion.country (keep=ContinentID Country CountryName Population)
       end=eof;
   rc=ContName.find(key:ContinentID);
   rc=C.add();
   if eof then rc=C.output(dataset: 'work.newcountries');
run;

proc print data=work.newcountries;
run;

/*v_2*/
data _null_;
   if 0 then set orion.continent;
   if _n_=1 then
      do;
         declare hash ContName(dataset:'orion.continent');
         ContName.definekey('ContinentID');
         ContName.definedata('ContinentName');
         ContName.definedone();

         declare hash C(ordered: 'ascending');
         C.definekey('ContinentID');
         C.definedata('ContinentID','ContinentName','Country',
                      'CountryName', 'Population');
         C.definedone();
      end;
   set orion.country(keep=ContinentID Country CountryName Population)
       end=eof;
   rc=ContName.find(key:ContinentID);
   rc=C.add();
   if eof then rc=C.output(dataset: 'work.newcountries');
run;

proc print data=work.newcountries;
run;

/* 4. Retrieving Values from a Hash Iterator Object: SAS Processing */
data top bottom;
   drop i;
   if _N_=1 then
      do;
         if 0 then set orion.orderfact(keep=CustomerID ProductID TotalRetailPrice);
         declare hash Customer
                (dataset:'orion.orderfact', ordered:'descending');
         customer.definekey('TotalRetailPrice', 'CustomerID');
         customer.definedata('TotalRetailPrice', 'CustomerID', 'ProductID');
         customer.definedone();
         declare hiter C('Customer');
      end;
      C.first();
      do i=1 to 2;
         output top;
         C.next();
      end;
      C.last();
      do i=1 to 2;
         output bottom;
         C.prev();
      end;
      stop;
run;

proc print data=top;
  title 'Top 2 Big Spenders';
run;

proc print data=bottom;
  title 'Bottom 2 Frugal Spenders';
run;
title;
