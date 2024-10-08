/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/04/01  NB      Added 640x480 with alternate category 1280x800 (CID-242)
  2019/01/03  NB      Initial Revision(CIMSV3-345)
------------------------------------------------------------------------------*/

Go

/* Create temp table */
select * into #AMF_DeviceCategories from AMF_DeviceCategories where RecordId is null;

/*----------------------------------------------------------------------------*/                                       
insert into #AMF_DeviceCategories
              (CategoryName,  CategoryDescription, MinScreenHeight, MaxScreenHeight, MinScreenWidth, MaxScreenWidth, AlternateCategory,  Visible,  Status, SortSeq)
      select   'STD',         'Standard',          null,            null,            null,           null,           null,                1,        'A',    0
union select   '320x320',     'RF Gun',            320,             320,             320,            320,            null,                1,        'A',    0
union select   '320x240',     'RF Gladiator',      240,             320,             240,            320,            null,                1,        'A',    0
union select   '640x480',     '640x480 Tablet',    480,             640,             480,            640,            '1280x800',          1,        'A',    0
union select   '1280x800',    '1280x800 Tablet',   800,             1280,            800,            1280,           null,                1,        'A',    0
/******************************************************************************/
delete from AMF_DeviceCategories;
	
insert into AMF_DeviceCategories (CategoryName,  CategoryDescription, MinScreenHeight, MaxScreenHeight, MinScreenWidth, MaxScreenWidth, AlternateCategory, Visible,  Status, SortSeq)
  select CategoryName,  CategoryDescription, MinScreenHeight, MaxScreenHeight, MinScreenWidth, MaxScreenWidth, AlternateCategory, Visible,  Status, RecordId
  from #AMF_DeviceCategories;
	
drop table #AMF_DeviceCategories; 
 
Go
