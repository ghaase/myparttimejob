drop procedure if exists myparttimejob.create_weekly_partitions$$

create procedure myparttimejob.create_weekly_partitions
(
    in  l_table_name    varchar(64),
    in  l_table_schema  varchar(64)
)
comment 'takes table_name and schema_name and creates partitions for 5 weeks forward'
begin

    declare     l_partition_name    varchar(64);
    declare     l_partition_filter  date;
    declare     l_new_partition     varchar(2000);
    declare     done                integer     default false;
    declare     c_partitions        cursor for
        select
            concat(pt.partition_base_name,pr.week_partition_suffix) as partition_name,
            pr.week_partition_filter as partition_filter
        from
            myparttimejob.partition_tables pt
        join
            myparttimejob.partition_ranges pr
        where
            pt.table_name = l_table_name and
            pt.table_schema = l_table_schema and
            pr.day >= curdate() and pr.day < date_add(curdate(), interval 5 week) and
            not exists
                (
                select
                    1
                from
                    information_schema.partitions isp
                where
                    isp.partition_name = concat(pt.partition_base_name,pr.week_partition_suffix) and
                    isp.table_name = l_table_name and
                    isp.table_schema = l_table_schema and
                    isp.table_name = pt.table_name and
                    isp.table_schema = pt.table_schema
                )
        group by
            pr.week_partition_suffix
        order by
            pr.day
    ;
    declare continue handler for not found set done = true;

    open c_partitions;
    partition_loop: loop

        fetch from c_partitions into l_partition_name, l_partition_filter;

        if done then
            close c_partitions;
            leave partition_loop;
        end if;

        set l_new_partition = concat_ws(',', l_new_partition, concat('partition ',l_partition_name,' values less than (''',l_partition_filter,''')'));

    end loop partition_loop;

    if l_new_partition is not null then
    
        set @sqlstatement = concat('alter table ',l_table_schema,'.',l_table_name,' reorganize partition ',l_table_name,'_default into (',l_new_partition,', partition ',l_table_name,'_default values less than maxvalue)');
        prepare sqlquery from @sqlstatement;
        execute sqlquery;
        deallocate prepare sqlquery;

    end if;

end 
