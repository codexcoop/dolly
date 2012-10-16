module Ingestor

  module IngestSupportTables
    include IngestSupportLogger

    def execute(sql);
      ActiveRecord::Base.connection.execute(sql);
    end

    def wip_tables
      execute("SELECT tablename FROM pg_tables WHERE schemaname = 'wip'").values.flatten
    end

    def wip_views
      execute("SELECT viewname FROM pg_views WHERE schemaname = 'wip'").values.flatten
    end

    def create_tmp_ingest_dirs
      return if wip_tables.include? 'tmp_ingest_dirs'
      execute <<-SQL
        CREATE TABLE wip.tmp_ingest_dirs (
          id                      SERIAL PRIMARY KEY,
          lot_code                VARCHAR(255),
          dirname                 VARCHAR(255),
          dirpath                 VARCHAR(255),
          original_object_id      INTEGER,
          original_object_is_new  BOOLEAN DEFAULT FALSE,
          tiff_digital_object_id  INTEGER,
          pdf_digital_object_id   INTEGER,
          digital_object_is_new   BOOLEAN DEFAULT FALSE
        )
      SQL
    end

    def create_tmp_ingest_files
      return if wip_tables.include? 'tmp_ingest_files'
      execute <<-SQL
        CREATE TABLE wip.tmp_ingest_files (
          id                  SERIAL PRIMARY KEY,
          tmp_ingest_dir_id   INTEGER,
          original_object_id  INTEGER,
          digital_object_id   INTEGER,
          digital_file_id     INTEGER,
          line                VARCHAR(255),
          original_filename   VARCHAR(255),
          mime_type           VARCHAR(255)
        )
      SQL
    end

    def create_tmp_ingest_nodes
      return if wip_tables.include? 'tmp_ingest_nodes'
      execute <<-SQL
        CREATE TABLE wip.tmp_ingest_nodes (
          id                  SERIAL PRIMARY KEY,
          tmp_ingest_file_id  INTEGER,
          digital_file_id     INTEGER,
          node_id             INTEGER,
          description         VARCHAR(255),
          ancestry            VARCHAR(255),
          ancestry_depth      INTEGER
        )
      SQL
    end

    def create_tmp_dirs_comparison
      return if wip_views.include? 'tmp_dirs_comparison'
      execute <<-SQL
        CREATE VIEW wip.tmp_dirs_comparison AS
        SELECT
          tmp_ingest_dirs.id,
          tmp_ingest_dirs.dirname,
          tmp_ingest_dirs.original_object_id AS suggested_original_object_id,
          tmp_ingest_dirs.original_object_is_new,
          original_objects.id AS original_object_id,
          original_objects.title,
          original_objects.institution_id
        FROM original_objects
        FULL OUTER JOIN wip.tmp_ingest_dirs
        ON original_objects.id = tmp_ingest_dirs.original_object_id
        ORDER BY tmp_ingest_dirs.id;
      SQL
    end

    def create_tmp_dirs_missing_original_objects
      return if wip_views.include? 'tmp_dirs_missing_original_objects'
      execute <<-SQL
        CREATE VIEW wip.tmp_dirs_missing_original_objects AS
        SELECT *
        FROM wip.tmp_dirs_comparison
        WHERE original_object_is_new = TRUE
        ORDER BY dirname;
      SQL
    end

    def create_tmp_dirs_missing_dirs
      return if wip_views.include? 'tmp_dirs_missing_dirs'
      execute <<-SQL
        CREATE VIEW wip.tmp_dirs_missing_dirs AS
        SELECT *
        FROM wip.tmp_dirs_comparison
        WHERE suggested_original_object_id IS NULL
        AND original_object_id IS NOT NULL
        ORDER BY dirname;
      SQL
    end

    def create_support_tables
      log.debug("Setting up support tables")
      create_tmp_ingest_dirs
      create_tmp_ingest_files
      create_tmp_ingest_nodes
      create_tmp_dirs_comparison
      create_tmp_dirs_missing_original_objects
      create_tmp_dirs_missing_dirs
    end

    def drop_support_tables
      log.debug("Dropping support tables")
      execute "DROP VIEW IF EXISTS wip.tmp_dirs_missing_dirs;"
      execute "DROP VIEW IF EXISTS wip.tmp_dirs_missing_original_objects;"
      execute "DROP VIEW IF EXISTS wip.tmp_dirs_comparison;"
      execute "DROP TABLE IF EXISTS wip.tmp_ingest_nodes;"
      execute "DROP TABLE IF EXISTS wip.tmp_ingest_files;"
      execute "DROP TABLE IF EXISTS wip.tmp_ingest_dirs;"
    end

  end

end

