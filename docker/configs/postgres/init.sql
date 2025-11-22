-- PostgreSQL Initialization Script for Academic Workflow Suite
-- This script sets up the database schema for production

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create schemas
CREATE SCHEMA IF NOT EXISTS aws_backend;
CREATE SCHEMA IF NOT EXISTS aws_analytics;

-- Set search path
SET search_path TO aws_backend, public;

-- Create rubrics table
CREATE TABLE IF NOT EXISTS rubrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_code VARCHAR(50) NOT NULL,
    assignment_code VARCHAR(50) NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    total_marks INTEGER NOT NULL,
    criteria JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(module_code, assignment_code, version)
);

CREATE INDEX idx_rubrics_module_assignment ON rubrics(module_code, assignment_code);
CREATE INDEX idx_rubrics_active ON rubrics(is_active) WHERE is_active = true;
CREATE INDEX idx_rubrics_criteria ON rubrics USING GIN(criteria);

-- Create rubric criteria table
CREATE TABLE IF NOT EXISTS rubric_criteria (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rubric_id UUID NOT NULL REFERENCES rubrics(id) ON DELETE CASCADE,
    criterion_name VARCHAR(255) NOT NULL,
    max_marks INTEGER NOT NULL,
    description TEXT,
    guidance TEXT,
    keywords TEXT[],
    weight DECIMAL(3,2) DEFAULT 1.0,
    display_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_criteria_rubric ON rubric_criteria(rubric_id);
CREATE INDEX idx_criteria_keywords ON rubric_criteria USING GIN(keywords);

-- Create analytics table for usage statistics
CREATE TABLE IF NOT EXISTS usage_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    module_code VARCHAR(50),
    assignment_code VARCHAR(50),
    user_hash VARCHAR(128),  -- Anonymized user identifier
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_usage_stats_event ON usage_stats(event_type, created_at DESC);
CREATE INDEX idx_usage_stats_module ON usage_stats(module_code, assignment_code);

-- Create audit log table
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(20) NOT NULL,
    record_id UUID,
    old_data JSONB,
    new_data JSONB,
    changed_by VARCHAR(255),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_table_operation ON audit_log(table_name, operation, changed_at DESC);

-- Create function for updating updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for rubrics table
CREATE TRIGGER update_rubrics_updated_at BEFORE UPDATE ON rubrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_data, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, OLD.id, row_to_json(OLD), session_user);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_data, new_data, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.id, row_to_json(OLD), row_to_json(NEW), session_user);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log (table_name, operation, record_id, new_data, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.id, row_to_json(NEW), session_user);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create audit triggers
CREATE TRIGGER audit_rubrics AFTER INSERT OR UPDATE OR DELETE ON rubrics
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_rubric_criteria AFTER INSERT OR UPDATE OR DELETE ON rubric_criteria
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Grant permissions
GRANT USAGE ON SCHEMA aws_backend TO aws_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA aws_backend TO aws_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA aws_backend TO aws_user;

-- Insert sample rubric
INSERT INTO rubrics (module_code, assignment_code, title, description, total_marks, criteria)
VALUES (
    'TM112',
    'TMA01',
    'Introduction to Computing and IT - TMA01',
    'Assessment for TM112 TMA01',
    100,
    '[
        {"name": "Understanding", "max_marks": 30, "description": "Understanding of key concepts"},
        {"name": "Analysis", "max_marks": 30, "description": "Critical analysis and evaluation"},
        {"name": "Structure", "max_marks": 20, "description": "Essay structure and organization"},
        {"name": "Presentation", "max_marks": 20, "description": "Presentation and referencing"}
    ]'::jsonb
) ON CONFLICT (module_code, assignment_code, version) DO NOTHING;

-- Vacuum and analyze
VACUUM ANALYZE;

\echo 'Database initialization complete'
