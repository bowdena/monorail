-- iPM_REPL database and app_one's SELECT-only access, created on
-- the shared MSSQL test instance for conduit's integration specs.
-- Mirrors the production iPM replica database; its tables are
-- derived from spec/support/mssql_production_schemas/iPM_REPL.
-- Test use only — passwords here are throwaway defaults.
-- Idempotent: run automatically by the spec suite before :mssql
-- examples (spec/support/mssql_seed_integration_tests.rb), before
-- this directory's table scripts.

IF DB_ID('iPM_REPL') IS NULL
  CREATE DATABASE [iPM_REPL];
GO

USE [iPM_REPL];
GO

-- Logins are instance-level, so every database.sql carries this
-- identical block: create the login if it is missing, otherwise
-- reset its password so reseeding converges on any instance. Each
-- script then grants access to its own database.
IF SUSER_ID('conduit_app_one') IS NULL
  CREATE LOGIN conduit_app_one
    WITH PASSWORD = 'App_one_integration1';
ELSE
  ALTER LOGIN conduit_app_one
    WITH PASSWORD = 'App_one_integration1';
GO

IF DATABASE_PRINCIPAL_ID('conduit_app_one') IS NULL
  CREATE USER conduit_app_one FOR LOGIN conduit_app_one;
GO

GRANT SELECT ON SCHEMA::dbo TO conduit_app_one;
GO
