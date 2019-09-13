--
-- PostgreSQL database dump
--

-- Dumped from database version 11.1
-- Dumped by pg_dump version 11.5 (Ubuntu 11.5-1.pgdg16.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: sample_records; Type: TABLE; Schema: public; Owner: lucky
--

CREATE TABLE public.sample_records (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.sample_records OWNER TO lucky;

--
-- Name: sample_records_id_seq; Type: SEQUENCE; Schema: public; Owner: lucky
--

CREATE SEQUENCE public.sample_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sample_records_id_seq OWNER TO lucky;

--
-- Name: sample_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lucky
--

ALTER SEQUENCE public.sample_records_id_seq OWNED BY public.sample_records.id;

--
-- Name: sample_records id; Type: DEFAULT; Schema: public; Owner: lucky
--

ALTER TABLE ONLY public.sample_records ALTER COLUMN id SET DEFAULT nextval('public.sample_records_id_seq'::regclass);

--
-- Name: sample_records sample_records_pkey; Type: CONSTRAINT; Schema: public; Owner: lucky
--

ALTER TABLE ONLY public.sample_records
    ADD CONSTRAINT sample_records_pkey PRIMARY KEY (id);

--
-- PostgreSQL database dump complete
--

