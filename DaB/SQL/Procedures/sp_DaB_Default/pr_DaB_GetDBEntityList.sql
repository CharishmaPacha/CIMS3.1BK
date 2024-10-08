/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies India.  All rights reserved.

  This file shall contain the custoom implementation for Dashboard procedures
  needed for CIMS DB

  Revision History:

  Date        Person  Comments

  2019/03/19  NB      Initial Revision (ADP-121)
------------------------------------------------------------------------------*/


if object_id('dbo.pr_DaB_GetDBEntityList') is not null
  drop Procedure pr_DaB_GetDBEntityList;
Go

/*------------------------------------------------------------------------------
  Procedure pr_DaB_GetDBEntityList:

  Processes the user input, and identifies which particular entities shall be provided
  as available in Dashboard Query Designer
  
  InputXML Structure
  
  <Root>
    <Data>
      <EntityType></EntityType>
      ..
      ..
      ..
    </Data>
    <SessionInfo>
      <UserName></UserName>
      <BusinessUnit></BusinessUnit>
    </SessionInfo>
  </Root>
  
  EntityType : type of database object to return
               valid values are
                 VW - for Views
                 TB - for Tables
                 SP - for Stored Procedures
                 
------------------------------------------------------------------------------*/
Create Procedure pr_DaB_GetDBEntityList
  (@InputXML     TXML)
as
  declare @vInputXML             xml,
          @vDBEntityCategory     TName,
          @vUserName             TName,
          @vBusinessUnit         TBusinessUnit;
          
begin /* pr_DaB_GetDBEntityList */
    /* Extracting data elements from XML. */
  set @vInputXML = convert(xml, @InputXML);

  select @vDBEntityCategory = Record.Col.value('EntityType[1]', 'TName')
  from @vInputXML.nodes('/Root/Data') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vInputXML = null ) );

  select @vUserName       = Record.Col.value('UserName[1]',      'TUserId'),
         @vBusinessUnit   = Record.Col.value('BusinessUnit[1]',  'TBusinessUnit')
  from @vInputXML.nodes('/Root/SessionInfo') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vInputXML = null ) );
  /* TODO TODO TODO 
     Need to implement additional checks and validation to identify specific views, tables or procedures based
     on username and role associated with the user */
  if (@vDBEntityCategory = 'SP')
    begin
      select * from sys.procedures;
    end
  else
  if (@vDBEntityCategory = 'VW')
    begin
      select * from sys.views;
    end  
  else
  if (@vDBEntityCategory = 'TB')
    begin
      select * from sys.tables;
    end  
end /* pr_DaB_GetDBEntityList */

Go
  
