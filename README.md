partitionmagic
==============

A set of entities and routines for managing range column date partitions in MySQL. Tables can be partitioned by day, week, month, or year.

Installation
------------
Clone the repo and then execute the install.sql script as a user with suitable permissions to create databases and execute routines. Make sure you use the delimiter switch as shown below or the routines will not compile correctly.
- git clone https://github.com/ghaase/partitionmagic
- cd partitionmagic
- mysql -uuser -ppass -hhostname --delimiter='$$' < install.sql

Verify your Install
-------------------
The install script creates a set of test tables created in the partitionmagic schema which allow you to verify the functionality before implementing your own tables. You can log into your database and check for exsting partitions, call the manage_partitions routine, and the rerun the select statement to validate things are working correctly.

```
mysql> select table_name, partition_name from information_schema.partitions where partition_name is not null;
+--------------+---------------------+
| table_name   | partition_name      |
+--------------+---------------------+
| testdaily    | testdaily_default   |
| testmonthly  | testmonthly_default |
| testweekly   | testweekly_default  |
| testyearly   | testyearly_default  |
+--------------+---------------------+
4 rows in set (0.10 sec)

mysql> call partitionmagic.manage_partitions();
Query OK, 0 rows affected, 1 warning (0.73 sec)

mysql> select table_name, partition_name from information_schema.partitions where partition_name is not null;
+--------------+---------------------+
| table_name   | partition_name      |
+--------------+---------------------+
| testdaily    | testdaily_20130826  |
| testdaily    | testdaily_20130827  |
| testdaily    | testdaily_20130828  |
| testdaily    | testdaily_20130829  |
| testdaily    | testdaily_20130830  |
| testdaily    | testdaily_default   |
| testmonthly  | testmonthly_201308  |
| testmonthly  | testmonthly_201309  |
| testmonthly  | testmonthly_201310  |
| testmonthly  | testmonthly_default |
| testweekly   | testweekly_201334   |
| testweekly   | testweekly_201335   |
| testweekly   | testweekly_201336   |
| testweekly   | testweekly_201337   |
| testweekly   | testweekly_201338   |
| testweekly   | testweekly_default  |
| testyearly   | testyearly_2013     |
| testyearly   | testyearly_2014     |
| testyearly   | testyearly_default  |
+--------------+---------------------+
19 rows in set (0.10 sec)
```

Use It
------
First, you will need tables that are partitioned by date or timestamp using the range columns( date_column_name ) syntax. Each table should have a default partition identified by '<table_name>_default' with values less than maxvalue. This is critical because the routines split this partition into multiple partitions.

Note that partitioning in InnoDB is not that straightforward due to requirements for auto_increment and requirements for partitioning keys. One way to do it is to make the primary key ( date_column_name, id ) and then have a seeparate index on id. This will allow you to have the date column as the first (useeful) column in the partitioning index, but still allow InnoDB to correctly increment the id field.

For example:
```
create table partition_me_dates
(
  partition_me_dates_id     integer     NOT NULL    auto_increment,
  insert_date               datetime    NOT NULL,
  [... snip table column irrelevant to example ...]
  primary_key (insert_date, partition_me_dates_id),
  key index_partition_me_dates_on_id (partition_me_dates_id)
) engine=InnoDB
partition by range column (insert_date)
(padtition partition_me_dates_default values less than maxvalue)
;
```

In order for the system to know that your table needs partition management, you need to insert a row into the partition_tables table. Partition Frequency can be daily, weekly, monthly, or yearly.

```
insert into partitionmagic.partition_tables
    (
    table_schema,
    table_name,
    partition_frequency,
    partition_base_name
    )
values
    (
    'my_schema',
    'partition_me_dates_',
    'daily',
    'partition_me_dates_'
    )
;
```

Once you have created the table and inserted the record into the partition_tables table, you can manage your partitions simply by calling the routine:

```
call partitionmagic.manage_partitions();
```

We suggest putting that call in a daily crontab.
