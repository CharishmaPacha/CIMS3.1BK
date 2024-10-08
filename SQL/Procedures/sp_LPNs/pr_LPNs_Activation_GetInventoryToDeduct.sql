/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/15  TK      pr_LPNs_Action_ActivateShipCartons & pr_LPNs_Activation_GetInventoryToDeduct:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Activation_GetInventoryToDeduct') is not null
  drop Procedure pr_LPNs_Activation_GetInventoryToDeduct;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Activation_GetInventoryToDeduct gets the inventory to be deducted to activate
    the ship cartons
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Activation_GetInventoryToDeduct
  (@Operation     TOperation,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @XMLRulesData             TXML;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Execute rules and get the inventory to deduct to activate ship carton */
  exec pr_RuleSets_ExecuteRules 'ActivateShipCartons_GetInventoryToDeduct', @XMLRulesData;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Activation_GetInventoryToDeduct */

Go
