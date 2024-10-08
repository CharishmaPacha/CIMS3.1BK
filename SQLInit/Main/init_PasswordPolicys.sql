/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/01  NB      PasswordRules: Revised names to use _ (underscore) instead of .(dot),
                        Added Use_Repeat and Repeat_Limit (CIMSV3-787)
  2020/08/12  RKC     Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  PasswordPolicy Types
 -----------------------------------------------------------------------------*/
declare @UserTypes TLookUpsTable, @LookUpCategory TCategory = 'PasswordPolicy';

insert into @UserTypes
       (LookUpCode,   LookUpDescription,         Status)
values ('RF',         'RF',                      'A'),
       ('WEB',        'Web',                     'A');

exec pr_LookUps_Setup @LookUpCategory, @UserTypes, @LookUpCategoryDesc = 'Password Policy';

Go

/*------------------------------------------------------------------------------*/
/* Password Policys rules */
/*------------------------------------------------------------------------------*/
delete from PasswordRules;

insert into PasswordRules
            (PolicyRule,                PolicyData,     PasswordPolicy, Status,  BusinessUnit)
/* Password Policys For RF */
      select 'Failed_Max',              '6',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'MustHave_Length',         '6',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'MustHave_Lower',          '0',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'MustHave_Number',         '1',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'MustHave_Symbol',         '0',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'MustHave_Upper',          '0',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'Reuse_Limit',             '6',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'Repeat_Limit',            '2',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'Unlock_Minutes',          '10',           'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Exceptions',          '1',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Expire',              '1',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Failed',              '1',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Length',              '1',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Reuse',               '1',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Repeat',              '1',            'RF',           'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Unlock',              'NA',           'RF',           'A',     BusinessUnit from vwBusinessUnits

/* Password Policys For WEB */
union select 'Failed_Max',              '3',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'MustHave_Length',         '8',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'MustHave_Lower',          '1',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'MustHave_Number',         '1',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'MustHave_Symbol',         '1',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'MustHave_Upper',          '1',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'Reuse_Limit',             '12',           'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'Repeat_Limit',            '2',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'Unlock_Minutes',          '10',           'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Exceptions',          '1',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Expire',              '1',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Failed',              '1',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Length',              '1',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Reuse',               '1',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Repeat',              '1',            'WEB',          'A',     BusinessUnit from vwBusinessUnits
union select 'Use_Unlock',              '1',            'WEB',          'A',     BusinessUnit from vwBusinessUnits

Go

/*------------------------------------------------------------------------------*/
/* Password Exceptions */
/*------------------------------------------------------------------------------*/
delete from PasswordExceptions;

insert into PasswordExceptions
             (PasswordPattern,    Status, BusinessUnit)
      select '111',               'A',    BusinessUnit from vwBusinessUnits
union select '222',               'A',    BusinessUnit from vwBusinessUnits
union select '333',               'A',    BusinessUnit from vwBusinessUnits
union select '444',               'A',    BusinessUnit from vwBusinessUnits
union select '555',               'A',    BusinessUnit from vwBusinessUnits
union select '666',               'A',    BusinessUnit from vwBusinessUnits
union select '777',               'A',    BusinessUnit from vwBusinessUnits
union select '888',               'A',    BusinessUnit from vwBusinessUnits
union select '999',               'A',    BusinessUnit from vwBusinessUnits
union select '000',               'A',    BusinessUnit from vwBusinessUnits
union select '123',               'A',    BusinessUnit from vwBusinessUnits
union select '234',               'A',    BusinessUnit from vwBusinessUnits
union select 'abc',               'A',    BusinessUnit from vwBusinessUnits
union select 'xyz',               'A',    BusinessUnit from vwBusinessUnits
union select 'password',          'A',    BusinessUnit from vwBusinessUnits
union select 'hello',             'A',    BusinessUnit from vwBusinessUnits
union select 'admin',             'A',    BusinessUnit from vwBusinessUnits
union select 'day',               'A',    BusinessUnit from vwBusinessUnits -- prevent days of week

Go
