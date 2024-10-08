/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/01/25  AA      Added system wide layouts "Available Inventory", "Short Inventory"
                        to show data from PickBatches Summary tab link
                        by using show data on request functionality(ta5899)
  2011/12/14  VM      Initial revision.
------------------------------------------------------------------------------*/

/* Records UserId and RoleId's having null considered be System Layouts */
delete from Layouts
where (UserId is null) and (RoleId is null);

Go

/*
   To get the System Layouts
   1. Set from UI pages
   2. Run the following two queries in T-SQL and copy the results and
      paste below the Insert statement below mentioned
   3. Uncomment Insert statement line as well
*/

/*
-- Get the first record with 'Select' prefix --
select top 1 'Select' + '''' + ContextName              + ''',''' + LayoutDescription + ''',''' + replace(Layout, '''', '''''') +  ''',''' +
                               DefaultLayout            + ''',''' + ShowExpanded      + ''',''' + Status                        +  ''',''' +
                               cast(SortSeq as varchar) + ''',''' + BusinessUnit      + ''''
from Layouts
where (UserId is null) and (RoleId is null)
order by RecordId

-- Get the remaining records (without first) with 'union select' prefix --
select 'union select' + '''' + ContextName              + ''',''' + LayoutDescription + ''',''' + replace(Layout, '''', '''''') +  ''',''' +
                               DefaultLayout            + ''',''' + ShowExpanded      + ''',''' + Status                        +  ''',''' +
                               cast(SortSeq as varchar) + ''',''' + BusinessUnit      + ''''
from Layouts
where (UserId is null) and (RoleId is null) and
      (RecordId <> (select min(RecordId) from Layouts where (UserId is null) and (RoleId is null)))
*/

/*------------------------------------------------------------------------------*/
/* System Layouts */
/*------------------------------------------------------------------------------*/
/* insert into Layouts (ContextName, LayoutDescription, Layout, DefaultLayout, ShowExpanded, Status, SortSeq, BusinessUnit)
      select'LPNs.gvLPNs','Available Inventory','page1|filter[OnhandStatus] = ''A''|conditions7|17|8|25|9|31|9|32|9|42|9|61|9|65|9|visible68|t0|t1|f2|t11|t12|t3|t4|t5|t6|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|t7|t8|t9|f-1|f-1|t13|f-1|f-1|t14|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|t15|f-1|f-1|f-1|f-1|f-1|f-1|f-1|t16|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|t17|f-1|f-1|f-1|f-1|f-1|f-1|t10|t18|t19|t20|t21|f-1|width68|30px|90px|60px|76px|96px|120px|86px|45px|45px|60px|60px|150px|60px|60px|80px|50px|65px|60px|100px|100px|100px|120px|100px|80px|60px|70px|60px|60px|60px|60px|60px|100px|e|120px|100px|74px|90px|60px|60px|60px|60px|60px|80px|81px|60px|60px|60px|60px|60px|60px|60px|60px|60px|60px|90px|185px|80px|80px|80px|80px|80px|150px|74px|150px|100px|150px|100px|e','N','N','A','0','TD'
union select'LPNs.gvLPNs','Short Inventory','page1|filter[OnhandStatus] In (''N'', ''R'')|conditions7|17|8|25|9|31|9|32|9|42|9|61|9|65|9|visible68|t0|t1|f2|t11|t13|t3|t4|t5|t6|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|t7|t8|t9|f-1|f-1|t12|f-1|f-1|t14|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|t15|f-1|f-1|f-1|f-1|f-1|f-1|f-1|t16|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|f-1|t17|f-1|f-1|f-1|f-1|f-1|f-1|t10|t18|t19|t20|t21|f-1|width68|30px|90px|60px|75px|90px|120px|85px|45px|45px|60px|60px|150px|60px|60px|80px|50px|65px|60px|100px|100px|100px|120px|100px|80px|60px|70px|60px|60px|60px|60px|60px|100px|e|120px|100px|90px|90px|60px|60px|60px|60px|60px|80px|100px|60px|60px|60px|60px|60px|60px|60px|60px|60px|60px|90px|185px|80px|80px|80px|80px|80px|150px|45px|150px|100px|150px|100px|e','N','N','A','0','TD'*/

Go
