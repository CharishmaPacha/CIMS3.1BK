/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/07/21  AY      pr_Imports_OrderDetails_AddSKUs: Fixed to not update existing SKUs and only add new ones.
  2016/06/27  AY      pr_Imports_OrderDetails_AddSKUs: Added distinct clause to avoid unique key violation issues
  2016/05/09  AY      pr_Imports_OrderDetails_AddSKUs: Added
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderDetails_AddSKUs') is not null
  drop Procedure pr_Imports_OrderDetails_AddSKUs;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_OrderDetails_AddSKUs
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderDetails_AddSKUs
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @ttSKUsToImport TSKUImportType,
          @xmlSKUs        xml,
          @vSKUList       TXML;
begin
  /* Get all SKUs from Order details that need to be imported.
     We only need to consider Speical SKUs that don't exist and only when ODs are being added or Updated
     i.e. when ODs are being deleted we don't get a SKU and hence we don't care about doing this with those lines */
  insert into @ttSKUsToImport (RecordType, RecordAction, SKU, Description, Ownership, BusinessUnit)
    select distinct 'SKU', ODI.RecordAction, ODI.SKU, ODI.SKU, ODI.Ownership, ODI.BusinessUnit
    from #OrderDetailsImport ODI
         left outer join SKUs S on (ODI.SKU = S.SKU) and
                                   (ODI.BusinessUnit = S.BusinessUnit)
    where (S.SKUId is null) and
          (ODI.LineType in ('2', '4')) and
          (ODI.RecordAction in ('I', 'U'));

  if (@@rowcount = 0) return;

  /* Generate xml from the SKUs table */
  select @xmlSKUs = (select RecordType, RecordAction as Action, SKU, Description, Ownership, BusinessUnit
                     from @ttSKUsToImport
                     FOR XML RAW('Record'), ELEMENTS);

  select @vSKUList = convert(varchar(max), @xmlSKUs);

  select @vSKUList = dbo.fn_XMLNode('msgBody', @vSKUList);
  select @vSKUList = dbo.fn_XMLNode('msg', @vSKUList);

  select @xmlSKUs = convert(xml, @vSKUList);

  /* Import SKUs */
  exec pr_Imports_SKUs @xmlSKUs;

end /* pr_Imports_OrderDetails_AddSKUs */

Go
