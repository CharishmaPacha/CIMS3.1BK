/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_Replenish_Details') is not null
  drop Procedure pr_DaB_Replenish_Details;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_Replenish_Details: Used to show the summary of Orders, Lines,
    SKUs and Units on the Batch
------------------------------------------------------------------------------*/
Create Procedure pr_DaB_Replenish_Details
as
begin
  SET NOCOUNT ON;

  select tasksubtype, taskstatusdesc, taskdetailstatusdesc, destzone, vwPT_UDF1,
  pickzone, vwPT_UDF2, count(*) NumPicks, sum(TotalInnerPacks) NumInnerPacks, sum(TotalUnits) NumUnits
  from vwPicktasks
  where (PickTicket like 'R%'   ) and
        (Archived = 'N' /* No */)
  group by tasksubtype, taskstatusdesc, taskdetailstatusdesc, destzone, vwPT_UDF1, vwPT_UDF2,
  pickzone

end /* pr_DaB_Replenish_Details */

Go
