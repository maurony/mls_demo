EXEC sp_configure

-- Reconfigure server
EXEC sp_configure 'external scripts enabled', 1;
RECONFIGURE WITH OVERRIDE

-- After configuration
EXEC sp_configure