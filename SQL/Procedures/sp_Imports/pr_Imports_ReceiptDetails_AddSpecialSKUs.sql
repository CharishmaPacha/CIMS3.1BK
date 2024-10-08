/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/16  SV      pr_Imports_ReceiptDetails_Validate: Initial Version
                      pr_Imports_ReceiptDetails_AddSpecialSKUs, pr_Imports_ReceiptDetails:
                        Replaced temp table with hash table
                      Added pr_Imports_ReceiptHeaders_Validate, pr_Imports_ReceiptHeaders
                        Changes to insert RH and RD from hash tables (OB2-1777)
  2017/05/25  NB      pr_Imports_OrderHeaders, pr_Imports_OrderDetails: enhanced to work with sequential processing
                        when xmlData is passed in
                      pr_Imports_ReceiptDetails: Bug Fix to properly identify SKUId and ReceiptDetailId
                      pr_Imports_ReceiptDetails_AddSpecialSKUs: Commented debug select statements(HPI-1396)
  2017/02/15  AY      pr_Imports_ReceiptDetails_AddSpecialSKUs: Use RD.UDF3 for SKU.Desc for Special Items (HPI-1391)
  2016/07/04  OK      pr_Imports_ReceiptDetails_AddSpecialSKUs: Added to Import Special SKUs if they are not already in cIMS (HPI-230)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ReceiptDetails_AddSpecialSKUs') is not null
  drop Procedure pr_Imports_ReceiptDetails_AddSpecialSKUs;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_ReceiptDetails_AddSpecialSKUs: This proc takes care of importing
    Speical SKUs that don't exist which is present along with RD line. Here the heart
    of the proc is #ReceiptDetailsImport, in which its data will be inserted before
    the execution of this proc.
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ReceiptDetails_AddSpecialSKUs
as
  declare @ttSKUsToImport TSKUImportType,
          @xmlSKUs        xml,
          @vSKUList       TXML;
begin
  /* Get all SKUs from Receipt details that need to be imported.
     We only need to consider Speical SKUs that don't exist and only when RDs are being added or Updated
     i.e. when RDs are being deleted we don't get a SKU and hence we don't care about doing this with details */
  insert into @ttSKUsToImport (RecordType, RecordAction, SKU, Description, Ownership, UoM, BusinessUnit)
    select distinct 'SKU', 'I'/* Insert */, RDI.SKU, RDI.RD_UDF3, RDI.Ownership, 'EA', RDI.BusinessUnit
    from #ReceiptDetailsImport RDI
         left outer join SKUs S on (RDI.SKU = S.SKU) and
                                   (RDI.BusinessUnit = S.BusinessUnit)
    where (S.SKUId is null) and (charindex('*', RDI.SKU)=1) and (RDI.RecordAction in ('I', 'U'));

  if (@@rowcount = 0) return;

  /* Generate xml from the SKUs table */
  select @xmlSKUs = (select RecordType, RecordAction as Action, SKU, Description, Ownership, UoM, BusinessUnit
                     from @ttSKUsToImport
                     FOR XML RAW('Record'), ELEMENTS);

  select @vSKUList = convert(varchar(max), @xmlSKUs);

  select @vSKUList = dbo.fn_XMLNode('msgBody', @vSKUList);
  select @vSKUList = dbo.fn_XMLNode('msg', @vSKUList);

  select @xmlSKUs = convert(xml, @vSKUList);

  /* Import SKUs */
  exec pr_Imports_SKUs @xmlSKUs;

end /* pr_Imports_ReceiptDetails_AddSpecialSKUs */

Go
