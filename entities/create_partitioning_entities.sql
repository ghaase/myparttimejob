create database if not exists myparttimejob;

drop table if exists myparttimejob.partition_ranges;
create table myparttimejob.partition_ranges
(
 partition_range_id     integer     NOT NULL auto_increment,
 day                    date        NOT NULL,
 day_partition_suffix   varchar(8)  NOT NULL,
 day_partition_filter   date        NOT NULL,
 week_partition_suffix  varchar(6)  NOT NULL,
 week_partition_filter  date        NOT NULL,
 month_partition_suffix varchar(6)  NOT NULL,
 month_partition_filter date        NOT NULL,
 year_partition_suffix  varchar(4)  NOT NULL,
 year_partition_filter  date        NOT NULL,
 primary key (partition_range_id)
) engine=InnoDB
;

select @startdate := '2013-01-01';
select @enddate := '2016-01-01';

insert into myparttimejob.partition_ranges
    (
    day,
    day_partition_suffix,
    day_partition_filter,
    week_partition_suffix,
    week_partition_filter,
    month_partition_suffix,
    month_partition_filter,
    year_partition_suffix,
    year_partition_filter
    )
(
select
    daterange.start_date,
    date_format(daterange.start_date,'%Y%m%d') day_partition_name,
    date_format(daterange.end_date, '%Y-%m-%d') day_partition_less_than,
    date_format(daterange.start_date, '%X%V') week_partition_name,
    date_format(str_to_date(concat(date_format(daterange.start_date + interval 1 week, '%X%V'),'1'),'%X%V %w'), '%Y-%m-%d') week_partition_less_than,
    date_format(daterange.start_date, '%Y%m') month_partition_name,
    date_format((last_day(daterange.start_date) + interval 1 day), '%Y-%m-%d') month_partition_less_than,
    date_format(daterange.start_date, '%Y') year_partition_name,
    date_format(concat(date_format(daterange.start_date + interval 1 year, '%Y'),'0101'),'%Y-%m-%d') year_partition_less_than
from
    (
    select
        @startdate as start_date,
        @startdate := date_add(@startdate, interval 1 day) as end_date
    from 
        information_schema.columns
    having
        @startdate < @enddate
    ) daterange
)
;


drop table if exists myparttimejob.partition_tables;
create table myparttimejob.partition_tables
(
 partition_table_id     integer     NOT NULL auto_increment,
 table_schema           varchar(64) NOT NULL,
 table_name             varchar(64) NOT NULL,
 partition_frequency    enum('daily','weekly','monthly','yearly') NOT NULL default 'monthly',
 partition_base_name    varchar(50) NOT NULL,
 primary key (partition_table_id)
) engine=InnoDB
;

drop table if exists myparttimejob.testdaily;
create table myparttimejob.testdaily
(
 test_daily_id  integer     NOT NULL auto_increment,
 created_at     datetime    NOT NULL,
 primary key (created_at, test_daily_id),
 key index_testdaily_on_id (test_daily_id)
) engine=InnoDB
partition by range columns (created_at)
(partition testdaily_default values less than maxvalue)
;

drop table if exists myparttimejob.testweekly;
create table myparttimejob.testweekly
(
 test_weekly_id integer     NOT NULL auto_increment,
 created_at     datetime    NOT NULL,
 primary key (created_at, test_weekly_id),
 key index_testweekly_on_id (test_weekly_id)
) engine=InnoDB
partition by range columns (created_at)
(partition testweekly_default values less than maxvalue)
;

drop table if exists myparttimejob.testmonthly;
create table myparttimejob.testmonthly
(
 test_monthly_id integer     NOT NULL auto_increment,
 created_at     datetime    NOT NULL,
 primary key (created_at, test_monthly_id),
 key index_testmonthly_on_id (test_monthly_id)
) engine=InnoDB
partition by range columns (created_at)
(partition testmonthly_default values less than maxvalue)
;

drop table if exists myparttimejob.testyearly;
create table myparttimejob.testyearly
(
 test_yearly_id integer     NOT NULL auto_increment,
 created_at     datetime    NOT NULL,
 primary key (created_at, test_yearly_id),
 key index_testyearly_on_id (test_yearly_id)
) engine=InnoDB
partition by range columns (created_at)
(partition testyearly_default values less than maxvalue)
;

insert into myparttimejob.partition_tables
    (
    table_schema,
    table_name,
    partition_frequency,
    partition_base_name
    )
values
    (
    'myparttimejob',
    'testdaily',
    'daily',
    'testdaily_'
    ),
    (
    'myparttimejob',
    'testweekly',
    'weekly',
    'testweekly_'
    ),
    (
    'myparttimejob',
    'testmonthly',
    'monthly',
    'testmonthly_'
    ),
    (
    'myparttimejob',
    'testyearly',
    'yearly',
    'testyearly_'
    )
;

