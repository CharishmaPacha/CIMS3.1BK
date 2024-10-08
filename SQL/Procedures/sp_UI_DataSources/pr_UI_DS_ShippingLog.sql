/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/16  OK      pr_UI_DS_ShippingLog: Changed to generic way as it will have custom proc in respective clients (HA-2264)
  2020/03/13  AY      pr_UI_DS_ShippingLog: developed to return dataset (HA-2264)
  2020/07/15  KBB     pr_UI_DS_ShippingLog: Added new Procedure (HA-1093)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_UI_DS_ShippingLog') is not null
  drop Procedure pr_UI_DS_ShippingLog;
Go
/*------------------------------------------------------------------------------
  Proc pr_UI_DS_ShippingLog: Datasource for ShippingLog.
   The data is returned via #ResultDataSet
-------------------------------------------------------------------------------*/
Create Procedure pr_UI_DS_ShippingLog
  (@xmlInput     XML,
   @OutputXML    TXML = null output)
as
  declare @vBusinessUnit  TBusinessUnit,
          @vUserId        TUserId,

          @ttShippingLog  TShippingLogData;
begin /* pr_UI_DS_ShippingLog */

  /* Read the inputs for procedure */
  select @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @vUserId        = Record.Col.value('(SessionInfo/UserId)[1]',       'TUserName')
  from @xmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlInput = null ));

  /* #ResultDataSet of type TShippingLogData should have been created by caller */
  if (object_id('tempdb..#ResultDataSet')) is null return;

  /* Get all the Loads+Orders to summarize */
  select LO.OrderId, LO.LoadId, LO.CustPO, LO.ShipToStore, LO.ShipToId, LO.LPNsAssigned NumLPNs,
         LO.CancelDate, coalesce(LO.CustPO, '') + '-' + coalesce(LO.ShipToStore, '') as GroupCriteria
  into #LoadOrders
  from vwLoadOrders LO join Loads LD on LO.LoadId = LD.LoadId
  where (LD.Archived = 'N')

  /* Insert Load info */
  insert into #ResultDataSet (LoadId, LoadNumber, LoadType, LoadTypeDesc, LoadStatus, LoadStatusDesc, RoutingStatusDesc, ClientLoad, ShipFrom, Warehouse,
                              ShipVia, ShipViaDesc, Account, AccountName, DesiredShipDate, AppointmentDatetime, ApptTime,
                              ShipToStore, ShipToId, GroupCriteria,
                              LPNsAssigned, BusinessUnit, Archived)
    select LD.LoadId, LD.LoadNumber, LD.LoadType, LD.LoadTypeDesc, LD.Status, LD.LoadStatusDesc, LD.RoutingStatusDescription, LD.ClientLoad, LD.ShipFrom, LD.FromWarehouse,
           LD.ShipVia, LD.ShipViaDescription, LD.Account, LD.AccountName, LD.DesiredShipDate, LD.AppointmentDateTime, null, --right(convert(varchar, LD.AppointmentDatetime, 0), 7),
           LO.ShipToStore, LD.ShipToId, LO.GroupCriteria,
           LO.NumLPNs, LD.BusinessUnit, LD.Archived
    from #LoadOrders LO join vwLoads LD on LO.LoadId = LD.LoadId;

  /* Get the list of CustPOs for each Load */
  with LoadPOs as (
       select LO1.GroupCriteria, String_Agg(LO1.CustPO, ', ') CustPOs,
              count(distinct CustPO) NumPOs
       from #LoadOrders LO1
       group by LO1.GroupCriteria
   )
  update RS
  set RS.Count1      = NumPOs
  from #ResultDataSet RS join LoadPOS LP on RS.GroupCriteria = LP.GroupCriteria;

  update RS
  set ShipFromName = LU.LookupDescription
  from #ResultDataSet RS join vwLookups LU on (LU.LookUpCategory = 'Warehouse') and (RS.ShipFrom = LU.LookUpcode);

end  /* pr_UI_DS_ShippingLog */

Go
