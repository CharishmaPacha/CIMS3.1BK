/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/23  VS/OK   Import_GenerateImportBatchesOH, Import_GenerateImportBatchesOD added steps to generate the importbatches for IOH and IOD (CIMSV3-1604)
  2021/03/09  VS      Initial revision (HA-3048)
------------------------------------------------------------------------------*/

/*******************************************************************************
 *  General Info needed to create jobs:
 ********** Do not add this file to _Init_All.sql file **********
 *** We cannot use user defined datatypes for SQL Server agent procedures hence use only system defined datatypes

 *    OnSuccessAction & OnFailureAction: The action to perform if the step succeeds
                                             1 = Quit with success
                                             2 = Quit with failure
                                             3 = Go to next step
                                             4 = Go to step on_success_step_id

 *    FreqType     : Indicates when the job is to be executed; 4 - daily, 8 - weekly, 16 - monthly, 128 - when idle.

 *    FreqInterval : Interval at which the job runs.
                     if type = 4, this is in days,
                     if type = 8 (weekly) then this is the days of the week, 1 - Sunday, 2 - Mon, 4 - Tue, 8 - Wed, .... 64 - Sat
                     if type = 16, this is day of the month

 *    FreqSubDayType : Specifies the units for frequency_subday_interval and it is defaulted to '4'
                         1 = At Specified Time
                         4 = Minutes
                         8 = Hours

 *    FreqSubDayInterval : Number of FreqSubDayType periods to occur between each execution of the job, with a default of 0.
                          0 = only once a day
                          1 = runs every minute
                          2 = runs every 2 minutes
                          5 = runs every 5 minutes and so on

 *    StartTime    : Time on any day to begin job execution, it is of integer datatype
                       and format should be like HHMMSS on a 24-hour clock
 *    EndTime      : Time on any day to end job execution , it is of integer datatype
                       and format should be like HHMMSS on a 24-hour clock
*******************************************************************************/

Go

declare @vJobId                  uniqueidentifier,
        @vJobName                nvarchar(128),
        @vJobDescription         nvarchar(512),
        @vCommand                nvarchar(max),
        @vBusinessUnit           nvarchar(30) = 'HA',
        @vJobEnabled             tinyint,
        @vFreqType               int,
        @vFreqInterval           int,
        @vFreqSubDayType         int,
        @vFreqSubDayInterval     int,
        @vFreqRelativeInterval   int,
        @vFreqRecurrenceFactor   int,
        @vStartTime              int,
        @vEndTime                int;

declare @ttJobStepsInfo       TJobStepsInfo;

/*******************************************************************************
  Functional Process Jobs
*******************************************************************************/
select @vJobName            = '~DBName~_Import_GenerateImportBatches',
       @vJobDescription     = 'Generate Batches for unprocessed import Records CIMSDE to CIMS',
      -- All other parameters are default params to run job all day long for every 5 minutes
       @vJobEnabled         = 1,
       @vFreqType           = null,  @vFreqInterval       = 1,
       @vFreqSubDayType     = null,  @vFreqSubDayInterval = null,
       @vStartTime          = null,  @vEndTime            = null;

insert into @ttJobStepsInfo
       (StepName,                                   Command)
values ('~DBName~_Import_GenerateImportBatchesSKU', 'exec pr_Imports_DE_GenerateBatchesForImportRecords ''ImportSKUs'', ''SKU'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_GenerateImportBatchesOH',  'exec pr_Imports_DE_GenerateBatchesForImportRecords ''ImportOrderHeaders'', ''PickTicket'', ''~BU~'', ''cIMSAgent'''),
       ('~DBName~_Import_GenerateImportBatchesOD',  'exec pr_Imports_DE_GenerateBatchesForImportRecords ''ImportOrderDetails'', ''concat_ws('', IOD.PickTicket, IOD.HostOrderLine, IOD.SKU)'', ''~BU~'', ''cIMSAgent''');

exec pr_Jobs_Setup @vJobName, @vJobDescription, @vJobEnabled, @ttJobStepsInfo, @vBusinessUnit,
                   @vFreqType, @vFreqInterval, @vFreqSubDayType, @vFreqSubDayInterval,
                   @vStartTime, @vEndTime;
                   
Go
