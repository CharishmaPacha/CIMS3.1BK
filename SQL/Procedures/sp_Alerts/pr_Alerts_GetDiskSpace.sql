/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/16  SK      pr_Alerts_GetDiskSpace: Enhancements (CIMSV3-1815)
  2018/12/22  RIA     pr_Alerts_GetDiskSpace: New procedure to get drive space (OB2-673)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_GetDiskSpace') is not null
  drop Procedure pr_Alerts_GetDiskSpace;
Go
/*------------------------------------------------------------------------------
  pr_GetDiskSpace: This procedure is used to get available disk space
                   and then based on the space limit decide the support
                   email to be sent to
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_GetDiskSpace
 (@BusinessUnit     TBusinessUnit,
  @ReturnDataSet    TFlags    = 'N',
  @EmailIfNoAlert   TFlags    = 'N')
as
  declare  @vMachineName              sql_variant,
           @vEmailSubject             TDescription,
           @vAlertCategory            TCategory,
           @vUpperLimitForYellowAlert TInteger,
           @vUpperLimitForRedAlert    TInteger,
           @vServerName               TName,
           @vsql                      nvarchar(512);

  declare @ttDiskSpace table (line varchar(512));

  declare @ttAlertDiskspace as Table (AlertLevel          TDescription,
                                      DriveName           TName,
                                      Description         TDescription,
                                      TotalCapacityGB     TInteger,
                                      FreeSpaceGB         TInteger,
                                      [FreeSpace%]        TInteger,
                                      TargetFreeSpaceGB   TInteger);
begin
  SET NOCOUNT ON;

  select @vAlertCategory  = 'Alert_DBA', -- default value
         @vMachineName    = SERVERPROPERTY('MachineName'),
         @vServerName     = @@SERVERNAME,
         @vEmailSubject   = @BusinessUnit +' '+ convert(varchar, @vMachineName) +' Alert: Drive Space';

  /* Get hash tables */
  select * into #AlertDiskSpace from @ttAlertDiskspace;
  alter table #AlertDiskSpace add UsedSpaceGB as (TotalCapacityGB - FreeSpaceGB);
  alter table #AlertDiskSpace add MaxSpaceUsedGB integer;

  /* Get control value */
  select @vUpperLimitForYellowAlert = dbo.fn_Controls_GetAsInteger('DBA', 'DiskSpaceYellowLimit', 50, @BusinessUnit, 'cimsadmin'),
         @vUpperLimitForRedAlert    = dbo.fn_Controls_GetAsInteger('DBA', 'DiskSpaceRedLimit',    25, @BusinessUnit, 'cimsadmin');

  /* Get disk spaces from system using powershell command */
  if (charindex('\', @vServerName) > 0)
     select @vServerName = substring(@vServerName, 1, charindex('\',@vServerName)-1);

  select @vsql = 'powershell.exe -c "Get-WmiObject -ComputerName ' + quotename(@vServerName,'''') + ' -Class Win32_Volume -Filter ''DriveType = 3'' | select name,capacity,freespace | foreach{$_.name+''|''+$_.capacity/1048576+''%''+$_.freespace/1048576+''*''}"'

  insert @ttDiskSpace (line)
    exec xp_cmdshell @vsql;

  insert into #AlertDiskSpace (DriveName, TotalCapacityGB, FreeSpaceGB, [FreeSpace%])
    select replace(rtrim(ltrim(substring(line,1,charindex('|',line) -1))), ':\', ''),
           round(cast(rtrim(ltrim(substring(line, charindex('|',line)+1,
                                            (charindex('%',line) -1)-charindex('|',line)) )) as float)/1024.0,0),
           round(cast(rtrim(ltrim(substring(line,charindex('%',line)+1,
                                            (charindex('*',line) -1)-charindex('%',line)) )) as float)/1024.0,0),
           cast(((round(cast(rtrim(ltrim(substring(line,charindex('%',line)+1,
                                                   (charindex('*',line) -1)-charindex('%',line)) )) as float),0)))*100 /
                 (round(cast(rtrim(ltrim(substring(line,charindex('|',line)+1,
                                                   (charindex('%',line) -1)-charindex('|',line)) )) as float),0)) as int)
    from @ttDiskSpace
    where (line like '[A-Z][:]%');

  /* Update all other info concerning the drive taken from disk configurations
     Here we update Alert level based on the disk space condition */
  update TT
  set TT.Description       = coalesce(DC.Description, 'Other'),
      TT.TargetFreeSpaceGB = coalesce(DC.MinFreeLimit, @vUpperLimitForYellowAlert),
      TT.AlertLevel        = case
                               when TT.FreeSpaceGB < coalesce(DC.LowFreeLimit, @vUpperLimitForRedAlert) then 'Red'
                               when TT.FreeSpaceGB < coalesce(DC.MinFreeLimit, @vUpperLimitForYellowAlert) then 'Yellow'
                               else 'Green'
                   end,
      TT.MaxSpaceUsedGB    = case
                               when TT.UsedSpaceGB > coalesce(DC.MaxSpaceUsed, 0) then TT.UsedSpaceGB
                               else coalesce(DC.MaxSpaceUsed, 0)
                             end
  from #AlertDiskSpace TT
    left join DBAConfigs DC on TT.DriveName = DC.Drive and DC.ControlCategory = 'DriveSpace' and DC.Status = 'A' /* Active */;

  /* Update based table in case the space used is greater than the last entry */
  update DC
  set DC.MaxSpaceUsed = case
                          when TT.UsedSpaceGB > coalesce(DC.MaxSpaceUsed, 0) then TT.UsedSpaceGB
                          else DC.MaxSpaceUsed
                        end
  from DBAConfigs DC
    join #AlertDiskSpace TT on DC.Drive = TT.DriveName and DC.ControlCategory = 'DriveSpace' and DC.Status = 'A' /* Active */;

  /* Evaluate whether to exit or the right recipient based on the alert type
     Send to Support group if there is at least 1 Red flag
     Send to DBA group if there is at least 1 Yellow flag */
  if (exists(select * from #AlertDiskSpace where AlertLevel = 'Red'))
    select @vAlertCategory = 'Alert_CIMSSupport';
  /* This does not apply for disk alert as we will always have data to be sent */
  --else
  --/* No major alerts & by default we do not send emails */
  --if (@EmailIfNoAlert = 'N' /* No */)
  --  return(0

  if (@ReturnDataSet = 'Y' /* Yes */)
    select * from #AlertDiskSpace;
  else
    exec pr_Email_SendQueryResults @BusinessUnit  = @BusinessUnit,
                                   @TableName     = '#AlertDiskSpace',
                                   @OrderBy       = 'Order By DriveName',
                                   @AlertCategory = @vAlertCategory,
                                   @EmailSubject  = @vEmailSubject;
end /* pr_Alerts_GetDiskSpace */

Go
