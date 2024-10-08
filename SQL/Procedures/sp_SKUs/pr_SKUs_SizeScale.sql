/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/09/06  VS      pr_SKUs_SizeScale: Intial Version (OB2-590)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SKUs_SizeScale') is not null
  drop Procedure pr_SKUs_SizeScale;
Go
/*------------------------------------------------------------------------------
  pr_SKUs_SizeScale: Enumerates the given sizes to use in pivot queries
------------------------------------------------------------------------------*/
Create Procedure pr_SKUs_SizeScale
  (@Sizes         TEntityKeystable ReadOnly,
   @SizeList      TNote out,
   @SizeTotals    TNote out,
   @GrandTotalRow TNote out)
as
declare @vReportSizes    TNote,
        @vGrandTotalCol  TNote,
        @vGrandTotalRow  TNote;

begin
  SET NOCOUNT ON;

  /* Get the all sizes to pivot by */
  select distinct @vReportSizes = stuff(
                                        (select '[' + g.EntityKey +'],'
                                         from @Sizes g
                                         order by EntityId
                                            for xml path('')),1,1,'['
                                        )
                                        from @Sizes;
  set @SizeList = reverse(stuff(reverse(@vReportSizes), 1, 1, ''));

  /* Calculate the GrandTotal value column level for all sizes */
  select @vGrandTotalCol = coalesce (@vGrandTotalCol + 'IsNull ([' + EntityKey +'],0) + ', 'isnull([' + EntityKey + '],0) + ')
  from @Sizes
  order by EntityId

  set @SizeTotals = left (@vGrandTotalCol, len (@vGrandTotalCol)-1);

  /* Calculate the GrandTotal value row level for all sizes */
  select @vGrandTotalRow = coalesce(@vGrandTotalRow + ',isnull(sum([' + EntityKey +']),0)', 'isnull(sum([' + EntityKey +']),0)')
  from @Sizes
  order by EntityId

  set @GrandTotalRow = @vGrandTotalRow

end /* pr_SKUs_SizeScale */

Go
