/*******************************************************************************

Accessing Observations Directly - a collection of snippets

from Summary of Lesson 3: Accessing Observations Directly
ECPG393R - SAS Programming 3 - Advanced Techniques and Efficiencies

- use the DATA step to retrieve observations by observation number
- use the DATA step to create a systematic sample, a simple random sample with - replacement, and a simple random sample without replacement
- define indexes
- list the uses of indexes
- use the DATA step to create indexes
- use PROC DATASETS to create and maintain indexes
- use PROC SQL to create and maintain indexes
- describe when an index is and is not used for WHERE statement processing
*******************************************************************************/


/*******************************************************************************
1. Accessing Observations Directly by Observation Number (POINT= option)
*******************************************************************************/
/*
This lesson describes three algorithms for creating a sample: systematic sampling, simple random sampling with replacement, and simple random sampling without replacement. When you create these types of samples, you can save resources by accessing observations directly.

In a systematic sample, the observations are selected at regular intervals from the source data set. The starting observation can be fixed, or it can be randomly selected.

In a simple random sample, the observations are selected randomly from the original data set. You can select observations for a simple random sample in two ways: with replacement and without replacement. When you sample with replacement, each observation that is selected is returned to the pool of observations before the next observation is selected. So, an observation might be selected more than one time. When you sample without replacement, after an observation is selected, it is no longer a candidate for selection. So, each observation can be selected once at most.
*/
/* 1.1 Using the DATA Step /
/*
Creating a systematic sample typically involves specifying a starting observation and selecting observations at a set interval until the end of the population data set is reached. So, the sample contains every nth observation from the population data set.

When you use the DATA step to create a systematic sample, you use the POINT= and NOBS= options in the SET statement.
The POINT= option creates and names a temporary point-variable whose numeric value determines which observation is read in the current iteration of the DO loop.
The POINT= option causes the SET statement to read observations directly, by observation number, instead of sequentially, saving I/O and CPU time.
  SET data-set-name POINT=point-variable;

The NOBS= option creates and names a temporary variable whose value is the total number of observations in the input data set.
  SET data-set-name NOBS=variable;

When you use the DATA step to create a simple random sample, you also use the POINT= and NOBS= options in the SET statement.

However, instead of selecting observations at regular intervals, you can use the RANUNI and CEIL functions to generate random observation numbers that are assigned to the point-variable.

The RANUNI function generates random numbers from a uniform distribution, and returns a decimal value between 0 and 1 non-inclusive. The RANUNI function uses the seed, a numeric value, the first time it executes, to initialize the stream of random numbers.
  RANUNI (seed)

To round up the number returned by the RANUNI function to integers, you can use the CEIL function. The CEIL function has one argument, which is a numeric constant, variable, or expression.
  CEIL (argument)
*/

/*******************************************************************************
2. Accessing Observations Directly by Key Value
*******************************************************************************/
/*
By default, SAS reads observations sequentially. You can optionally use an index to access specific observations directly. An index points to observations based on the values of one or more key index variables. This saves I/O and CPU time, particularly when you read very large data sets. By using indexes to access observations directly, you can access small subsets more quickly using a WHERE statement. Indexes can also help you perform table lookups, join observations, and modify observations. To make informed decisions about indexing, it's important to know your data and how it will be used.

Indexes and the data sets that they index are stored in the same SAS library. An index file has the same name as the associated data file, but a member type of INDEX. The index stores unique key values and their record identifiers in ascending sorted order by key value, organized in a tree structure. Record identifiers include page and observation numbers of each observation with a given key value.

You can create two types of indexes: simple indexes and composite indexes. A simple index contains the values of one key variable, which can be character or numeric. When you create a simple index, SAS assigns the name of the key variable as the name of the index. A composite index contains the values of multiple key variables, which can be character, numeric, or a combination. SAS concatenates the values of these key variables to form a single value.

Index Type	| Key Variables	| Index Name
Simple	    | CustomerID	  | CustomerID
Simple	    | ProductID	    | ProductID
Composite	  | OrderID       | OrderID_ProductID
            | ProductID
*/

/*******************************************************************************
3. Creating Indexes
*******************************************************************************/
/*
You can create as many indexes as you need, and you can index character or numeric variables. Be careful, though, and don't over-index; remember that indexing takes up disk space. Once again, knowing your data and how it's used is extremely important.

You can choose among three different techniques for creating indexes: the DATA step with the INDEX= data set option on the output SAS data set, PROC DATASETS, and PROC SQL. To create a data set and index it at the same time, use the DATA step with the INDEX= data set option on the output data set. To create or delete indexes on existing data sets, you can use PROC DATASETS or PROC SQL. After you choose a technique, you need to specify the key variable or variables. For composite indexes, you also need to supply a valid SAS name. Finally, you need to specify indexing options as appropriate.

Using the INDEX= data set option, you can specify any number of indexes, and you can specify different options for individual indexes.
  INDEX=(index-specification-1 ...<index-specification-n>)

Using the INDEX= data set option has two main advantages. You create the index and the data set in one step, which means that you read the data only once. This is very efficient. On the other hand, you have to plan your indexes before you create a data set. You can always modify, create, or delete indexes later using PROC DATASETS or PROC SQL.

To create or delete indexes on existing data sets, you can use PROC DATASETS. You follow the same basic process as with the INDEX= option: specify a key variable or variables, supply a valid SAS name for any composite indexes, and specify indexing options as required.
  PROC DATASETS LIBRARY=libref NOLIST;
         MODIFY SAS-data-set;
                INDEX DELETE index-1 <...index-n> | _ALL_;
                INDEX CREATE index-specification-2;
                INDEX CREATE index-specification-3;
  QUIT;

To create indexes using PROC SQL, you follow the same basic process as with the INDEX= option and PROC DATASETS: specify a key variable or variables, supply a valid SAS name for any composite indexes, and specify indexing options as required.
  PROC SQL;
         DROP INDEX index-name
                    FROM table-name;
         CREATE <option> INDEX index-name
                         ON table-name(column-name-1,...column-name-n);
  QUIT;
*/

/*******************************************************************************
4. Using Indexes
*******************************************************************************/
/*
To determine whether to use an index to optimize a WHERE expression, SAS first identifies an available index or indexes, selecting the best index if several are availabe. Then SAS estimates the number of observations that satisfy the WHERE expression, and compares the probable resource usage for indexed access versus sequential access.

SAS uses an index for WHERE clause optimization when a WHERE expression references either a simple index key variable or the primary key variable of a composite index, and SAS estimates that using the index is more efficient than a sequential read. SAS uses only one index to process a given WHERE expression, even if the WHERE expression specifies different variables and contains multiple conditions.

If SAS calculates that it will retrieve anywhere from 0 observations to 3% of the observations, SAS uses the index. If SAS calculates that it will retrieve between 3% and 1/3 of the data, SAS probably uses the index. And if SAS calculates that it will retrieve between 1/3 of the data and all of the data that satisfies the WHERE expression, or that it’s more efficient to read the data sequentially, SAS is unlikely to use the index.

SAS compares the probable resource usage for indexed access versus sequential access and estimates the I/O usage. The factors affecting I/O include the size of the subset relative to the size of the data file, the page size of the data file, the order of data with regard to the chosen index, the number of buffers allocated, and the cost of uncompressing a compressed file for a sequential read. Of these factors, sorting is the most important for indexing because the sorted observations that meet a specific WHERE condition are on consecutive pages.

To control index usage for WHERE processing, you can use two data set options: IDXWHERE= and IDXNAME=.
- IDXWHERE=YES tells SAS to choose the best index for optimizing a WHERE expression and to disregard the possibility of sequential processing. For example, if you know the subset is small, you might want SAS to skip the decision algorithm and use the index. IDXWHERE=NO tells SAS to ignore all indexes and read the data set sequentially. You should use IDXWHERE=NO when you know the subset is large.
- The IDXNAME= option directs SAS to use a specific index. You should use the IDXNAME= option when you know the better index, so SAS doesn't need to compare indexes. For example, if you have a compound WHERE expression with two simple indexes, and you know which index will return the fewest observations, you can tell SAS to use that index.

There are some trade-offs in indexing. Fast access to observations is a benefit, but creating and maintaining an index means extra CPU time and I/O. Retrieving values in sorted order using an index means increased CPU time and I/O to read the data. Using an index is not an efficient way to support BY-group processing. Overall, indexing requires extra disk space to store the index file, along with extra memory to load the index pages.
*/

/*******************************************************************************
  Sample Programs
*******************************************************************************/
/* 1. Using the DATA Step to Create a Simple Random Sample without Replacement */
data subset(drop=ObsLeft SampSize);
   SampSize=10;
   ObsLeft=TotObs;
   do while(SampSize>0 and ObsLeft>0);
      PickIt+1;
      if ranuni(0)<SampSize/ObsLeft then do;
         ObsPicked=PickIt;
         set orion.orderfact point=PickIt nobs=TotObs;
         output;
         SampSize=SampSize-1;
      end;
      ObsLeft=ObsLeft-1;
   end;
   stop;
run;

proc print data=subset;
   title 'A Random Sample without Replacement';
   var ObsPicked CustomerID OrderDate DeliveryDate OrderID;
run;
title;

/* 2. Creating Indexes Using the INDEX= Data Set Option */
options msglevel=n;
data orion.saleshistory(index=
                       (CustomerID ProductGroup
                        SaleID=(OrderID ProductID)
                               /unique/nomiss));
   set orion.history;
   ValueCost=CostPricePerUnit*Quantity;
   YearMonth=mdy(MonthNum, 15, input(YearID,4.));
   format ValueCost dollar12.
          YearMonth monyy7.;
   label ValueCost="Value Cost"
         YearMonth="Month/Year";
run;

options msglevel=i;
data orion.saleshistory(index=
                       (CustomerID ProductGroup
                        SaleID=(OrderID ProductID)
                               /unique/nomiss));
   set orion.history;
   ValueCost=CostPricePerUnit*Quantity;
   YearMonth=mdy(MonthNum, 15, input(YearID,4.));
   format ValueCost dollar12.
          YearMonth monyy7.;
   label ValueCost="Value Cost"
         YearMonth="Month/Year";
run;

/* 3. Creating and Deleting Indexes Using PROC DATASETS */
options msglevel=n;
proc datasets library=orion nolist;
   modify saleshistory;
      index create CustomerID;
      index create ProductGroup;
      index create SaleID=(OrderID
                   ProductID)/unique;
quit;

options msglevel=n;
proc datasets library=orion nolist;
   modify saleshistory;
      index delete _ALL_;
      index create CustomerID;
      index create ProductGroup;
      index create SaleID=(OrderID
                   ProductID)/unique;
quit;

/4. Creating and Deleting Indexes Using PROC SQL */
proc sql;
	create index CustomerID
		on orion.saleshistory(CustomerID);
	create index ProductGroup
		on orion.saleshistory(ProductGroup);
	create unique index SaleID
		on orion.saleshistory(OrderID, ProductID);
quit;

proc sql;
	drop index CustomerID, ProductGroup, SaleID
		from orion.saleshistory;
quit;

/*5. Documenting Indexes*/
proc contents data=orion.saleshistory;
run;
