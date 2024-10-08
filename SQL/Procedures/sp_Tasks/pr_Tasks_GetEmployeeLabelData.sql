/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/12/23  PK      pr_Tasks_GetEmployeeLabelData: Updated MaxLabelsToPrint property to print 100 labels.
  2016/08/16  TK      pr_Tasks_GetEmployeeLabelData: Changes made to return number of labels to be printed per Employee (HPI-475)
  2016/08/10  TD      pr_Tasks_GetEmployeeLabelData: Added account number to the output table, and updating.
  2016/08/10  AY      pr_Tasks_GetEmployeeLabelData: Return Packing group and Emp Seq No to print on label
  2016/08/03  TK      pr_Tasks_GetEmployeeLabelData: Changes made to print atleast sales order no if cust# is absent (HPI-421)
  2016/08/02  TK      pr_Tasks_GetEmployeeLabelData: Initial Revision (HPI-379)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Tasks_GetEmployeeLabelData') is not null
  drop Procedure pr_Tasks_GetEmployeeLabelData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Tasks_GetEmployeeLabelData
------------------------------------------------------------------------------*/
Create Procedure pr_Tasks_GetEmployeeLabelData
  (@TaskId           TRecordId,
   @LabelFormatName  TName   = null)
as
  declare @vEmpRecordId      TRecordId,
          @vRecordId         TInteger,
          @vLabelSNo         TInteger,
          @vCol              TInteger,
          @vCols             TInteger,
          @vLinecount        TInteger,
          @vRecordCount      TInteger,

          @vEmpNo            TName,
          @vEmpName          TName,
          @vTaskId           TRecordId,
          @vSalesOrder       TSalesOrder,
          @vPickTicket       TPickTicket,
          @vSKU              TSKU,
          @vSKUDescription   TDescription,
          @vQuantity         TQuantity,
          @vUDF1             TUDF,
          @vUDF2             TUDF,
          @vUDF3             TUDF,
          @vUDF4             TUDF,
          @vUDF5             TUDF,
          @vUDF6             TUDF,
          @vUDF7             TUDF,
          @vUDF8             TUDF,
          @vUDF9             TUDF,
          @vUDF10            TUDF,

                    /* Label Info */
          @vPrintOptionsXml   xml,
          @vGetAdditionalInfo TFlag,
          @vContentsInfo      TFlag,
          @vContentLinesPerLabel
                              TCount,
          @vMaxLabelsToPrint  TCount;

  declare @LabelContents  table
    (TaskId           TRecordId,
     PickTicket       TPickTicket,
     SalesOrder       TSalesOrder,
     Account          TAccount,
     LabelSNo         TInteger, /* Row is a Keyword - What is this for ? */
                               /* Ans: No of total labels required to print content label  */
     EmpNo            TName,
     EmpName          TName,
     NumInnerPacksDesc TDescription,

     SKU1             TSKU,
     SKUDescription1  TDescription,
     Quantity1        TQuantity,
     UDF11            TUDF,
     UDF21            TUDF,
     UDF31            TUDF,
     UDF41            TUDF,
     UDF51            TUDF,
     UDF61            TUDF,
     UDF71            TUDF,
     UDF81            TUDF,
     UDF91            TUDF,
     UDF101           TUDF,

     SKU2             TSKU,
     SKUDescription2  TDescription,
     Quantity2        TQuantity,
     UDF12            TUDF,
     UDF22            TUDF,
     UDF32            TUDF,
     UDF42            TUDF,
     UDF52            TUDF,
     UDF62            TUDF,
     UDF72            TUDF,
     UDF82            TUDF,
     UDF92            TUDF,
     UDF102           TUDF,

     SKU3             TSKU,
     SKUDescription3  TDescription,
     Quantity3        TQuantity,
     UDF13            TUDF,
     UDF23            TUDF,
     UDF33            TUDF,
     UDF43            TUDF,
     UDF53            TUDF,
     UDF63            TUDF,
     UDF73            TUDF,
     UDF83            TUDF,
     UDF93            TUDF,
     UDF103           TUDF,

     SKU4             TSKU,
     SKUDescription4  TDescription,
     Quantity4        TQuantity,
     UDF14            TUDF,
     UDF24            TUDF,
     UDF34            TUDF,
     UDF44            TUDF,
     UDF54            TUDF,
     UDF64            TUDF,
     UDF74            TUDF,
     UDF84            TUDF,
     UDF94            TUDF,
     UDF104           TUDF,

     SKU5             TSKU,
     SKUDescription5  TDescription,
     Quantity5        TQuantity,
     UDF15            TUDF,
     UDF25            TUDF,
     UDF35            TUDF,
     UDF45            TUDF,
     UDF55            TUDF,
     UDF65            TUDF,
     UDF75            TUDF,
     UDF85            TUDF,
     UDF95            TUDF,
     UDF105           TUDF,

     SKU6             TSKU,
     SKUDescription6  TDescription,
     Quantity6        TQuantity,
     UDF16            TUDF,
     UDF26            TUDF,
     UDF36            TUDF,
     UDF46            TUDF,
     UDF56            TUDF,
     UDF66            TUDF,
     UDF76            TUDF,
     UDF86            TUDF,
     UDF96            TUDF,
     UDF106           TUDF,

     SKU7             TSKU,
     SKUDescription7  TDescription,
     Quantity7        TQuantity,
     UDF17            TUDF,
     UDF27            TUDF,
     UDF37            TUDF,
     UDF47            TUDF,
     UDF57            TUDF,
     UDF67            TUDF,
     UDF77            TUDF,
     UDF87            TUDF,
     UDF97            TUDF,
     UDF107           TUDF,

     SKU8             TSKU,
     SKUDescription8  TDescription,
     Quantity8        TQuantity,
     UDF18            TUDF,
     UDF28            TUDF,
     UDF38            TUDF,
     UDF48            TUDF,
     UDF58            TUDF,
     UDF68            TUDF,
     UDF78            TUDF,
     UDF88            TUDF,
     UDF98            TUDF,
     UDF108           TUDF,

     SKU9             TSKU,
     SKUDescription9  TDescription,
     Quantity9        TQuantity,
     UDF19            TUDF,
     UDF29            TUDF,
     UDF39            TUDF,
     UDF49            TUDF,
     UDF59            TUDF,
     UDF69            TUDF,
     UDF79            TUDF,
     UDF89            TUDF,
     UDF99            TUDF,
     UDF109           TUDF,

     SKU10            TSKU,
     SKUDescription10 TDescription,
     Quantity10       TQuantity,
     UDF110           TUDF,
     UDF210           TUDF,
     UDF310           TUDF,
     UDF410           TUDF,
     UDF510           TUDF,
     UDF610           TUDF,
     UDF710           TUDF,
     UDF810           TUDF,
     UDF910           TUDF,
     UDF1010          TUDF);

  declare @ttEmpToProcess table
    (EmpNo            TName,
     EmpName          TName,
     PickTicket       TPickTicket,

     RecordId         TRecordId identity (1,1));

  declare @TaskDetails table
    (TaskId           TRecordId,
     PickTicket       TPickTicket,
     SalesOrder       TSalesOrder,
     SKU              TSKU,
     SKUDescription   TDescription,
     Quantity         TQuantity,
     UDF1             TUDF,
     UDF2             TUDF,
     UDF3             TUDF,
     UDF4             TUDF,
     UDF5             TUDF,
     UDF6             TUDF,
     UDF7             TUDF,
     UDF8             TUDF,
     UDF9             TUDF,
     UDF10            TUDF,

     RecordId         TRecordId identity(1,1));

  declare @TaskDetailsToProcess table
    (TaskId           TRecordId,
     PickTicket       TPickTicket,
     SalesOrder       TSalesOrder,
     EmpNo            TName,
     EmpName          TName,
     SKU              TSKU,
     SKUDescription   TDescription,
     Quantity         TQuantity,
     UDF1             TUDF,
     UDF2             TUDF,
     UDF3             TUDF,
     UDF4             TUDF,
     UDF5             TUDF,
     UDF6             TUDF,
     UDF7             TUDF,
     UDF8             TUDF,
     UDF9             TUDF,
     UDF10            TUDF,

     RecordId         TRecordId identity(1,1));

begin /* pr_Tasks_GetEmployeeLabelData */
  SET NOCOUNT ON;

  select @vLinecount   = 0,
         @vEmpRecordId = 0;

  /* Get Label Details */
  select @vPrintOptionsXml = PrintOptions
  from LabelFormats
  where (LabelFormatName = @LabelFormatName);

  if (@vPrintOptionsXML is not null)
    select @vContentsInfo         = Record.Col.value('ContentsInfo[1]',         'TFlag'),
           @vContentLinesPerLabel = Record.Col.value('ContentLinesPerLabel[1]', 'TCount'),
           @vMaxLabelsToPrint     = Record.Col.value('MaxLabelsToPrint[1]',     'TCount'),
           @vGetAdditionalInfo    = Record.Col.value('GetAdditionalInfo[1]',    'TFlag')
    from @vPrintOptionsXml.nodes('printoptions') as Record(Col);

  /* initialize row with starting number
     initialize cols with number sku details a label can hold - 10 if none is passed in */
  select @vLabelSNo         = 1,
         @vCols             = coalesce(nullif(@vContentLinesPerLabel, 0), 10),
         @vMaxLabelsToPrint = coalesce(nullif(@vMaxLabelsToPrint, 0), 100);

  insert into @TaskDetailsToProcess(TaskId, PickTicket, SalesOrder, EmpNo, EmpName, SKU, SKUDescription, Quantity, UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10)
    select TD.TaskId, OD.PickTicket, OD.SalesOrder, OD_UDF1, OD_UDF2, OD.SKU, OD.SKUDesc, OD.UnitsAuthorizedToShip, OD.OH_UDF7, OD.PackingGroup,
           TD.PickPosition, '', '', '', '', '', '', ''
    from TaskDetails TD
      join vwOrderDetails  OD on (TD.OrderDetailId = OD.OrderDetailId)
    where (TD.TaskId = @TaskId) and
          (TD.Status <> 'X'/* Canceled */) and
          (coalesce(nullif(OD.OD_UDF1, ''), '') <> '') and
          (coalesce(nullif(OD.OD_UDF2, ''), '') <> '');

  /* There may be different employees per order get them */
  insert into @ttEmpToProcess(EmpNo, EmpName, PickTicket)
    select distinct EmpNo, EmpName, PickTicket
    from @TaskDetailsToProcess;

  /* Loop thru each employee and get their details */
  while exists (select * from @ttEmpToProcess where RecordId > @vEmpRecordId)
    begin
      select top 1 @vEmpRecordId = RecordId,
                   @vEmpNo       = EmpNo,
                   @vEmpName     = EmpName,
                   @vPickTicket  = PickTicket
      from @ttEmpToProcess
      where (RecordId > @vEmpRecordId)
      order by RecordId;

      /* Initialization */
      select @vRecordId    = 0,
             @vLinecount   = 0,
             @vRecordCount = 1;

      delete from @TaskDetails;

      /* insert the required data into a temp table to loop through / process */
      insert into @TaskDetails(TaskId, PickTicket, SalesOrder, SKU, SKUDescription, Quantity, UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10)
        select TaskId, PickTicket, SalesOrder, SKU, SKUDescription, Quantity, UDF1, UDF2, UDF3, UDF4, UDF5, UDF6, UDF7, UDF8, UDF9, UDF10
        from @TaskDetailsToProcess
        where (TaskId     = @TaskId     ) and
              (EmpNo      = @vEmpNo     ) and
              (EmpName    = @vEmpName   ) and
              (PickTicket = @vPickTicket);

      /* Number of records inserted */
      select @vLinecount = count(*) from @TaskDetails;

      /* Fill the table variable with the rows for your result set
         Iterate thru each Pack detail record and insert into output table */
      while exists (select * from @TaskDetails where RecordId > @vRecordId)
        begin
          /* For each record to print, compute the label number and the column number to add data to in that label,
             for example, the first record will be label 1 col 1, second will be label 1, col 2 ... 10th would be
             label 1, col 10 and next would be label 2, col 1 and so on... */
          select top 1
               @vRecordId          = RecordId,
               @vTaskId            = TaskId,
               @vPickTicket        = PickTicket,
               @vSalesOrder        = coalesce(nullif(UDF1, '') + '-', '') + SalesOrder, -- Cust # and Sales Order
               @vSKU               = SKU,
               @vSKUDescription    = SKUDescription,
               @vQuantity          = Quantity,
               @vUDF1              = UDF1,
               @vUDF2              = UDF2,
               @vUDF3              = UDF3,
               @vUDF4              = UDF4,
               @vUDF5              = UDF5,
               @vUDF6              = UDF6,
               @vUDF7              = UDF7,
               @vUDF8              = UDF8,
               @vUDF9              = UDF9,
               @vUDF10             = UDF10,
               /* Column number is mod of total columns except when result is zero when it is the last line */
               @vCol               = case when @vRecordCount % @vCols = 0 then @vCols
                                          else @vRecordCount % @vCols end,
               @vLabelSNo          = case when @vRecordCount % @vCols = 0 then @vRecordCount / @vCols
                                          else round(@vRecordCount / @vCols + 1, 0) end
          from @TaskDetails
          where RecordId > @vRecordId
          order by RecordId;

          set @vRecordCount += 1;

          /* In some situations, no matter how many lines there are, we may only want to print one label
             and have something like ...and more at the end of the label. So, check for the condition
             where we are exceeding the max labels and quit;
          */
          if (@vLabelSNo > @vMaxLabelsToPrint) break;

          /* create a new record for each lpn and for single label (label can hold 10 sku details)
             create additional record if sku details exceeds more than 10 per label */
          if not exists(select @TaskId from @LabelContents where (TaskId     = @vTaskId    ) and
                                                                 (PickTicket = @vPickTicket) and
                                                                 (EmpNo      = @vEmpNo     ) and
                                                                 (EmpName    = @vEmpName   ) and
                                                                 (LabelSNo   = @vLabelSNo  ))
            begin
              insert into @LabelContents (TaskId, PickTicket, SalesOrder, EmpNo, EmpName, LabelSNo, SKU1, SKUDescription1, Quantity1, UDF11, UDF21, UDF31, UDF41, UDF51, UDF61, UDF71, UDF81, UDF91, UDF101)
                values(@vTaskId, @vPickTicket, @vSalesOrder, @vEmpNo, @vEmpName, @vLabelSNo, @vSKU, @vSKUDescription, @vQuantity, @vUDF1, @vUDF2, @vUDF3, @vUDF4, @vUDF5, @vUDF6, @vUDF7, @vUDF8, @vUDF9, @vUDF10)
            end
          else
            begin
              /* Update rest of the sku details defined as columns (to obtain transform / pivot functionality) */
              update @LabelContents
              set SKU1       = case when @vCol = 1 then @vSKU      else SKU1   end,
                  SKUDescription1
                             = case when @vCol = 1 then @vSKUDescription
                                                                   else SKUDescription1 end,
                  Quantity1  = case when @vCol = 1 then @vQuantity else Quantity1 end,
                  UDF11      = case when @vCol = 1 then @vUDF1     else UDF11  end,
                  UDF21      = case when @vCol = 1 then @vUDF2     else UDF21  end,
                  UDF31      = case when @vCol = 1 then @vUDF3     else UDF31  end,
                  UDF41      = case when @vCol = 1 then @vUDF4     else UDF41  end,
                  UDF51      = case when @vCol = 1 then @vUDF5     else UDF51  end,
                  UDF61      = case when @vCol = 1 then @vUDF6     else UDF61  end,
                  UDF71      = case when @vCol = 1 then @vUDF7     else UDF71  end,
                  UDF81      = case when @vCol = 1 then @vUDF8     else UDF81  end,
                  UDF91      = case when @vCol = 1 then @vUDF9     else UDF91  end,
                  UDF101     = case when @vCol = 1 then @vUDF10    else UDF101 end,

                  SKU2       = case when @vCol = 2 then @vSKU      else SKU2   end,
                  SKUDescription2
                             = case when @vCol = 2 then @vSKUDescription
                                                                   else SKUDescription2 end,
                  Quantity2  = case when @vCol = 2 then @vQuantity else Quantity2 end,
                  UDF12      = case when @vCol = 2 then @vUDF1     else UDF12  end,
                  UDF22      = case when @vCol = 2 then @vUDF2     else UDF22  end,
                  UDF32      = case when @vCol = 2 then @vUDF3     else UDF32  end,
                  UDF42      = case when @vCol = 2 then @vUDF4     else UDF42  end,
                  UDF52      = case when @vCol = 2 then @vUDF5     else UDF52  end,
                  UDF62      = case when @vCol = 2 then @vUDF6     else UDF62  end,
                  UDF72      = case when @vCol = 2 then @vUDF7     else UDF72  end,
                  UDF82      = case when @vCol = 2 then @vUDF8     else UDF82  end,
                  UDF92      = case when @vCol = 2 then @vUDF9     else UDF92  end,
                  UDF102     = case when @vCol = 2 then @vUDF10    else UDF102 end,

                  SKU3       = case when @vCol = 3 then @vSKU      else SKU3   end,
                  SKUDescription3
                             = case when @vCol = 3 then @vSKUDescription
                                                                   else SKUDescription3 end,
                  Quantity3  = case when @vCol = 3 then @vQuantity else Quantity3 end,
                  UDF13      = case when @vCol = 3 then @vUDF1     else UDF13  end,
                  UDF23      = case when @vCol = 3 then @vUDF2     else UDF23  end,
                  UDF33      = case when @vCol = 3 then @vUDF3     else UDF33  end,
                  UDF43      = case when @vCol = 3 then @vUDF4     else UDF43  end,
                  UDF53      = case when @vCol = 3 then @vUDF5     else UDF53  end,
                  UDF63      = case when @vCol = 3 then @vUDF6     else UDF63  end,
                  UDF73      = case when @vCol = 3 then @vUDF7     else UDF73  end,
                  UDF83      = case when @vCol = 3 then @vUDF8     else UDF83  end,
                  UDF93      = case when @vCol = 3 then @vUDF9     else UDF93  end,
                  UDF103     = case when @vCol = 3 then @vUDF10    else UDF103 end,

                  SKU4       = case when @vCol = 4 then @vSKU      else SKU4   end,
                  SKUDescription4
                             = case when @vCol = 4 then @vSKUDescription
                                                                   else SKUDescription4 end,
                  Quantity4  = case when @vCol = 4 then @vQuantity else Quantity4 end,
                  UDF14      = case when @vCol = 4 then @vUDF1     else UDF14  end,
                  UDF24      = case when @vCol = 4 then @vUDF2     else UDF24  end,
                  UDF34      = case when @vCol = 4 then @vUDF3     else UDF34  end,
                  UDF44      = case when @vCol = 4 then @vUDF4     else UDF44  end,
                  UDF54      = case when @vCol = 4 then @vUDF5     else UDF54  end,
                  UDF64      = case when @vCol = 4 then @vUDF6     else UDF64  end,
                  UDF74      = case when @vCol = 4 then @vUDF7     else UDF74  end,
                  UDF84      = case when @vCol = 4 then @vUDF8     else UDF84  end,
                  UDF94      = case when @vCol = 4 then @vUDF9     else UDF94  end,
                  UDF104     = case when @vCol = 4 then @vUDF10    else UDF104 end,

                  SKU5       = case when @vCol = 5 then @vSKU      else SKU5   end,
                  SKUDescription5
                             = case when @vCol = 5 then @vSKUDescription
                                                                   else SKUDescription5 end,
                  Quantity5  = case when @vCol = 5 then @vQuantity else Quantity5 end,
                  UDF15      = case when @vCol = 5 then @vUDF1     else UDF15  end,
                  UDF25      = case when @vCol = 5 then @vUDF2     else UDF25  end,
                  UDF35      = case when @vCol = 5 then @vUDF3     else UDF35  end,
                  UDF45      = case when @vCol = 5 then @vUDF4     else UDF45  end,
                  UDF55      = case when @vCol = 5 then @vUDF5     else UDF55  end,
                  UDF65      = case when @vCol = 5 then @vUDF6     else UDF65  end,
                  UDF75      = case when @vCol = 5 then @vUDF7     else UDF75  end,
                  UDF85      = case when @vCol = 5 then @vUDF8     else UDF85  end,
                  UDF95      = case when @vCol = 5 then @vUDF9     else UDF95  end,
                  UDF105     = case when @vCol = 5 then @vUDF10    else UDF105 end,

                  SKU6       = case when @vCol = 6 then @vSKU      else SKU6   end,
                  SKUDescription6
                             = case when @vCol = 6 then @vSKUDescription
                                                                   else SKUDescription6 end,
                  Quantity6  = case when @vCol = 6 then @vQuantity else Quantity6 end,
                  UDF16      = case when @vCol = 6 then @vUDF1     else UDF16  end,
                  UDF26      = case when @vCol = 6 then @vUDF2     else UDF26  end,
                  UDF36      = case when @vCol = 6 then @vUDF3     else UDF36  end,
                  UDF46      = case when @vCol = 6 then @vUDF4     else UDF46  end,
                  UDF56      = case when @vCol = 6 then @vUDF5     else UDF56  end,
                  UDF66      = case when @vCol = 6 then @vUDF6     else UDF66  end,
                  UDF76      = case when @vCol = 6 then @vUDF7     else UDF76  end,
                  UDF86      = case when @vCol = 6 then @vUDF8     else UDF86  end,
                  UDF96      = case when @vCol = 6 then @vUDF9     else UDF96  end,
                  UDF106     = case when @vCol = 6 then @vUDF10    else UDF106 end,

                  SKU7       = case when @vCol = 7 then @vSKU      else SKU7   end,
                  SKUDescription7
                             = case when @vCol = 7 then @vSKUDescription
                                                                   else SKUDescription7 end,
                  Quantity7  = case when @vCol = 7 then @vQuantity else Quantity7 end,
                  UDF17      = case when @vCol = 7 then @vUDF1     else UDF17  end,
                  UDF27      = case when @vCol = 7 then @vUDF2     else UDF27  end,
                  UDF37      = case when @vCol = 7 then @vUDF3     else UDF37  end,
                  UDF47      = case when @vCol = 7 then @vUDF4     else UDF47  end,
                  UDF57      = case when @vCol = 7 then @vUDF5     else UDF57  end,
                  UDF67      = case when @vCol = 7 then @vUDF6     else UDF67  end,
                  UDF77      = case when @vCol = 7 then @vUDF7     else UDF77  end,
                  UDF87      = case when @vCol = 7 then @vUDF8     else UDF87  end,
                  UDF97      = case when @vCol = 7 then @vUDF9     else UDF97  end,
                  UDF107     = case when @vCol = 7 then @vUDF10    else UDF107 end,

                  SKU8       = case when @vCol = 8 then @vSKU      else SKU8   end,
                  SKUDescription8
                             = case when @vCol = 8 then @vSKUDescription
                                                                   else SKUDescription8 end,
                  Quantity8  = case when @vCol = 8 then @vQuantity else Quantity8 end,
                  UDF18      = case when @vCol = 8 then @vUDF1     else UDF18  end,
                  UDF28      = case when @vCol = 8 then @vUDF2     else UDF28  end,
                  UDF38      = case when @vCol = 8 then @vUDF3     else UDF38  end,
                  UDF48      = case when @vCol = 8 then @vUDF4     else UDF48  end,
                  UDF58      = case when @vCol = 8 then @vUDF5     else UDF58  end,
                  UDF68      = case when @vCol = 8 then @vUDF6     else UDF68  end,
                  UDF78      = case when @vCol = 8 then @vUDF7     else UDF78  end,
                  UDF88      = case when @vCol = 8 then @vUDF8     else UDF88  end,
                  UDF98      = case when @vCol = 8 then @vUDF9     else UDF98  end,
                  UDF108     = case when @vCol = 8 then @vUDF10    else UDF108 end,

                  SKU9       = case when @vCol = 9 then @vSKU      else SKU9   end,
                  SKUDescription9
                             = case when @vCol = 9 then @vSKUDescription
                                                                   else SKUDescription9 end,
                  Quantity9  = case when @vCol = 9 then @vQuantity else Quantity9 end,
                  UDF19      = case when @vCol = 9 then @vUDF1     else UDF19  end,
                  UDF29      = case when @vCol = 9 then @vUDF2     else UDF29  end,
                  UDF39      = case when @vCol = 9 then @vUDF3     else UDF39  end,
                  UDF49      = case when @vCol = 9 then @vUDF4     else UDF49  end,
                  UDF59      = case when @vCol = 9 then @vUDF5     else UDF59  end,
                  UDF69      = case when @vCol = 9 then @vUDF6     else UDF69  end,
                  UDF79      = case when @vCol = 9 then @vUDF7     else UDF79  end,
                  UDF89      = case when @vCol = 9 then @vUDF8     else UDF89  end,
                  UDF99      = case when @vCol = 9 then @vUDF9     else UDF99  end,
                  UDF109     = case when @vCol = 9 then @vUDF10    else UDF109 end,

                  SKU10      = case when @vCol = 10 then @vSKU      else SKU10  end,
                  SKUDescription10
                             = case when @vCol = 10 then @vSKUDescription
                                                                   else SKUDescription10 end,
                  Quantity10 = case when @vCol = 10 then @vQuantity else Quantity10 end,
                  UDF110     = case when @vCol = 10 then @vUDF1     else UDF110 end,
                  UDF210     = case when @vCol = 10 then @vUDF2     else UDF210 end,
                  UDF310     = case when @vCol = 10 then @vUDF3     else UDF310 end,
                  UDF410     = case when @vCol = 10 then @vUDF4     else UDF410 end,
                  UDF510     = case when @vCol = 10 then @vUDF5     else UDF510 end,
                  UDF610     = case when @vCol = 10 then @vUDF6     else UDF610 end,
                  UDF710     = case when @vCol = 10 then @vUDF7     else UDF710 end,
                  UDF810     = case when @vCol = 10 then @vUDF8     else UDF810 end,
                  UDF910     = case when @vCol = 10 then @vUDF9     else UDF910 end,
                  UDF1010    = case when @vCol = 10 then @vUDF10    else UDF1010 end
              where (TaskId     = @vTaskId    ) and
                    (PickTicket = @vPickTicket) and
                    (EmpNo      = @vEmpNo     ) and
                    (EmpName    = @vEmpName   ) and
                    (LabelSNo   = @vLabelSNo  );
            end
        end --while (@vRecordId < @vPackDetailCount)
    end -- while Employees To Process

  /* Update account number here */
  update LC
  set LC.Account = OH.Account
  from @LabelContents LC
    join OrderHeaders OH on (LC.PickTicket = OH.PickTicket);

  /* Update NumInnerPacksDesc which is the combination of SeqNo of label and num labels per employee */
  update LC
  set LC.NumInnerPacksDesc = 'Innerpack ' + cast(LabelSNo as varchar) + ' of ' + cast(NumLabels as varchar)
  from @LabelContents LC
    inner join (select  max(LabelSNo) as NumLabels, EmpNo from @LabelContents group by EmpNo) SQ on (LC.EmpNo = SQ.EmpNo);

  /* Return result dataset */
  select * from @LabelContents
end /* pr_Tasks_GetEmployeeLabelData */

Go
