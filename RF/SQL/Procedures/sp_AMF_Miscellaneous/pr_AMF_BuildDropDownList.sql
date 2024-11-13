/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/11  RV      pr_AMF_BuildDropDownList: Initial Version (FBV3-1337)
  if object_id('dbo.pr_AMF_BuildDropDownList') is null
  exec('Create Procedure pr_AMF_BuildDropDownList as begin return; end')
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_BuildDropDownList') is not null
  drop Procedure pr_AMF_BuildDropDownList;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_BuildDropDownList:
  This procedure build the xml to generate dropdown list in RF. This proc accepts
  hash table name with columns name, vlaue, Reference1, Reference2 and so on.
  In some cases after select the drop down need to show and send data back to the SQL,
  so we are using References.
  output:
  <RootNode>
    <OptionDetail>
      <Name>411-A/R Adj-Reserve</LookUpDisplayDescription>
      <Value>411</LookUpCode>
      <Reference1></Reference1>
      <Reference2></Reference2>
      <Reference3></Reference3>
      <Reference4></Reference4>
      <Reference5></Reference5>
    </OptionDetail>
    <OptionDetail>
      <Name>504-Bundle Build</LookUpDisplayDescription>
      <Value>504</LookUpCode>
      <Reference1></Reference1>
      <Reference2></Reference2>
      <Reference3></Reference3>
      <Reference4></Reference4>
      <Reference5></Reference5>
    </OptionDetail>
    <OptionDetail>
      <Name>202-Cannot find Units</LookUpDisplayDescription>
      <Value>202</LookUpCode>
      <Reference1></Reference1>
      <Reference2></Reference2>
      <Reference3></Reference3>
      <Reference4></Reference4>
      <Reference5></Reference5>
    </OptionDetail>
           ....
           ....
    <OptionDetail>
      <Name>506-Concealed Damage</LookUpDisplayDescription>
      <Value>506</LookUpCode>
      <Reference1></Reference1>
      <Reference2></Reference2>
      <Reference3></Reference3>
      <Reference4></Reference4>
      <Reference5></Reference5>
    </OptionDetail>
  </RootNode>
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_BuildDropDownList
  (@HashTableName       TName,
   @RootNode            TDescription,
   @DefaultPrompt       TDescription,
   @BusinessUnit        TBusinessUnit,
   @outputXML           TXML        = null output)
as
  declare @vxmlLookupCodes    xml,
          @vLookupCodesXML    TXML,
          @vFirstNode         TXML,
          @vSelectSQL         TSQL;
begin /* pr_AMF_BuildDropDownList */
  /* The first node is to prompt user to select a value and to later validate if the
     user has selected a value */
  select @vFirstNode = dbo.fn_XMLNode('OptionDetail',
                         dbo.fn_XMLNode('Name',  coalesce(@DefaultPrompt, 'Select')) +
                         dbo.fn_XMLNode('Value', '*'));

  select @vSelectSQL = N'set @outputXML = (select Name, Value, Reference1, Reference2, Reference3, Reference4, Reference5
                                           from #'+ @HashTableName +'
                                           order by RecordId
                                           for XML Raw(''OptionDetail''), elements)';

  execute sp_executesql @vSelectSQL, N'@outputXML TXML output', @outputXML output;

  select @outputXML = dbo.fn_XMLNode(@RootNode, @vFirstNode + @outputXML);
end /* pr_AMF_BuildDropDownList */

Go
