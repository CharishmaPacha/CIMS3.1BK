/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this procedure exists. Taken here for extended functionality.
  So, if there is any common code to be modified, MUST consider modifying the same in Base version as well.
  *****************************************************************************

  2021/03/02  SJ      pr_Printers_Action_AddOrEdit: Made changes to show StockSize & ProcessGroup (HA-2019)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printers_Action_AddOrEdit') is not null
  drop Procedure pr_Printers_Action_AddOrEdit;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printers_Action_AddOrEdit: This procedure is for user to add printer
  in the system or edit an existing printer.
------------------------------------------------------------------------------*/
Create Procedure pr_Printers_Action_AddOrEdit
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vRecordId                   TRecordId,
          /* Response */
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vPrinterId                  TRecordId,
          @vPrinterName                TName,
          @vPrinterDescription         TDescription,
          @vPrinterType                TTypeCode,
          @vWarehouse                  TWarehouse,
          @vPrinterConfigName          TName,
          @vPrinterConfigIP            TName,
          @vPrinterPort                TName,
          @vProcessGroup               TName,
          @vPrintProtocol              TLookUpCode,
          @vPrinterUsability           TDescription,
          @vStockSizes                 TString,
          @vStatus                     TStatus,
          @vSortSeq                    TSortSeq;

begin /* pr_Printers_Action_AddOrEdit */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  select @vEntity               = Record.Col.value('Entity[1]',                    'TEntity'),
         @vAction               = Record.Col.value('Action[1]',                    'TAction'),
         @vPrinterId            = Record.Col.value('(Data/PrinterId) [1]',         'TRecordId'),
         @vPrinterName          = nullif(Record.Col.value('(Data/PrinterName)[1]',        'TName'), ''),
         @vPrinterDescription   = nullif(Record.Col.value('(Data/PrinterDescription)[1]', 'TDescription'), ''),
         @vPrinterType          = Record.Col.value('(Data/PrinterType)[1]',        'TTypeCode'),
         @vWarehouse            = Record.Col.value('(Data/Warehouse)[1]',          'TWarehouse'),
         @vPrinterConfigName    = Record.Col.value('(Data/PrinterConfigName)[1]',  'TName'),
         @vPrinterConfigIP      = Record.Col.value('(Data/PrinterConfigIP)[1]',    'TName'),
         @vPrinterPort          = Record.Col.value('(Data/PrinterPort )[1]',       'TName'),
         @vProcessGroup         = Record.Col.value('(Data/ProcessGroup )[1]',      'TName'),
         @vPrintProtocol        = Record.Col.value('(Data/PrintProtocol )[1]',     'TLookUpCode'),
         @vPrinterUsability     = Record.Col.value('(Data/PrinterUsability)[1]',   'TDescription'),
         @vStockSizes           = Record.Col.value('(Data/StockSizes )[1]',        'TString'),
         @vStatus               = Record.Col.value('(Data/Status)[1]',             'TStatus')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Get PrinterId of selected Printer */
  select @vPrinterId = PrinterId
  from Printers
  where (PrinterName = @vPrinterName) and (BusinessUnit = @BusinessUnit);

  /* Validations */
  if (@vAction = 'Printers_Add') and (@vPrinterId <> 0)
    set @vMessageName = 'PrinterAlreadyExists';
  else
  if (@vAction in ('Printers_Add', 'Printers_Edit')) and (@vPrinterName is null)
    set @vMessageName = 'PrinterNameIsrequired';
  else
  if (@vAction in ('Printers_Add', 'Printers_Edit')) and (@vPrinterDescription is null)
    set @vMessageName = 'PrinterDescIsrequired';
  else
  if (@vAction in ('Printers_Edit', 'Printers_Delete')) and (@vPrinterId = 0)
    set @vMessageName = 'PrinterDoesNotExist';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Insert the Records into Printers Table */
  if (@vAction = 'Printers_Add')
    begin
      /* #ttSelectedEntities is not populated with entries during addition of a new printer
         Right now we will be adding 1 record at a time */
      select @vTotalRecords = 1;

      insert into Printers
        (PrinterName, PrinterDescription, PrinterType, Warehouse, PrinterConfigName,
         PrinterConfigIP, PrinterPort, ProcessGroup, PrintProtocol, PrinterUsability, StockSizes, Status,
         SortSeq, BusinessUnit, CreatedBy)
        select @vPrinterName, @vPrinterDescription, @vPrinterType, @vWarehouse , @vPrinterConfigName,
               @vPrinterConfigIP, @vPrinterPort, @vProcessGroup, @vPrintProtocol, @vPrinterUsability, @vStockSizes, @vStatus,
               coalesce(@vSortSeq, 0), @BusinessUnit, @UserId
    end
  /* Update the details of selected Printer */
  else
  if (@vAction = 'Printers_Edit')
    update Printers
    set PrinterName           = coalesce(@vPrinterName,            PrinterName),
        PrinterDescription    = coalesce(@vPrinterDescription,     PrinterDescription),
        PrinterType           = coalesce(@vPrinterType,            PrinterType),
        Warehouse             = coalesce(@vWarehouse,              Warehouse),
        PrinterConfigName     = coalesce(@vPrinterConfigName,      PrinterConfigName),
        PrinterConfigIP       = coalesce(@vPrinterConfigIP,        PrinterConfigIP),
        PrinterPort           = coalesce(@vPrinterPort,            PrinterPort),
        ProcessGroup          = coalesce(@vProcessGroup,           ProcessGroup),
        PrintProtocol         = coalesce(@vPrintProtocol,          PrintProtocol),
        PrinterUsability      = coalesce(@vPrinterUsability,       PrinterUsability),
        StockSizes            = coalesce(@vStockSizes,             StockSizes),
        Status                = coalesce(@vStatus,                 Status),
        ModifiedDate          = current_timestamp,
        ModifiedBy            = coalesce(@UserId,                  System_user)
    where (PrinterId = @vPrinterId);
  /* delete selected Printers */
  else
  if (@vAction = 'Printers_Delete')
    begin
      delete P from Printers P
        join #ttSelectedEntities ttSE on (P.PrinterId = ttSE.EntityId)
    end

  select @vRecordsUpdated = @@rowcount

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords, @vPrinterName;

  return(coalesce(@vReturnCode, 0));
end /* pr_Printers_Action_AddOrEdit */

Go
