/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/24  RV      pr_UI_DS_LocationsToReplenish: Made changes to create temp tables and insert messages to show in V3 (HA-936)
  2020/05/27  NB      Added pr_UI_DS_LocationsToReplenish(HA-368)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_UI_DS_LocationsToReplenish') is not null
  drop Procedure pr_UI_DS_LocationsToReplenish;
Go
/*------------------------------------------------------------------------------
  Prod pr_UI_DS_LocationsToReplenish: Datasource procedure for Manage Replenishments page.
   The data is returned via #ResultDataSet
------------------------------------------------------------------------------*/
Create Procedure pr_UI_DS_LocationsToReplenish
  (@xmlInput     XML,
   @OutputXML    TXML = null output)
as
  declare @vLocationsInfo     TXML,
          @vBusinessUnit      TBusinessUnit,
          @vUserId            TUserId,
          @vConfirmMessage    TMessageName;

  declare @ttLocationsToReplenish TLocationsToReplenishData, -- Table Variable for output
          @ttResultMessages       TResultMessagesTable,
          @ttResultData           TNameValuePairs;
begin /* pr_UI_DS_LocationsToReplenish */
  /* Read the inputs needed for pr_Replenish_LocationsToReplenish procedure */
  select @vBusinessUnit  = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @vUserId        = Record.Col.value('(SessionInfo/UserId)[1]',       'TUserName')
  from @xmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlInput = null ));

  /* Build the inputs for pr_Replenish_LocationsToReplenish procedure */
  select @vLocationsInfo = (select Record.Col.value('(Data/ReplenishType)[1]', 'TStatus'    ) as ReplenishType,
                                   Record.Col.value('(Data/PutawayZone)[1]',   'TLookUpCode') as PutawayZone,
                                   Record.Col.value('(Data/PickZone)[1]',      'TLookUpCode') as PickZone,
                                   Record.Col.value('(Data/StorageType)[1]',   'TTypeCode'  ) as StorageType,
                                   Record.Col.value('(Data/SKU)[1]',           'TSKU'       ) as SKU
                            from @xmlInput.nodes('/Root') as Record(Col)
                            --OPTION ( OPTIMIZE FOR ( @vInputXML = null )) This does not work inside the paranthesis
                            for xml raw('SELECTIONS'), elements, Root('LOCATIONSTOREPLENISH'));

  exec pr_Replenish_LocationsToReplenish @vLocationsInfo, @vBusinessUnit, @vUserId, @vConfirmMessage output, 'Y' /* Save To TempTable */;

  /* Build the Info  xml from the temp table */
  if (@vConfirmMessage is not null)
    insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, @vConfirmMessage;
end  /* pr_UI_DS_LocationsToReplenish */

Go
