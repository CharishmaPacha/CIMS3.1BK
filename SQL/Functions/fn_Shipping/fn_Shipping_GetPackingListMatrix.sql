/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/10/03  AA      fn_Shipping_GetPackingListMatrix: Added UnitSalePrice in output
  2012/09/26  AY      fn_Shipping_GetPackingListMatrix: Enhance to match TD packing list
  2012/09/11  AY      fn_Shipping_GetPackingListMatrix: Enhance to show Component SKUs
                        for Prepacks.
  2012/08/16  PKS     pr_Shipping_GetPackingListData: function 'fn_Shipping_GetPackingListMatrix' is used
                      instead of vwPackingListDetails.
  2012/08/14  AY      fn_Shipping_GetPackingListMatrix: New procedure to show PL in a matrix format
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Shipping_GetPackingListMatrix') is not null
  drop Function fn_Shipping_GetPackingListMatrix;
Go
/*------------------------------------------------------------------------------
  fn_Shipping_GetPackingListMatrix
  Function to return the packed item details for on order in a matrix format.

  This returns the size scale to be printed as well as the quantities per size
  and blank lines in between for better readability.
------------------------------------------------------------------------------*/
Create Function fn_Shipping_GetPackingListMatrix
  (@OrderId TRecordId)
returns
  @PackingListDetails table
    (SKU1            TSKU,
     SKU2            TSKU,
     SKU3            TSKU,
     SKUDescription  TDescription,
     CustSKU         TSKU,

     HostLineNo      THostOrderLine,
     RetailUnitPrice TMoney,
     UnitSalePrice   TMoney,
     LineTotalAmount TMoney,

     Value1          varchar(10),
     Value2          varchar(10),
     Value3          varchar(10),
     Value4          varchar(10),
     Value5          varchar(10),
     Value6          varchar(10),
     Value7          varchar(10),
     Value8          varchar(10),
     Value9          varchar(10),
     Value10         varchar(10),
     Value11         varchar(10),
     Value12         varchar(10),

     TotalValue      varchar(10),
     RecordId        TRecordId identity(1,1))
as
begin
  declare @vHostOrderLine     THostOrderLine,
          @vUoM               TUoM,
          @vSKU2              TSKU,
          @vPrevSizeScale     TDescription,
          @vSizeScale         TDescription,
          @vShowComponents    TFlag;

  declare @OrderLines         table
          (OrderId            TRecordId,
           HostOrderLine      THostOrderLine,
           SKUId              TRecordId,
           SKU2               TSKU,
           UoM                TUoM,
           PackQty            TQuantity Default 1,
           ProcessedFlag      TFlag default 'N');

  /* Initialize */
  select @vPrevSizeScale  = '',
         @vShowComponents = 'N';

  /* Get the distinct order lines */
  insert into @OrderLines (OrderId, HostOrderLine, SKUId, SKU2, UoM)
    select distinct OD.OrderId, OD.HostOrderLine, S.SKUId, S.SKU2, S.UoM
    from OrderDetails OD left outer join SKUs S on OD.SKUId = S.SKUId
    where (OrderId = @OrderId);

  with MSKUs (SKUId, PrePackQty)
  as
  (
    select OL.SKUId, sum(SPP.ComponentQty)
    from @OrderLines OL join SKUPrepacks SPP on OL.SKUId = SPP.MasterSKUId
    group by OL.SKUId
  )
  update @OrderLines
  set PackQty = PrePackQty
  from @OrderLines OL join MSKUs MS on OL.SKUId = MS.SKUId
  where (Uom = 'PP');

  while (exists (select * from @OrderLines where ProcessedFlag = 'N'))
    begin
      /* select the first line */
      select top 1 @vHostOrderLine = HostOrderLine,
                   @vSKU2          = SKU2,
                   @vUoM           = UoM
      from @OrderLines
      where (ProcessedFlag = 'N')
      order by cast (HostOrderLine as integer);

      /* Determine the size scale for this line */
      if (@vUoM = 'PP' /* Prepack */) and (@vShowComponents = 'Y')
        select @vSizeScale = FullScale
        from vwPackingListPrepackSizeScale
        where (OrderId = @OrderId) and (HostOrderLine = @vHostOrderLine);
      else
        select @vSizeScale = FullScale
        from vwPackingListSizeScale
        where (SKU2 = @vSKU2);

      /* if the size scale is different than previous one, then we need to insert it for printing */
      if (@vPrevSizeScale <> @vSizeScale)
        begin
          /* Unless this is the first line, insert a blank line so that there is
             a separation between earlier lines and this one */
          if (@vPrevSizeScale <> '')
            insert into @PackingListDetails (Value1) select null;

          /* Insert the size scale header of a solid SKU or Prepack SKU */
          if (@vUoM = 'PP' /* Prepack */) and (@vShowComponents = 'Y')
            insert into @PackingListDetails (Value1, Value2,  Value3,  Value4,
                                             Value5, Value6,  Value7,  Value8,
                                             Value9, Value10, Value11, Value12)
              select Size1, Size2, Size3, Size4, Size5, Size6,
                     Size7, Size8, Size9, Size10, Size11, Size12
              from vwPackingListPrepackSizeScale
              where (OrderId = @OrderId) and
                    (HostOrderLine = @vHostOrderLine)
          else
            insert into @PackingListDetails (Value1, Value2,  Value3,  Value4,
                                             Value5, Value6,  Value7,  Value8,
                                             Value9, Value10, Value11, Value12)
              select Size1, Size2, Size3, Size4, Size5, Size6,
                     Size7, Size8, Size9, Size10, Size11, Size12
              from vwPackingListSizeScale
              where --(OrderId = @OrderId) and
                    (SKU2    = @vSKU2);

          select @vPrevSizeScale = @vSizeScale;
        end

      /* Now insert the units for this line */
      if (@vUoM = 'PP' /* Prepack */) and (@vShowComponents = 'Y')
        insert into @PackingListDetails
          select SKU1, SKU2, SKU3, SKU2 + ' ' + SKUDescription, '',
                 PPM.HostOrderLine,  RetailUnitPrice/PackQty, UnitSalePrice/PackQty, TotalUnits * (UnitSalePrice/PackQty),
                 Units1, Units2, Units3, Units4, Units5, Units6, Units7, Units8,
                 Units9, Units10, Units11, Units12, TotalUnits
          from vwPackingListPrepackMatrix PPM join @OrderLines OL on PPM.HostOrderLine = OL.HostOrderLine
          where (PPM.OrderId = @OrderId) and (PPM.HostOrderLine = @vHostOrderLine);
      else
        insert into @PackingListDetails
          select SKU1, SKU2, SKU3, substring(coalesce(CustSKU + ' ', '') + SKUDescription, 1, 30),
                 CustSKU, HostOrderLine, RetailUnitPrice, UnitSalePrice, TotalUnits * UnitSalePrice,
                 Units1, Units2, Units3, Units4, Units5, Units6, Units7, Units8,
                 Units9, Units10, Units11, Units12, TotalUnits
          from vwPackingListMatrix
          where (OrderId = @OrderId) and (HostOrderLine = @vHostOrderLine);

      update @OrderLines
      set ProcessedFlag = 'Y'
      where (OrderId = @OrderId) and (HostOrderLine = @vHostOrderLine);
    end

   return
end /* fn_Shipping_GetPackingListMatrix */

Go
