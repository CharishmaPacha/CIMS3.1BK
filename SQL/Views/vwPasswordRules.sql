/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/01  NB      Revised names to use _ (underscore) instead of .(dot),
                        Added Use_Repeat and Repeat_Limit (CIMSV3-787)
  2021/09/24  NB      Initial Revision(CIMSV3-787)
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPasswordRules') is not null
  drop View dbo.vwPasswordRules;
Go

Create View dbo.vwPasswordRules
As
select PasswordPolicy,
       BusinessUnit,
       MustHave_Lower,
       MustHave_Upper,
       MustHave_Number,
       MustHave_Symbol,
       Use_Exceptions,
       Use_Length,
       MustHave_Length,
       Use_Expire,
       Expiry_Days,
       Use_Failed,
       Failed_Max,
       Use_Reuse,
       Reuse_Limit,
       Use_Repeat,
       Repeat_Limit,
       Use_Unlock,
       Unlock_Minutes
from (
       select PolicyRule, PolicyData, PasswordPolicy, BusinessUnit
       from PasswordRules
      ) As PasswordPolicyRules
      PIVOT
      (
        max(PolicyData) for PolicyRule in (MustHave_Lower,
                                           MustHave_Upper,
                                           MustHave_Number,
                                           MustHave_Symbol,
                                           Use_Exceptions,
                                           Use_Length,
                                           MustHave_Length,
                                           Use_Expire,
                                           Expiry_Days,
                                           Use_Failed,
                                           Failed_Max,
                                           Use_Reuse,
                                           Reuse_Limit,
                                           Use_Repeat,
                                           Repeat_Limit,
                                           Use_Unlock,
                                           Unlock_Minutes)
      ) As PasswordPolicyRulesPivot;

Go