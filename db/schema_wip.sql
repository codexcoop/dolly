CREATE SCHEMA wip;
--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = wip, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: tmp_ingest_dirs; Type: TABLE; Schema: wip; Owner: -; Tablespace: 
--

CREATE TABLE tmp_ingest_dirs (
    id integer NOT NULL,
    lot_code character varying(255),
    dirname character varying(255),
    dirpath character varying(255),
    original_object_id integer,
    original_object_is_new boolean DEFAULT false,
    tiff_digital_object_id integer,
    pdf_digital_object_id integer,
    digital_object_is_new boolean DEFAULT false
);


--
-- Name: tmp_ingest_dirs_id_seq; Type: SEQUENCE; Schema: wip; Owner: -
--

CREATE SEQUENCE tmp_ingest_dirs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tmp_ingest_dirs_id_seq; Type: SEQUENCE OWNED BY; Schema: wip; Owner: -
--

ALTER SEQUENCE tmp_ingest_dirs_id_seq OWNED BY tmp_ingest_dirs.id;


--
-- Name: tmp_ingest_files; Type: TABLE; Schema: wip; Owner: -; Tablespace: 
--

CREATE TABLE tmp_ingest_files (
    id integer NOT NULL,
    tmp_ingest_dir_id integer,
    original_object_id integer,
    digital_object_id integer,
    digital_file_id integer,
    line character varying(255),
    original_filename character varying(255),
    mime_type character varying(255)
);


--
-- Name: tmp_ingest_files_id_seq; Type: SEQUENCE; Schema: wip; Owner: -
--

CREATE SEQUENCE tmp_ingest_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tmp_ingest_files_id_seq; Type: SEQUENCE OWNED BY; Schema: wip; Owner: -
--

ALTER SEQUENCE tmp_ingest_files_id_seq OWNED BY tmp_ingest_files.id;


--
-- Name: tmp_ingest_nodes; Type: TABLE; Schema: wip; Owner: -; Tablespace: 
--

CREATE TABLE tmp_ingest_nodes (
    id integer NOT NULL,
    tmp_ingest_file_id integer,
    digital_file_id integer,
    node_id integer,
    description character varying(255),
    ancestry character varying(255),
    ancestry_depth integer
);


--
-- Name: tmp_ingest_nodes_id_seq; Type: SEQUENCE; Schema: wip; Owner: -
--

CREATE SEQUENCE tmp_ingest_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tmp_ingest_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: wip; Owner: -
--

ALTER SEQUENCE tmp_ingest_nodes_id_seq OWNED BY tmp_ingest_nodes.id;


--
-- Name: id; Type: DEFAULT; Schema: wip; Owner: -
--

ALTER TABLE tmp_ingest_dirs ALTER COLUMN id SET DEFAULT nextval('tmp_ingest_dirs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: wip; Owner: -
--

ALTER TABLE tmp_ingest_files ALTER COLUMN id SET DEFAULT nextval('tmp_ingest_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: wip; Owner: -
--

ALTER TABLE tmp_ingest_nodes ALTER COLUMN id SET DEFAULT nextval('tmp_ingest_nodes_id_seq'::regclass);


--
-- Name: tmp_ingest_dirs_pkey; Type: CONSTRAINT; Schema: wip; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tmp_ingest_dirs
    ADD CONSTRAINT tmp_ingest_dirs_pkey PRIMARY KEY (id);


--
-- Name: tmp_ingest_files_pkey; Type: CONSTRAINT; Schema: wip; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tmp_ingest_files
    ADD CONSTRAINT tmp_ingest_files_pkey PRIMARY KEY (id);


--
-- Name: tmp_ingest_nodes_pkey; Type: CONSTRAINT; Schema: wip; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tmp_ingest_nodes
    ADD CONSTRAINT tmp_ingest_nodes_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

