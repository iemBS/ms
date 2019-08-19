Do Action on All Tables in DB
Note:
  -Below query confirms "sp_msforeachtable" does not include views:
    exec sp_MSforeachtable 'select TABLE_TYPE from INFORMATION_SCHEMA.TABLES  where TABLE_TYPE = ''VIEW'' AND QUOTENAME(TABLE_SCHEMA) + ''.'' + QUOTENAME(TABLE_NAME) = ''?'''

Main Success Scenario:
  1. sp_msforeachtable 'print ''?'''
