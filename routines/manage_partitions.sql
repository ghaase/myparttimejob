drop procedure if exists myparttimejob.manage_partitions$$

create procedure myparttimejob.manage_partitions()
comment 'Reads from partition_tables and partition_ranges and creates new partitions for tables'
begin

    declare     l_table_schema          varchar(64);
    declare     l_table_name            varchar(64);
    declare     l_partition_freq        varchar(8);
    declare     l_partition_name        varchar(64);
    declare     l_partition_filter      date;   
    declare     done                    integer         default false;
    declare     c_partition_tables      cursor for
        select
            table_schema,
            table_name,
            partition_frequency
        from
            myparttimejob.partition_tables
    ;
    declare     continue handler for not found set done = true;
    
    open c_partition_tables;
    table_loop: loop

        fetch from c_partition_tables into l_table_schema, l_table_name, l_partition_freq;

        if done then
            close c_partition_tables;
            leave table_loop;
        end if;

        case l_partition_freq
            when 'daily' then call create_daily_partitions(l_table_name,l_table_schema);
            when 'weekly' then call create_weekly_partitions(l_table_name,l_table_schema);
            when 'monthly' then call create_monthly_partitions(l_table_name,l_table_schema);
            when 'yearly' then call create_yearly_partitions(l_table_name,l_table_schema);
        end case;

    end loop table_loop;

end
