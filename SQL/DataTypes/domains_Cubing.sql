/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved.

  Revision History

  Date        Person  Comments

  2022/03/29  VM      TCartonTypes: Added CartonTypeDisplayDesc (OBV3-223)
  2021/07/06  TK      TCubeCartonDtls: Added InventoryClasses (HA-2923)
  2021/07/05  AY      TCartonTypes: Add Desc & SortSeq (CIMSV3-1524)
  2021/05/21  TK      TCartonDims: Table Type added (HA-2664)
  2021/03/03  AY      TCubeCartonHdr: Added SortOrder (HA-2127)
  2021/02/16  TK      TOrdersToCube: Added NumShipCartons (HA-1964)
  2020/01/11  TK      TCubeCartonHdr & TCubeCartonDtls: Added  UDFs (HA-1899)
  2020/10/06  TK      TDetailsToCube: Added required fields for single carton orders processing
                      TCartonTypes: Added OrderId
                      TOrdersToCube: Initial Revision (HA-1487)
  2020/09/16  TK      TDetailsToCube: Added Dimensions (HA-1446)
  2020/07/24  TK      TCartonTypes & TCubeCartonHdr: Added Dimensions (S2GCA-1202)
  2020/06/05  TK      TDetailsToCube: Added inventory classes (HA-829)
  2020/05/30  TK      TCubeCartonHdr: Added inventory classes (HA-703)
  2020/05/06  TK      TDetailsToCube, TCubeCartonHdrs, TCubeCartonDtls & TCartonTypes:
                        Added fields required for Weight computation and several corrections (HA-298)
  2020/04/15  TK      TDetailsToCube: Added WaveId, WaveNo, TaskId, TaskDetailId, OrderDetailId
                      TDetailsToCube & TCubeCartonDtls TaskRecordId -> UniqueId (HA-171)
  2018/10/29  AY      pr_Cubing_Execute: Cubing shippacks (GNC-2060)
  2019/10/07  TK      TCubeCartonHdr: Added more fields
                      TTaskDetailsToCube: Added Ownership (CID-883)
  2018/10/17  AY      Changes to add PackingGroup for several fields (S2GCA-383)
  2018/09/26  AY      Added PackingGroup for temp tables (GNC-2010)
  2018/06/12  TK      TCubeCartonDtls: Bug fix to consider InnerPackVolume properly (S2G-925)
  2018/03/25  AY      Cubing of IPs issues (S2G-476)
  2018/02/09  TD      TTaskDetailsToCube:Added PickType, CubedIPs, AllocatedIPs (S2G-107)
  2016/09/27  AY      Cubing of nesting items (HPI-GoLive)
  2015/11/05  TK      Added UnitsPerIP field to TTaskDetailsToCube
  2015/07/18  AY      Added TCartonType
  2015/04/20  TK      Initial Revision
------------------------------------------------------------------------------*/
Go

/* Carton Type */
Create Type TCartonType                from varchar(30);        grant references on Type:: TCartonType                to public;
Create Type TCartonGroup               from varchar(100);       grant references on Type:: TCartonGroup                to public;

Go
