/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2015/06/05  DK      Commented Default LabelPrintSortOrder as more work has to be done related to it
  2014/03/05  TK      Changes to control data using procedure
  2103/10/18  TD      Added Default LabelPrintSortOrder
  2012/11/05  AA      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
 /* Label Print Sort Order */
/*------------------------------------------------------------------------------*/
declare @LabelPrintSortOrder TLookUpsTable, @LookUpCategory TCategory = 'LabelPrintSortOrder';

insert into @LabelPrintSortOrder
       (LookUpCode,  LookUpDescription,         Status)
values ('BPL',       'Wave, PickTicket, LPN',   'A')

exec pr_LookUps_Setup @LookUpCategory, @LabelPrintSortOrder, @LookUpCategoryDesc = 'Label Print Sort Sequence';

Go
