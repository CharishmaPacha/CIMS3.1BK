/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/14  YJ      pr_ShipLabel_GetLabelFormat: Changes to get the account name to pass it to rules Migrated from Prod (S2GCA-98)
  pr_ShipLabel_GetLabelFormat: changes to evaulate the Packing List rules and Passed the LoadNumber to the table Label to print
  pr_ShipLabel_GetLabelFormat, pr_ShipLabel_GetLabelsToPrint,
  pr_ShipLabel_GetLabelFormat: Made changes to get Carrier Interface from rules and get Ship Label Formats
  2018/05/10  RV      pr_ShipLabel_GetLabelFormat, pr_ShipLabel_GetLabelsToPrintProcess: Added Pallet Ship Label type to print
  2018/04/03  TK      pr_ShipLabel_GetLabelFormat: Changes to print PTL wave packing list (S2G-535)
  2016/11/17  KN      pr_ShipLabel_GetLabelFormat : Retrieving contacts from view to avoid duplicate rows (FB-818).
  2016/07/26  TK      pr_ShipLabel_GetLabelFormat: Changes made to consider carrier to determine ship label to be printed (HPI-187)
  2016/07/08  KN      pr_ShipLabel_GetLabelFormat: Added Ownership column (NBD-634)
  2016/06/13  TK      pr_ShipLabel_GetLabelFormat: Changes to retrieve label formats for LPN Entity
  2016/03/08  TK      pr_ShipLabel_GetLabelFormat & pr_ShipLabel_GetLabelsToPrintProcess:
  2015/11/16  TK      pr_ShipLabel_GetLabelFormat: Return TaskId (ACME-408)
  2015/10/21  AY      pr_ShipLabel_GetLabelFormat: IsPrintable would be null coming from Tasks, so handled it correctly.
  2015/07/18  VM      pr_ShipLabel_GetLabelFormat: Use singular for RuleSetType - ShipLabelFormat (FB-255)
  2014/06/13  SV      pr_ShipLabel_GetLabelFormat: Created procedure,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetLabelFormat') is not null
  drop Procedure pr_ShipLabel_GetLabelFormat;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetLabelFormat: Determine the label format and report format
    to print for each of the entities that have to be printed in the given data set.
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetLabelFormat
  (@LabelsToPrint  TLabelsToPrint ReadOnly)
as
  declare @vRecordId          TRecordId,
          @vCarrierInterface  TCarrierInterface,
          @vLabelsToPrintXML  TXML,

          @vResult            TResult,
          @vLabelType         TTypeCode,
          @vPLTypeToPrint     TTypeCode,
          @vShiplabelFormat   TName,
          @vRuleSetName       TName;

  declare @ttLabelsToPrint    TLabelsToPrint;

begin /* pr_ShipLabel_GetLabelFormat */

  /* Copy data to local table variable for processing */
  insert into @ttLabelsToPrint
     (LoadNumber, BatchNo, PickTicket, Pallet, LPNId, LPN, TaskId, OrderId, CustPO, SoldToId, ShipToId, Account,
      ShipVia, Carrier, ShipToStore, WaveType, LabelType, DocumentType, EntityType, AddressRegion,
      Operation, DocSubType, IsPrintable, Ownership, BusinessUnit,
      UDF1, UDF2, UDF3, UDF4, UDF5)
    select LTP.LoadNumber, LTP.BatchNo, OH.PickTicket, LTP.Pallet, LTP.LPNId, LTP.LPN, LTP.TaskId, OH.OrderId, LTP.CustPO, OH.SoldToId, C.ContactRefId, OH.Account,
           SV.ShipVia, SV.Carrier, OH.ShipToStore, LTP.WaveType, LTP.LabelType, LTP.DocumentType, LTP.EntityType, C.AddressRegion,
           LTP.Operation, 'LPN' /* (DocSubType) by defualt PL type as LPN */, LTP.IsPrintable, OH.Ownership, LTP.BusinessUnit,
           LTP.UDF1, LTP.UDF2, LTP.UDF3, LTP.UDF4, LTP.UDF5
    from @LabelsToPrint LTP
      /* Pallets in the data set may not have OrderId, so we have to use left outer join only */
      left outer join OrderHeaders OH on (LTP.OrderId   = OH.OrderId     )
      left outer join ShipVias     SV on (OH.ShipVia    = SV.ShipVia     )
      cross apply dbo.fn_Contacts_GetShipToAddress(OH.OrderId, OH.ShipToId) C
    order by LTP.RecordId;

  select @vRecordId = 0;

  while (exists (select * from @ttLabelsToPrint where RecordId > @vRecordId and (IsPrintable is null or IsPrintable = 'Y')))
    begin
      select @vResult = null;

      select top 1 @vRecordId    = RecordId,
                   @vLabelType   = LabelType,
                   @vRuleSetName = LabelType + '_GetFormat'
      from @ttLabelsToPrint
      where (RecordId > @vRecordId) and (IsPrintable is null or IsPrintable = 'Y')
      order by RecordId;

      /* Build the XML for record with all data in the record */
      select @vLabelsToPrintXML = (select LoadNumber, BatchNo, PickTicket, Pallet, LPNId, LPN, TaskId, OrderId, CustPO, Account,
                                          SoldToId, ShipToId, ShipVia, Carrier, '' CarrierInterface, ShipToStore, WaveType, LabelType,
                                          DocumentType, EntityType, AddressRegion, Operation,
                                          DocSubType as PackingListType /* Retained as rules may still be using this */, IsPrintable,
                                          Ownership, BusinessUnit, UDF1, UDF2, UDF3, UDF4, UDF5
                                   from @ttLabelsToPrint
                                   where RecordId = @vRecordId
                                   for xml raw('RootNode'), elements);

      /* Use rules to identify the Ship label format */
      if (@vLabelType in ('SL', 'SPL', 'PSL', 'CL' /* Shipping Label or Small Package Label or Pallet Ship Label or Contents Label */))
        begin
          /* Determine which integration we are going to use ie. Direct with UPS/FedEx or ADSI */
          exec pr_RuleSets_Evaluate 'CarrierInterface', @vLabelsToPrintXML, @vCarrierInterface output;

          /* Stufff with latest value of Carrier Interface */
          select @vLabelsToPrintXML = dbo.fn_XMLStuffValue(@vLabelsToPrintXML, 'CarrierInterface', @vCarrierInterface);

          /* Get the Ship label format */
          exec pr_RuleSets_Evaluate 'ShiplabelFormat', @vLabelsToPrintXML, @vResult output;
        end
      else
      if (@vLabelType in ('PL' /* Packing List */))
        begin
          /* Evaulate Pasking List type to be printed */
          exec pr_RuleSets_Evaluate 'PackingListType', @vLabelsToPrintXML, @vPLTypeToPrint output;

          select @vLabelsToPrintXML = dbo.fn_XMLStuffValue(@vLabelsToPrintXML, 'PackingListType', @vPLTypeToPrint)

          /* Packing List to Print */
          exec pr_RuleSets_Evaluate 'PackingList', @vLabelsToPrintXML, @vResult output;
        end
      else
      if (@vLabelType in ('PS' /* Price Stickers */))
        exec pr_RuleSets_Evaluate 'PriceStickers', @vLabelsToPrintXML, @vResult output;
      else
      if (@vLabelType in ('LPN' /* New Labels */))
        exec pr_RuleSets_Evaluate 'LPNLabelToPrint', @vLabelsToPrintXML, @vResult output;
      else
        /* By default use the RuleSet <LabelType>_GetFormat */
        exec pr_RuleSets_Evaluate @vRuleSetName, @vLabelsToPrintXML, @vResult output;

      /* Update format to i/p table param */
      update @ttLabelsToPrint
      set LabelFormatName = @vResult
      where (RecordId = @vRecordId);
    end

  /* Return records which are not printable as well as they have to be displayed to user */
  select LoadNumber, BatchNo, PickTicket, Pallet, LPNId, LPN, TaskId, OrderId, CustPO, SoldToId, ShipToId,
         Carrier, ShipVia, ShipToStore, WaveType, LabelType, LabelFormatName, IsPrintable
  from  @ttLabelsToPrint
  where (LabelType = 'PL') or
        (IsPrintable = 'N') or
        (LabelFormatName is not null); -- temporary condition as we are not yet returning PL format.

end /* pr_ShipLabel_GetLabelFormat */

Go
