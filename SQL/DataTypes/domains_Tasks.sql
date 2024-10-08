/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/10  TK      TTaskDetailsInfoTable: Added PickedBy (CID-1704)
  2020/11/30  TK      TTaskDetailsInfoTable: Added FromLPNType, TDUnitsToPick & Reason (CID-1545)
  2020/10/01  TK      Added TPickMethod (CID-1489)
  2020/08/04  TK      TTaskInfoTable: Added CartType (HA-1137)
  2020/06/10  TK      TTaskDetailsInfoTable: Added InventoryClasses (HA-880)
  2020/04/26  TK      TTaskInfoTable: Added DestLocationId (HA-86)
  2020/04/16  TK      TTaskInfoTable: Added Processed flag (HA-171)
  2019/08/25  TK      TTaskInfoTable: Added InnerPackWeight and InnerPackVolume
                      TTaskBuildCriteria: TDCategory1 to 5 and UDF1 to 5 (CID-931)
  2019/05/15  SV      TTaskDetailsInfoTable: Added CoO (CID-135)
  2019/03/22  TK      TTaskDetailsInfoTable: Added FromLPNOwnership (S2GCA-534)
  2019/01/31  TK      TTaskInfoTable: Added UnitsPerInnerpack (S2GMI-79)
  2019/01/27  TK      TTaskDetailsInfoTable: Added FromLDUnitsPerPackage (S2GMI-79)
  2018/10/17  AY      TTaskInfoTable: Added PackingGroup (S2GCA-383)
  2018/08/02  AY      TPickSequence: Added to determine the sequence to pick the tasks (OB2-396)
  2018/04/23  TK      TTaskInfoTable: Added task detail MergeCriteria fields (S2G-493)
  2018/03/15  TK      TTaskInfoTable: Added TDStatus, TDInnerpacks & TDQuantity (S2G-423)
  2018/03/11  TK      TTaskInfoTable: Added TDCategory & UDF fields ()
  2018/02/04  TK      Added TDependencies (S2G-179)
  2017/01/23  TK      TTaskInfoTable: Added TempLabelDetailId field (HPI-1274)
  2016/11/11  VM      TTaskDetailsInfoTable: Added (HPI-993)
  2016/11/01  YJ      TTaskInfoTable: Added IsLabelGenerated, IsTaskAllocated (CIMS-1146)
  2016/06/25  AY      TTaskInfoTable: Added DestLocationType, TaskId, TaskDetailId (HPI-162)
  2015/07/24  TK      TTaskInfoTable: Added PalletId(FB-265)
  2015/05/02  TK      TTaskInfoTable: Added CartonType, TempLabel
  2014/04/19  TD      Added TLPNTasksTable.
  2014/04/10  TD      Added DestZone, DestLocation.
  2014/04/01  TD      TTaskInfoTable: Added PickType,LocationType, LPNType,
                        StorageType.
  2011/12/19  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/* Task */
Create Type TTaskBatchNo               from varchar(10);        Grant References on Type:: TTaskBatchNo               to public;
Create Type TPickGroup                 from varchar(10);        Grant References on Type:: TPickGroup                 to public;
Create Type TPickMethod                from varchar(20);        Grant References on Type:: TPickMethod                 to public;
Create Type TPickSequence              from varchar(150);       Grant References on Type:: TPickSequence              to public;

Go
