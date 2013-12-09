drop procedure if exists myparttimejob.create_daily_partitions$$

create procedure myparttimejob.create_daily_partitions
(
    in  l_table_name    varchar(64),
    in  l_table_schema  varchar(64)
)
comment 'takes table_name and schema_name and creates partitions for 7 days forward'
begin

    declare     l_partition_name    varchar(64);
    declare     l_partition_filter  date;
    declare     l_new_partition     varchar(2000);
    declare     done                integer     default false;
    declare     c_partitions        cursor for
        select
            concat(pt.partition_base_name,pr.day_partition_suffix) as partition_name,
            pr.day_partition_filter as partition_filter
        from
            myparttimejob.partition_tables pt
        join
            myparttimejob.partition_ranges pr
        where
            pt.table_name = l_table_name and
            pt.table_schema = l_table_schema and
            pr.day >= curdate() and pr.day < date_add(curdate(), interval 7 day) 
        group by
            pr.day_partition_suffix
        order by
            pr.day
    ;
    declare continue handler for not found set done = true;
    declare continue handler for 1517
    begin
        select concat('Did not create ',l_partition_name,' - partition already exists') as status;
    end;

    open c_partitions;
    partition_loop: loop

        fetch from c_partitions into l_partition_name, l_partition_filter;

        if done then
            close c_partitions;
            leave partition_loop;
        end if;

        set l_new_partition = concat('partition ',l_partition_name,' values less than (''',l_partition_filter,''')');
        set @sqlstatement = concat('alter table ',l_table_schema,'.',l_table_name,' reorganize partition ',l_table_name,'_default into (',l_new_partition,', partition ',l_table_name,'_default values less than maxvalue)');
        prepare sqlquery from @sqlstatement;
        execute sqlquery;
        deallocate prepare sqlquery;

    end loop partition_loop;

end 
