DO $$ BEGIN
    -- Create the read-only user
    CREATE USER john WITH PASSWORD 'viewer';

    -- Grant CONNECT privilege on the database
    GRANT CONNECT ON DATABASE "jack" TO john;

    -- Grant USAGE privilege on all schemas
    GRANT USAGE ON SCHEMA public TO john;

    -- Grant SELECT privilege on all tables in the public schema
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO john;

    -- Ensure future tables in the public schema are accessible
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO john;
END $$;