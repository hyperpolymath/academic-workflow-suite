-- PostgreSQL Replication Setup (for future use)
-- This script prepares the database for streaming replication

-- Create replication user (if needed in the future)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'replicator') THEN
        CREATE ROLE replicator WITH REPLICATION PASSWORD 'repl_password' LOGIN;
    END IF;
END
$$;

-- Grant permissions
GRANT CONNECT ON DATABASE academic_workflow TO replicator;

\echo 'Replication setup complete (currently inactive)'
