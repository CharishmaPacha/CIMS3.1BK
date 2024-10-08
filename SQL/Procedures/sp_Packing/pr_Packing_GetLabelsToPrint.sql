/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/28  RT      pr_Packing_GetLabelsToPrint,pr_Packing_CloseLPN: Chnages to use Printers instead of Devices (HA-683)
  2016/02/18  AY      pr_Packing_GetLabelsToPrint: New procedure to evaluate the labels to be printed at Packing
  pr_Packing_CloseLPN: Change to use pr_Packing_GetLabelsToPrint.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_GetLabelsToPrint') is not null
  drop Procedure pr_Packing_GetLabelsToPrint;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_GetLabelsToPrint: Evaluates the rules and gets the list
   of label types to print for the particular LPN and for each of the Label Types
   it uses the rules again to find the label format for each of the label types.
   It builds XML of all the label formats to be printed and returns the xml.
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_GetLabelsToPrint
  (@xmlRulesData     TXML,
   @xmlLabelsToPrint TXML output)
as
  declare @vOrderId      TRecordId,
          @ValidOrderId  TRecordId,
          @vPalletId     TRecordId,
          @ValidPalletId TRecordId,
          @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @vLabelsxml    TXML,
          @vLabelFormatsToPrint TDescription,
          @vPrinter      TName,
          @vLabelCopies  TCount,
          @xmldata       xml,
          @vPackStation  TName,
          @vOperation    TOperation,
          @vBusinessUnit TBusinessUnit,
          @vUserId       TUserId,

          @vRulesResult  TResult;
begin
  /* Initialize */
  select @vLabelsxml   = '',
         @vLabelCopies = 1,
         @xmldata      = convert(xml, @xmlRulesData);

  /* Get the Action from the xml */
  select @vPrinter      = Record.Col.value('Printer[1]',     'varchar(100)'),
         @vPackStation  = Record.Col.value('PackStation[1]', 'varchar(100)'),
         @vOperation    = Record.Col.value('Operation[1]',   'varchar(100)'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]','TBusinessUnit')
  from @xmlData.nodes('/RootNode') as Record(Col);

  /***************** Which Printer? *****************/

  /* Get configured printer for the given workstation */
  if (coalesce(@vPackStation, '') <> '')
    begin
      select @vPrinter = MappedPrinterId
      from DevicePrinterMapping DPM
        left outer join vwPrinters P on (P.PrinterName = DPM.MappedPrinterId)
      where (DPM.PrintRequestSource = @vPackStation);
    end

  /* If there is no configured printer then get the default printer */
  if (coalesce(@vPrinter, '') = '')
    select @vPrinter = dbo.fn_Controls_GetAsString(@vOperation, 'DefaultPrinter', '', @vBusinessUnit, @vUserId);

  /* If we still do not have a valid printer, then get the first available printer */
  if (not exists(select * from vwPrinters where PrinterName = @vPrinter and Status = 'A'))
    select top 1 @vPrinter = PrinterName
    from vwPrinters
    where (BusinessUnit = @vBusinessUnit) and
          (Status       = 'A' /* Active */)
    order by SortSeq;

  /***************** Which labels to print for this LPN? *****************/
  /* There could be Small Package Label, UCC 128 Label, Contents Label, Packing label */
  exec pr_RuleSets_Evaluate 'PackingLabels', @xmlRulesData, @vLabelFormatsToPrint output;

  /***************** Small Package Label *****************/
  /* If SPL label needs to be printed, then determine the format */
  if (charindex('SPL', @vLabelFormatsToPrint) > 0)
    begin
      /* Change LabelType to SPL and then evaluate the rules */
      select @xmlRulesData = dbo.fn_XMLStuffValue(@xmlRulesData, 'LabelType', 'SPL');

      exec pr_RuleSets_Evaluate 'ShiplabelFormat', @xmlRulesData, @vRulesResult output;

      /* If there is a Small package label to print, then add that to the xml */
      if (@vRulesResult <> '')
        select @vLabelsxml = @vLabelsxml + (select @vRulesResult  as LabelFormat,
                                                   @vPrinter      as Printer,
                                                   @vLabelCopies  as Copies
                                            for xml raw('Label'), elements );
    end

  /***************** Ship Label *****************/
  /* If SL label needs to be printed, then determine the format */
  if (charindex('SL', @vLabelFormatsToPrint) > 0)
    begin
      /* Change LabelType to SPL and then evaluate the rules */
      select @vRulesResult = null,
             @xmlRulesData = dbo.fn_XMLStuffValue(@xmlRulesData, 'LabelType', 'SL');

      /* Get the ship label format */
      exec pr_RuleSets_Evaluate 'ShiplabelFormat', @xmlRulesData, @vRulesResult output;

      if (@vRulesResult <> '')
        select @vLabelsxml = @vLabelsxml + (select @vRulesResult     as LabelFormat,
                                                   @vPrinter         as Printer,
                                                   @vLabelCopies     as Copies
                                            for xml raw('Label'), elements );
    end

    /***************** Contents Label *****************/
    /* If CL label needs to be printed, then determine the format */
    if (charindex('CL', @vLabelFormatsToPrint) > 0)
      begin
        /* Change LabelType to SPL and then evaluate the rules */
        select @vRulesResult = null,
               @xmlRulesData = dbo.fn_XMLStuffValue(@xmlRulesData, 'LabelType', 'CL');

        /* Get the ship label format */
        exec pr_RuleSets_Evaluate 'ShiplabelFormat', @xmlRulesData, @vRulesResult output;

        if (@vRulesResult <> '')
          select @vLabelsxml = @vLabelsxml + (select @vRulesResult     as LabelFormat,
                                                     @vPrinter         as Printer,
                                                     @vLabelCopies     as Copies
                                              for xml raw('Label'), elements );
      end

  /***************** Packing Label *****************/
  /* If PCKL label needs to be printed, then determine the format */
  if (charindex('PCKL', @vLabelFormatsToPrint) > 0)
    begin
      /* Change LabelType to SPL and then evaluate the rules */
      select @vRulesResult = null,
             @xmlRulesData = dbo.fn_XMLStuffValue(@xmlRulesData, 'LabelType', 'PCKL');

      /* Get the Packing label format */
      exec pr_RuleSets_Evaluate 'ShiplabelFormat', @xmlRulesData, @vRulesResult output;

      if (@vRulesResult <> '')
        select @vLabelsxml = @vLabelsxml + (select @vRulesResult as LabelFormat,
                                                   @vPrinter     as Printer,
                                                   @vLabelCopies as Copies
                                            for xml raw('Label'), elements );
    end

  select @xmlLabelsToPrint = @vLabelsxml;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_GetLabelsToPrint */

Go
