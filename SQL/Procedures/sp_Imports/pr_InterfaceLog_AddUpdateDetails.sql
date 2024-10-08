/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/04/20  VS/TK   pr_Imports_ImportRecord, pr_InterfaceLog_AddUpdateDetails, pr_Imports_Contact:
                      pr_InterfaceLog_AddUpdateDetails: Minor changes to input params.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_InterfaceLog_AddUpdateDetails') is not null
  drop Procedure pr_InterfaceLog_AddUpdateDetails;
Go
/*------------------------------------------------------------------------------
  Procedure pr_InterfaceLog_AddUpdateDetails is used to add/Update the given entry
   to InterfaceLogDetails
------------------------------------------------------------------------------*/
Create Procedure pr_InterfaceLog_AddUpdateDetails
  (@ParentLogId    TRecordId,
   @RecordType     TRecordType,
   @TransferType   TTransferType,
   @BusinessUnit   TBusinessUnit,
   @Inputxml       XML           = null,
   @Resultxml      XML           = null,
   @LogMessage     TDescription  = null,
   @KeyData        TReference    = null,
   @HostReference  TReference    = null,
   @HostRecId      TRecordId     = null,
   -------------------------------------
   @ILogRecordId   TRecordId output)
as
begin
  /* If recordid is not given, then add a new detail record */
  if (coalesce(@ILogRecordId, 0) = 0)
    begin
      /* Prepare Keydata - We can write a funtion to do the following but passing of xml should be done.
         So, we need to see the performance as well */
      if (@RecordType in ('SKU', 'SPP', 'SMP', 'UPC'))
         select @KeyData = Record.Col.value('SKU[1]', 'TName')
         from @Inputxml.nodes('Record') as Record(Col);
      else
      if (@RecordType in ('ROH', 'RH' /* Receipt Headers */))
         select @KeyData = Record.Col.value('ReceiptNumber[1]', 'TName')
         from @Inputxml.nodes('Record') as Record(Col);
      else
      if (@RecordType in ('ROD', 'RD' /* Receipt Details */))
         select @KeyData = Record.Col.value('ReceiptNumber[1]', 'TName')
         from @Inputxml.nodes('Record') as Record(Col);
      else
      if (@RecordType in ('SOH', 'OH' /* OrderHeaders */))
         select @KeyData = Record.Col.value('PickTicket[1]', 'TName')
         from @Inputxml.nodes('Record') as Record(Col);
      else
      if (@RecordType in ('SOD', 'OD' /* OrderDetails */))
         select @KeyData = Record.Col.value('PickTicket[1]', 'TName')
         from @Inputxml.nodes('Record') as Record(Col);
      else
      if (@RecordType = 'VEN' /* Vendors */)
         select @KeyData = Record.Col.value('VendorId[1]', 'TName')
         from @Inputxml.nodes('Record') as Record(Col);
      else
      if (@RecordType = 'CNT' /* Address(Contacts) */)
         select @KeyData = Record.Col.value('ContactRefId[1]', 'TName')
         from @Inputxml.nodes('Record') as Record(Col);
      else
      if (@RecordType in( 'ASNLH' ,'ASNLD'/* ASNLPNs */) )
         select @KeyData = Record.Col.value('LPN[1]', 'TName')
         from @Inputxml.nodes('Record') as Record(Col);
      else
      if (@RecordType in( 'LOC'/* Location */) )
         select @KeyData = Record.Col.value('Location[1]', 'TLocation')
         from @Inputxml.nodes('Record') as Record(Col);

      insert into InterfaceLogDetails (ParentLogId, TransferType, RecordType, LogMessage, KeyData, HostReference, HostRecId,
                                      BusinessUnit, Inputxml, Resultxml)
      select @ParentLogId, @TransferType, @RecordType, @LogMessage, @KeyData, @HostReference, @HostRecId,
            @BusinessUnit, convert(varchar(max), convert(nvarchar(max), @Inputxml)), convert(varchar(max), convert(nvarchar(max), @Resultxml));

      select @ILogRecordId = SCOPE_IDENTITY();
   end
 else
   update InterfaceLogDetails
   set Resultxml = convert(varchar(max), convert(nvarchar(max), @Resultxml))
   where (RecordId = @ILogRecordId);
end /* pr_InterfaceLog_AddUpdateDetails */

Go
