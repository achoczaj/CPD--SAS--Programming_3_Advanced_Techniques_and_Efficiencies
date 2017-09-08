/*******************************************************************************

Using DATA Step Arrays for Table Lookups - a collection of snippets

from Summary of Lesson 4: Using DATA Step Arrays for Table Lookups
ECPG393R - SAS Programming 3 - Advanced Techniques and Efficiencies

- define table lookup and list table lookup techniques
- describe arrays as a lookup technique
- define one-dimensional arrays and multidimensional arrays
- use a one-dimensional array as a lookup table
- use a multidimensional array as a lookup table
- load a multidimensional array from a SAS data set
- identify the advantages and disadvantages of using an array as a lookup table
*******************************************************************************/


/*******************************************************************************
1. Introduction to Lookup Techniques
*******************************************************************************/
/*
In SAS programs, you can perform table lookups using a variety of techniques. Choosing a technique for a table lookup requires knowing the structure and nature of your data, and understanding your available computing resources. When you use arrays, SAS retrieves a data value based on its position in the array. When you use hash objects, SAS retrieves a data value based on a key value. When you use PROC FORMAT to create a format table, SAS retrieves the label based on a value. These three techniques are suitable for small to medium size tables.

Other table lookup techniques include combining data horizontally using the MERGE statement in a DATA step, multiple SET statements and the KEY= option in a DATA step, and SQL procedure joins. These techniques retrieve values that are stored on disk, and therefore, are suitable for the largest tables.

Because the array is the fastest lookup technique, it's your first choice among the in-memory techniques.
*/

/*******************************************************************************
2. Using the Array as an In-Memory Lookup Technique
*******************************************************************************/
/*
SAS array is a temporary grouping of variables that exists only for the duration of the DATA step. Arrays can be one-dimensional or multidimensional. One advantage of using an array for a table lookup is its use of positional order. Each variable, or element, of the array has a position in the array. When you use arrays, SAS retrieves a value based on its position in the array. You must have numeric integers to perform the lookup, so positional order is also a disadvantage of an array.

You declare an array with an ARRAY statement. When you specify an initial value list, the values of all elements are retained in the PDV during DATA step processing, rather than being reinitialized. This creates a lookup table in memory.
  ARRAY array-name {subscript} <$> <length>
               <_temporary_> <array-elements> <(initial-value-list)>;

To perform the lookup, you use an array reference.
The syntax for the array reference is the array-name, followed by the subscript value in brackets.
  array-name {subscript};
*/

/*******************************************************************************
3. Using Multidimensional Arrays to Look Up Data
*******************************************************************************/
/*
A multidimensional array can have two or more dimensions. As with a one-dimensional array, each element in a two-dimensional array is identified by its position. The ARRAY statement for a multidimensional array is similar to the ARRAY statement for a one dimensional array. The difference is that you indicate multiple dimensions, separated by commas in the curly braces, to show the number of elements for each dimension.
  ARRAY array-name {...,rows,cols} <$> <length>
               <_temporary_> <array-elements> <(initial-value-list)>;

There is no limit to the number of dimensions you can have in a multidimensional array. Just remember that the entire array has to fit in memory at one time.

To reference the array in your DATA step program, you specify the name of the array followed by the subscript.
  array-name {subscript};
*/

/*******************************************************************************
4. Loading a Multidimensional Array from a SAS Data Set
*******************************************************************************/
/*
When you have too many values to easily hardcode in an array, you can load the array from a SAS data set. Other conditions for loading a SAS data set are when the values will change frequently, or when the same values are used in many programs. One method for loading an array from a SAS data set is to load it within a DO loop.
*/

/*******************************************************************************
Sample Programs
*******************************************************************************/
/* 1. Creating an Array and Using It as a Lookup Table */
data countryinfo;
   array ContName{91:96} $30
         ('North America',
          ' ',
          'Europe',
          'Africa',
          'Asia',
          'Australia/Pacific');
   set orion.country;
   Continent=ContName{ContinentID};
run;

proc print data=countryinfo;
run;

/* 2. Using a One-Dimensional Array to Look Up Data */
data compare;
   keep EmployeeID YearHired Salary
        Average SalaryDif;
   format Salary Average SalaryDif dollar12.2;
   array yr{1978:2011} Yr1978-Yr2011;
   if _n_=1 then set orion.salarystats
      (where=(Statistic='AvgSalary'));
   set orion.employeepayroll
      (keep=EmployeeID EmployeeHireDate Salary);
   YearHired=year(EmployeeHireDate);
   Average=yr{YearHired};
   SalaryDif=sum(Salary, -Average);
run;

proc print data=compare(obs=8);
   var EmployeeID YearHired Salary Average SalaryDif;
   title 'Using One Dimensional Arrays';
run;

title;

/* 3. Loading a Multidimensional Array from a Data Set */
data budgetamt;
   drop Yr2007-Yr2011 Month I J Y M;
   array B{12,2007:2011} _temporary_;
   if _n_=1 then
      do I=1 to 12;
         set orion.budget;
         array tmp{2007:2011} Yr2007-Yr2011;
         do J=2007 to 2011;
            B{I,J}=tmp{J};
         end;
      end;
   set orion.profit(where=(Sales ne .));
   Y=year(YYMM);
   M=month(YYMM);
   BudgetAmt=B{M,Y};
run;

proc print data=budgetamt noobs;
title 'Actual vs Budgeted Amounts';
run;
title;
