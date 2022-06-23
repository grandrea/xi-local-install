--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.6
-- Dumped by pg_dump version 9.6.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

CREATE ROLE bio_user WITH LOGIN;
ALTER ROLE bio_user WITH PASSWORD 'XXXXXXXXXXX';

--
-- Name: xi3; Type: DATABASE; Schema: -; Owner: bio_user
--
CREATE DATABASE xi3 WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';


ALTER DATABASE xi3 OWNER TO bio_user;

\connect xi3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: comma_concate(text, text); Type: FUNCTION; Schema: public; Owner: bio_user
--

CREATE FUNCTION comma_concate(text, text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
  DECLARE
    t text;
  BEGIN
    IF  character_length($1) > 0 THEN
      t = $1 ||', '|| $2;
    ELSE
      t = $2;
    END IF;
    RETURN t;
  END;
  
  $_$;


ALTER FUNCTION public.comma_concate(text, text) OWNER TO bio_user;

--
-- Name: f_autorestart_searches(); Type: FUNCTION; Schema: public; Owner: bio_user
--

CREATE FUNCTION f_autorestart_searches() RETURNS integer
    LANGUAGE plpgsql
    AS $$DECLARE
  update_count integer;
BEGIN
UPDATE search SET status = 'queuing', is_executing = FALSE WHERE id IN (SELECT id FROM v_SerachesToBeRestarted);
GET DIAGNOSTICS update_count = ROW_COUNT;
return update_count;
END
$$;


ALTER FUNCTION public.f_autorestart_searches() OWNER TO bio_user;

--
-- Name: FUNCTION f_autorestart_searches(); Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON FUNCTION f_autorestart_searches() IS 'restart all searches that appear to have stoped and are in a state that can be restarted';


--
-- Name: f_export(integer); Type: FUNCTION; Schema: public; Owner: bio_user
--

CREATE FUNCTION f_export(sid integer) RETURNS TABLE(search_id integer, spectrum_match_id bigint, spectrum_id bigint, notes text, autovalidated boolean, rejected boolean, validated character varying, rank integer, run_name character varying, scan_number integer, match_score numeric, total_fragment_matches smallint, delta real, peptide1_coverage smallint, peptide2_coverage smallint, spectrum_peaks_coverage real, spectrum_intensity_coverage real, peptide1_id bigint, peptide1 text, protein1 text[], peptide_position1 integer[], site_count1 integer, protein_count1 integer, pep1_link_pos integer, peptide1_length integer, peptide2_id bigint, peptide2 text, protein2 text[], peptide_position2 integer[], site_count2 integer, protein_count2 integer, pep2_link_pos integer, peptide2_length integer, crosslinker character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
   RETURN QUERY
   
   SELECT 
	sm.search_id,
	sm.id as spectrum_match_id, 
	s.id as spectrum_id ,
	sm.notes,
	sm.autovalidated,
	sm.rejected,
	sm.validated,
	sm.rank,
	ss.name AS run_name,
	s.scan_number,
	sm.score AS match_score,
	scorefragmentsmatchedconservative AS total_fragment_matches,
	scoredelta AS delta,
	scorepeptide1matchedconservative AS peptide1_coverage,
	scorepeptide2matchedconservative AS peptide2_coverage,
	scorespectrumpeaksexplained AS spectrum_peaks_coverage,
	scorespectrumintensityexplained AS spectrum_intensity_coverage,
	mp1.peptide_id AS peptide1_id,
	mp1.sequence AS peptide1,
	mp1.protein_names as protein1,
	mp1.peptide_positions as peptide_position1,
	mp1.site_count AS site_count1, 
	mp1.protein_count AS protein_count1,
	mp1.link_position AS pep1_link_pos,
	mp1.peptide_length AS peptide1_length,
	mp2.peptide_id AS peptide2_id,
	mp2.sequence AS peptide2,
	mp2.protein_names as protein2,
	mp2.peptide_positions as peptide_position2,
	mp2.site_count as site_count2, 
	mp2.protein_count as protein_count2, 
	mp2.link_position AS pep2_link_pos,
	mp2.peptide_length AS peptide2_length,
	cl.name AS crosslinker

FROM 
	(SELECT * FROM Spectrum_match smi WHERE smi.search_id = sid AND smi.dynamic_rank = 't') sm   
		INNER JOIN
	f_matched_proteins(10001,1) mp1
		ON sm.id = mp1.match_id 
		LEFT OUTER JOIN    
	f_matched_proteins(10001,2) mp2
		ON sm.id = mp2.match_id 
		INNER JOIN     
	spectrum s 
		ON sm.spectrum_id = s.id  
		INNER JOIN     
	spectrum_source ss 
		ON s.source_id = ss.id  
		LEFT OUTER JOIN
	crosslinker cl
		ON mp2.crosslinker_id = cl.id;

		
END
$$;


ALTER FUNCTION public.f_export(sid integer) OWNER TO bio_user;

--
-- Name: f_export(integer, boolean); Type: FUNCTION; Schema: public; Owner: bio_user
--

CREATE FUNCTION f_export(sid integer, dynamicrank boolean) RETURNS TABLE(search_id integer, spectrum_match_id bigint, spectrum_id bigint, notes text, autovalidated boolean, rejected boolean, validated character varying, rank integer, run_name character varying, scan_number integer, match_score numeric, total_fragment_matches smallint, delta real, peptide1_coverage smallint, peptide2_coverage smallint, spectrum_peaks_coverage real, spectrum_intensity_coverage real, peptide1_id bigint, peptide1 text, protein1 text[], peptide_position1 integer[], site_count1 integer, protein_count1 integer, pep1_link_pos integer, peptide1_length integer, peptide2_id bigint, peptide2 text, protein2 text[], peptide_position2 integer[], site_count2 integer, protein_count2 integer, pep2_link_pos integer, peptide2_length integer, crosslinker character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN

   IF not dynamicrank ISNULL THEN
	   RETURN QUERY
	   SELECT 
		sm.search_id,
		sm.id as spectrum_match_id, 
		s.id as spectrum_id ,
		sm.notes,
		sm.autovalidated,
		sm.rejected,
		sm.validated,
		sm.rank,
		ss.name AS run_name,
		s.scan_number,
		sm.score AS match_score,
		scorefragmentsmatchedconservative AS total_fragment_matches,
		scoredelta AS delta,
		scorepeptide1matchedconservative AS peptide1_coverage,
		scorepeptide2matchedconservative AS peptide2_coverage,
		scorespectrumpeaksexplained AS spectrum_peaks_coverage,
		scorespectrumintensityexplained AS spectrum_intensity_coverage,
		mp1.peptide_id AS peptide1_id,
		mp1.sequence AS peptide1,
		mp1.protein_names as protein1,
		mp1.peptide_positions as peptide_position1,
		mp1.site_count AS site_count1, 
		mp1.protein_count AS protein_count1,
		mp1.link_position AS pep1_link_pos,
		mp1.peptide_length AS peptide1_length,
		mp2.peptide_id AS peptide2_id,
		mp2.sequence AS peptide2,
		mp2.protein_names as protein2,
		mp2.peptide_positions as peptide_position2,
		mp2.site_count as site_count2, 
		mp2.protein_count as protein_count2, 
		mp2.link_position AS pep2_link_pos,
		mp2.peptide_length AS peptide2_length,
		cl.name AS crosslinker

	FROM 
		(SELECT * FROM Spectrum_match smi WHERE smi.search_id = sid AND smi.dynamic_rank = dynamicrank) sm   
			INNER JOIN
		f_matched_proteins(sid,1) mp1
			ON sm.id = mp1.match_id 
			LEFT OUTER JOIN    
		f_matched_proteins(sid,2) mp2
			ON sm.id = mp2.match_id 
			INNER JOIN     
		spectrum s 
			ON sm.spectrum_id = s.id  
			INNER JOIN     
		spectrum_source ss 
			ON s.source_id = ss.id  
			LEFT OUTER JOIN
		crosslinker cl
			ON mp2.crosslinker_id = cl.id;
  ELSE
	   RETURN QUERY
	   SELECT 
		sm.search_id,
		sm.id as spectrum_match_id, 
		s.id as spectrum_id ,
		sm.notes,
		sm.autovalidated,
		sm.rejected,
		sm.validated,
		sm.rank,
		ss.name AS run_name,
		s.scan_number,
		sm.score AS match_score,
		scorefragmentsmatchedconservative AS total_fragment_matches,
		scoredelta AS delta,
		scorepeptide1matchedconservative AS peptide1_coverage,
		scorepeptide2matchedconservative AS peptide2_coverage,
		scorespectrumpeaksexplained AS spectrum_peaks_coverage,
		scorespectrumintensityexplained AS spectrum_intensity_coverage,
		mp1.peptide_id AS peptide1_id,
		mp1.sequence AS peptide1,
		mp1.protein_names as protein1,
		mp1.peptide_positions as peptide_position1,
		mp1.site_count AS site_count1, 
		mp1.protein_count AS protein_count1,
		mp1.link_position AS pep1_link_pos,
		mp1.peptide_length AS peptide1_length,
		mp2.peptide_id AS peptide2_id,
		mp2.sequence AS peptide2,
		mp2.protein_names as protein2,
		mp2.peptide_positions as peptide_position2,
		mp2.site_count as site_count2, 
		mp2.protein_count as protein_count2, 
		mp2.link_position AS pep2_link_pos,
		mp2.peptide_length AS peptide2_length,
		cl.name AS crosslinker

	FROM 
		(SELECT * FROM Spectrum_match smi WHERE smi.search_id = sid) sm   
			INNER JOIN
		f_matched_proteins(sid,1) mp1
			ON sm.id = mp1.match_id 
			LEFT OUTER JOIN    
		f_matched_proteins(sid,2) mp2
			ON sm.id = mp2.match_id 
			INNER JOIN     
		spectrum s 
			ON sm.spectrum_id = s.id  
			INNER JOIN     
		spectrum_source ss 
			ON s.source_id = ss.id  
			LEFT OUTER JOIN
		crosslinker cl
			ON mp2.crosslinker_id = cl.id;
  
  END IF;

		
END
$$;


ALTER FUNCTION public.f_export(sid integer, dynamicrank boolean) OWNER TO bio_user;

--
-- Name: f_matched_proteins(integer, integer); Type: FUNCTION; Schema: public; Owner: bio_user
--

CREATE FUNCTION f_matched_proteins(sid integer, matchtype integer) RETURNS TABLE(match_id bigint, link_position integer, crosslinker_id integer, crosslinker_number integer, peptide_id bigint, sequence text, peptide_length integer, protein_ids bigint[], protein_names text[], peptide_positions integer[], unique_proteins text[], site_count integer, protein_count integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
   RETURN QUERY
   SELECT *,array_length(i.peptide_positions,1) as site_count,array_length(i.unique_proteins,1) as protein_count     from (
   SELECT
	mp.match_id,
	mp.link_position,
	mp.crosslinker_id,
	mp.crosslinker_number,
	pep.id as peptide_id,
	pep.sequence,
	pep.peptide_length,
	array_agg(pr.id) AS protein_ids,
	array_agg(pr.name) AS protein_names,
	array_agg(hp.peptide_position) as peptide_positions,
	array_agg(distinct pr.name) AS unique_proteins
   FROM
	(Select * from matched_peptide where search_id = sid AND match_type = matchtype) mp
		INNER JOIN    
	peptide pep 
		ON mp.peptide_id = pep.id 
		INNER JOIN    
	has_protein hp
		ON mp.peptide_id = hp.peptide_id 
		INNER JOIN    
	protein pr
		ON hp.protein_id = pr.id 
   GROUP BY mp.match_id,mp.link_position,mp.crosslinker_id, mp.crosslinker_number,  pep.id, pep.peptide_length, pep.sequence
   ) i;
END
$$;


ALTER FUNCTION public.f_matched_proteins(sid integer, matchtype integer) OWNER TO bio_user;

--
-- Name: first_agg(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION first_agg(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$SELECT $1$_$;


ALTER FUNCTION public.first_agg(anyelement, anyelement) OWNER TO postgres;

--
-- Name: getdefaultxiversion(); Type: FUNCTION; Schema: public; Owner: bio_user
--

CREATE FUNCTION getdefaultxiversion() RETURNS integer
    LANGUAGE sql
    AS $$ SELECT id FROM xiversions WHERE isdefault;$$;


ALTER FUNCTION public.getdefaultxiversion() OWNER TO bio_user;

--
-- Name: randomstring(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION randomstring() RETURNS character varying
    LANGUAGE sql
    AS $$
 SELECT
         CAST( '' || trunc(random()*10) ||  trunc(random()*10) || trunc(random()*10) || trunc(random()*10) || trunc(random()*10)
           || '-' || trunc(random()*10) || trunc(random()*10) || trunc(random()*10) || trunc(random()*10) || trunc(random()*10)
           || '-' || trunc(random()*10) || trunc(random()*10) || trunc(random()*10) || trunc(random()*10) || trunc(random()*10)
           || '-' || trunc(random()*10) || trunc(random()*10) || trunc(random()*10) || trunc(random()*10) || trunc(random()*10)
             AS varchar)
 $$;


ALTER FUNCTION public.randomstring() OWNER TO postgres;

--
-- Name: reserve_ids(character varying, bigint); Type: FUNCTION; Schema: public; Owner: bio_user
--

CREATE FUNCTION reserve_ids(sequence_name character varying, count bigint DEFAULT 1) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
	val BIGINT;
BEGIN
	UPDATE storage_ids
	SET id_value = id_value + count
	WHERE name = sequence_name
	RETURNING id_value INTO val;
	RETURN val-count;
END;
$$;


ALTER FUNCTION public.reserve_ids(sequence_name character varying, count bigint) OWNER TO bio_user;

--
-- Name: FUNCTION reserve_ids(sequence_name character varying, count bigint); Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON FUNCTION reserve_ids(sequence_name character varying, count bigint) IS 'reserves a set of ids for a given name';


--
-- Name: reserve_ids2(character varying, bigint); Type: FUNCTION; Schema: public; Owner: bio_user
--

CREATE FUNCTION reserve_ids2(sequence_name character varying, count bigint DEFAULT 1) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
	val BIGINT;
BEGIN
	SELECT id_value INTO val FROM storage_ids WHERE name = sequence_name FOR UPDATE;
	UPDATE storage_ids
	SET id_value = val + count
	WHERE name = sequence_name;
	RETURN val;
END;
$$;


ALTER FUNCTION public.reserve_ids2(sequence_name character varying, count bigint) OWNER TO bio_user;

--
-- Name: search_ping_on_update(); Type: FUNCTION; Schema: public; Owner: bio_user
--

CREATE FUNCTION search_ping_on_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.ping := now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.search_ping_on_update() OWNER TO bio_user;

--
-- Name: xiversions_single_default(); Type: FUNCTION; Schema: public; Owner: bio_user
--

CREATE FUNCTION xiversions_single_default() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN                                       
  
  IF NEW.isdefault AND ((not OLD.isdefault) or OLD.isdefault is null) THEN
 UPDATE xiversions set isdefault = null where isdefault and id <> new.ID;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.xiversions_single_default() OWNER TO bio_user;

--
-- Name: first(anyelement); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE first(anyelement) (
    SFUNC = first_agg,
    STYPE = anyelement,
    PARALLEL = safe
);


ALTER AGGREGATE public.first(anyelement) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: search; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE search (
    id integer NOT NULL,
    name character varying(1000),
    private boolean DEFAULT false,
    uploadedby integer,
    paramset_id integer,
    submit_date timestamp without time zone DEFAULT now(),
    notes character varying(10000),
    status character varying(1000),
    percent_complete integer,
    completed boolean,
    is_executing boolean,
    hidden boolean,
    total_spec_count integer,
    total_proteins integer,
    total_peptides integer,
    visible_group integer DEFAULT 1,
    random_id character varying(100) DEFAULT randomstring() NOT NULL,
    cleanup boolean DEFAULT false,
    r_flag boolean DEFAULT false,
    ping timestamp without time zone,
    xiversion integer,
    scorenames text[],
    stop boolean
);


ALTER TABLE search OWNER TO bio_user;

--
-- Name: SerachesToBeRestarted; Type: VIEW; Schema: public; Owner: bio_user
--

CREATE VIEW "SerachesToBeRestarted" AS
 SELECT search.id
   FROM search
  WHERE ((NOT ((lower((search.status)::text) ~~ 'completed'::text) OR (lower((search.status)::text) ~~ 'unfinished:%'::text) OR (lower((search.status)::text) ~~ 'queuing'::text) OR (lower((search.status)::text) ~~ 'paused'::text) OR (lower((search.status)::text) ~~ 'xilauncher: requested xi version%'::text))) AND ((search.hidden IS NULL) OR (NOT search.hidden)) AND (search.ping < (now() - '24:00:00'::interval)) AND (search.ping > (now() - '60 days'::interval)));


ALTER TABLE "SerachesToBeRestarted" OWNER TO bio_user;

--
-- Name: VIEW "SerachesToBeRestarted"; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON VIEW "SerachesToBeRestarted" IS 'list all searches that can automatically be restarted';


--
-- Name: acquisition; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE acquisition (
    id integer NOT NULL,
    name character varying(1000),
    notes character varying(10000),
    upload_date timestamp without time zone DEFAULT now(),
    uploadedby integer,
    private boolean DEFAULT false,
    file_path character varying(10000)[]
);


ALTER TABLE acquisition OWNER TO bio_user;

--
-- Name: acquisition_id; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE acquisition_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE acquisition_id OWNER TO bio_user;

--
-- Name: acquisition_id; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE acquisition_id OWNED BY acquisition.id;


--
-- Name: base_setting; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE base_setting (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    setting text
);


ALTER TABLE base_setting OWNER TO bio_user;

--
-- Name: base_setting_id_seq; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE base_setting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE base_setting_id_seq OWNER TO bio_user;

--
-- Name: base_setting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE base_setting_id_seq OWNED BY base_setting.id;


--
-- Name: chosen_crosslinker; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE chosen_crosslinker (
    paramset_id integer NOT NULL,
    crosslinker_id integer NOT NULL
);


ALTER TABLE chosen_crosslinker OWNER TO bio_user;

--
-- Name: chosen_ions; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE chosen_ions (
    paramset_id integer NOT NULL,
    ion_id integer NOT NULL
);


ALTER TABLE chosen_ions OWNER TO bio_user;

--
-- Name: chosen_label_scheme; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE chosen_label_scheme (
    paramset_id integer NOT NULL,
    scheme_id integer NOT NULL,
    label_id integer NOT NULL
);


ALTER TABLE chosen_label_scheme OWNER TO bio_user;

--
-- Name: chosen_losses; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE chosen_losses (
    paramset_id integer NOT NULL,
    loss_id integer NOT NULL
);


ALTER TABLE chosen_losses OWNER TO bio_user;

--
-- Name: chosen_modification; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE chosen_modification (
    paramset_id integer NOT NULL,
    mod_id integer NOT NULL,
    fixed boolean NOT NULL
);


ALTER TABLE chosen_modification OWNER TO bio_user;

--
-- Name: crosslinker; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE crosslinker (
    id integer NOT NULL,
    name character varying(100),
    mass character varying(100),
    is_decoy boolean DEFAULT false,
    description text,
    is_default boolean
);


ALTER TABLE crosslinker OWNER TO bio_user;

--
-- Name: COLUMN crosslinker.is_default; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN crosslinker.is_default IS 'Should the crosslinker be selected by default?';


--
-- Name: crosslinker_id_seq; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE crosslinker_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE crosslinker_id_seq OWNER TO bio_user;

--
-- Name: crosslinker_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE crosslinker_id_seq OWNED BY crosslinker.id;


--
-- Name: enzyme; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE enzyme (
    id integer NOT NULL,
    name character varying(100),
    description text,
    is_default boolean
);


ALTER TABLE enzyme OWNER TO bio_user;

--
-- Name: COLUMN enzyme.is_default; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN enzyme.is_default IS 'Is the enzyme selected by default?';


--
-- Name: enzyme_id_seq; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE enzyme_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE enzyme_id_seq OWNER TO bio_user;

--
-- Name: enzyme_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE enzyme_id_seq OWNED BY enzyme.id;


--
-- Name: fdrlevel; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE fdrlevel (
    level_id integer NOT NULL,
    name character varying(100)
);


ALTER TABLE fdrlevel OWNER TO bio_user;

--
-- Name: has_protein; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE has_protein (
    peptide_id bigint NOT NULL,
    protein_id bigint NOT NULL,
    peptide_position integer NOT NULL,
    display_site boolean
);


ALTER TABLE has_protein OWNER TO bio_user;

--
-- Name: iaminberlin; Type: VIEW; Schema: public; Owner: bio_user
--

CREATE VIEW iaminberlin AS
 SELECT (1 + 1);


ALTER TABLE iaminberlin OWNER TO bio_user;

--
-- Name: ion; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE ion (
    id integer NOT NULL,
    name character varying(50),
    description text,
    is_default boolean
);


ALTER TABLE ion OWNER TO bio_user;

--
-- Name: COLUMN ion.is_default; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN ion.is_default IS 'Is an ion chosen by default?';


--
-- Name: ion_id_seq; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE ion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ion_id_seq OWNER TO bio_user;

--
-- Name: ion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE ion_id_seq OWNED BY ion.id;


--
-- Name: label; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE label (
    id integer NOT NULL,
    name character varying(1000),
    aa character varying(10),
    description text
);


ALTER TABLE label OWNER TO bio_user;

--
-- Name: label_id_seq; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE label_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE label_id_seq OWNER TO bio_user;

--
-- Name: label_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE label_id_seq OWNED BY label.id;


--
-- Name: label_scheme; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE label_scheme (
    id integer NOT NULL,
    name name
);


ALTER TABLE label_scheme OWNER TO bio_user;

--
-- Name: label_scheme_id_seq; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE label_scheme_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE label_scheme_id_seq OWNER TO bio_user;

--
-- Name: label_scheme_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE label_scheme_id_seq OWNED BY label_scheme.id;


--
-- Name: layouts; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE layouts (
    search_id text NOT NULL,
    user_id integer NOT NULL,
    "time" timestamp without time zone DEFAULT now() NOT NULL,
    layout text,
    description text
);


ALTER TABLE layouts OWNER TO bio_user;

--
-- Name: loss; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE loss (
    id integer NOT NULL,
    name character varying(50),
    lost_mass numeric,
    description text,
    is_default boolean
);


ALTER TABLE loss OWNER TO bio_user;

--
-- Name: COLUMN loss.is_default; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN loss.is_default IS 'Is this loss chosen by default?';


--
-- Name: loss_id_seq; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE loss_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE loss_id_seq OWNER TO bio_user;

--
-- Name: loss_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE loss_id_seq OWNED BY loss.id;


--
-- Name: manual_annotations; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE manual_annotations (
    protein_ids character varying,
    on_chromatin character(3),
    localization character varying,
    p_function character varying,
    name character varying,
    complex character varying,
    domain_accessions character varying
);


ALTER TABLE manual_annotations OWNER TO bio_user;

--
-- Name: match_type; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE match_type (
    id integer NOT NULL,
    name character varying(50)
);


ALTER TABLE match_type OWNER TO bio_user;

--
-- Name: match_type_id_seq; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE match_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE match_type_id_seq OWNER TO bio_user;

--
-- Name: match_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE match_type_id_seq OWNED BY match_type.id;


--
-- Name: matched_peptide; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE matched_peptide (
    peptide_id bigint NOT NULL,
    match_id bigint NOT NULL,
    match_type integer NOT NULL,
    link_position integer NOT NULL,
    display_positon boolean,
    search_id integer,
    crosslinker_id integer,
    crosslinker_number integer,
    link_site_score real[],
    weight real
);


ALTER TABLE matched_peptide OWNER TO bio_user;

--
-- Name: COLUMN matched_peptide.crosslinker_id; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN matched_peptide.crosslinker_id IS 'Which of the n involved crosslinker is linking to the refered site';


--
-- Name: modification; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE modification (
    id integer NOT NULL,
    name character varying(1000),
    description text,
    formula character varying,
    symbol character varying,
    is_default_fixed boolean,
    is_default_var boolean
);


ALTER TABLE modification OWNER TO bio_user;

--
-- Name: COLUMN modification.is_default_fixed; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN modification.is_default_fixed IS 'Is this a default fixed modification?';


--
-- Name: COLUMN modification.is_default_var; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN modification.is_default_var IS 'Is this a default var modification?';


--
-- Name: modification_id_seq; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE modification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE modification_id_seq OWNER TO bio_user;

--
-- Name: modification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE modification_id_seq OWNED BY modification.id;


--
-- Name: parameter_set; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE parameter_set (
    id integer NOT NULL,
    name character varying(1000),
    template boolean,
    uploadedby integer,
    top_alpha_matches integer,
    missed_cleavages integer,
    ms_tol numeric,
    ms2_tol numeric,
    ms_tol_unit character varying(10),
    ms2_tol_unit character varying(10),
    synthetic boolean,
    global_id uuid,
    upload_date timestamp without time zone DEFAULT now(),
    enzyme_chosen integer,
    notes character varying(10000),
    customsettings character varying(50000)
);


ALTER TABLE parameter_set OWNER TO bio_user;

--
-- Name: users; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE users (
    id integer NOT NULL,
    user_name character varying(20) NOT NULL,
    password text,
    max_spectra integer,
    max_aas integer,
    email character varying(320),
    ptoken_timestamp timestamp with time zone,
    ptoken character varying(36),
    hidden boolean,
    gdpr_token character varying(36),
    gdpr_timestamp timestamp with time zone
);


ALTER TABLE users OWNER TO bio_user;

--
-- Name: COLUMN users.email; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN users.email IS 'Varchar 320';


--
-- Name: COLUMN users.ptoken_timestamp; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN users.ptoken_timestamp IS 'timestamp that puts limit on when password can be reset';


--
-- Name: COLUMN users.ptoken; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN users.ptoken IS 'token for authenticating user in web link';


--
-- Name: COLUMN users.hidden; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN users.hidden IS 'Is user hidden from view (can be used as flag to sweep for later deletion)';


--
-- Name: opentargetmodificationsearches; Type: VIEW; Schema: public; Owner: bio_user
--

CREATE VIEW opentargetmodificationsearches AS
 SELECT s.id,
    s.name,
    s.private,
    u.user_name,
    s.paramset_id,
    s.submit_date,
    s.notes,
    s.status,
    s.percent_complete,
    s.completed,
    s.is_executing,
    s.hidden,
    s.total_spec_count,
    s.total_proteins,
    s.total_peptides,
    s.visible_group,
    s.random_id,
    s.cleanup
   FROM ((((search s
     JOIN parameter_set ps ON ((s.paramset_id = ps.id)))
     JOIN chosen_crosslinker cc ON ((cc.paramset_id = ps.id)))
     JOIN crosslinker c ON ((cc.crosslinker_id = c.id)))
     JOIN users u ON ((s.uploadedby = u.id)))
  WHERE (((lower((c.name)::text) ~~ 'openmodification'::text) OR (lower((c.name)::text) ~~ 'targetmodification'::text)) AND ((s.status)::text <> 'failed'::text));


ALTER TABLE opentargetmodificationsearches OWNER TO bio_user;

--
-- Name: parameter_set_id; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE parameter_set_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE parameter_set_id OWNER TO bio_user;

--
-- Name: parameter_set_id; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE parameter_set_id OWNED BY parameter_set.id;


--
-- Name: peaklistfile; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE peaklistfile (
    id integer NOT NULL,
    name character varying
);


ALTER TABLE peaklistfile OWNER TO bio_user;

--
-- Name: peaklistfile_id_seq; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE peaklistfile_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE peaklistfile_id_seq OWNER TO bio_user;

--
-- Name: peaklistfile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE peaklistfile_id_seq OWNED BY peaklistfile.id;


--
-- Name: peptide; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE peptide (
    id bigint NOT NULL,
    sequence text,
    mass numeric,
    peptide_length integer
);


ALTER TABLE peptide OWNER TO bio_user;

--
-- Name: protein; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE protein (
    id bigint NOT NULL,
    name text,
    accession_number text,
    description text,
    sequence text,
    is_decoy boolean DEFAULT false,
    protein_length integer,
    header text,
    seq_id integer
);


ALTER TABLE protein OWNER TO bio_user;

--
-- Name: run; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE run (
    acq_id integer NOT NULL,
    run_id integer NOT NULL,
    name character varying(1000),
    file_path character varying(10000),
    size character varying(50)[]
);


ALTER TABLE run OWNER TO bio_user;

--
-- Name: score_id_seq; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE score_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE score_id_seq OWNER TO bio_user;

--
-- Name: search_acquisition; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE search_acquisition (
    search_id integer NOT NULL,
    acq_id integer NOT NULL,
    run_id integer NOT NULL
);


ALTER TABLE search_acquisition OWNER TO bio_user;

--
-- Name: search_id; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE search_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE search_id OWNER TO bio_user;

--
-- Name: search_id; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE search_id OWNED BY search.id;


--
-- Name: search_sequencedb; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE search_sequencedb (
    search_id integer NOT NULL,
    seqdb_id integer NOT NULL
);


ALTER TABLE search_sequencedb OWNER TO bio_user;

--
-- Name: xiversions; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE xiversions (
    id integer NOT NULL,
    version character varying NOT NULL,
    isdefault boolean,
    "Notes" character varying
);


ALTER TABLE xiversions OWNER TO bio_user;

--
-- Name: seq_xiversion_ids; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE seq_xiversion_ids
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_xiversion_ids OWNER TO bio_user;

--
-- Name: seq_xiversion_ids; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE seq_xiversion_ids OWNED BY xiversions.id;


--
-- Name: sequence_file; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE sequence_file (
    id integer NOT NULL,
    name character varying(1000),
    file_name character varying(10000),
    decoy_file boolean DEFAULT false,
    file_path character varying(10000),
    notes character varying(10000),
    upload_date timestamp without time zone DEFAULT now(),
    uploadedby integer,
    private boolean DEFAULT false,
    species character varying(40)
);


ALTER TABLE sequence_file OWNER TO bio_user;

--
-- Name: sequence_file_id; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE sequence_file_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sequence_file_id OWNER TO bio_user;

--
-- Name: sequence_file_id; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE sequence_file_id OWNED BY sequence_file.id;


--
-- Name: showblocks; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW showblocks AS
 SELECT blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    "substring"(blocked_activity.query, 1, 20) AS blocked_statement,
    "substring"(blocking_activity.query, 1, 20) AS current_statement_in_blocking_process
   FROM (((pg_locks blocked_locks
     JOIN pg_stat_activity blocked_activity ON ((blocked_activity.pid = blocked_locks.pid)))
     JOIN pg_locks blocking_locks ON (((blocking_locks.locktype = blocked_locks.locktype) AND (NOT (blocking_locks.database IS DISTINCT FROM blocked_locks.database)) AND (NOT (blocking_locks.relation IS DISTINCT FROM blocked_locks.relation)) AND (NOT (blocking_locks.page IS DISTINCT FROM blocked_locks.page)) AND (NOT (blocking_locks.tuple IS DISTINCT FROM blocked_locks.tuple)) AND (NOT (blocking_locks.virtualxid IS DISTINCT FROM blocked_locks.virtualxid)) AND (NOT (blocking_locks.transactionid IS DISTINCT FROM blocked_locks.transactionid)) AND (NOT (blocking_locks.classid IS DISTINCT FROM blocked_locks.classid)) AND (NOT (blocking_locks.objid IS DISTINCT FROM blocked_locks.objid)) AND (NOT (blocking_locks.objsubid IS DISTINCT FROM blocked_locks.objsubid)) AND (blocking_locks.pid <> blocked_locks.pid))))
     JOIN pg_stat_activity blocking_activity ON ((blocking_activity.pid = blocking_locks.pid)))
  WHERE (NOT blocked_locks.granted);


ALTER TABLE showblocks OWNER TO postgres;

--
-- Name: spectrum; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE spectrum (
    id bigint NOT NULL,
    run_id integer,
    acq_id integer,
    scan_number integer,
    elution_time_start character varying(50),
    elution_time_end character varying(50),
    precursor_charge integer,
    precursor_intensity numeric,
    precursor_mz numeric,
    notes text,
    source_id integer,
    scan_index integer,
    peaklist_id integer
);


ALTER TABLE spectrum OWNER TO bio_user;

--
-- Name: spectrum_match; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE spectrum_match (
    id bigint NOT NULL,
    spectrum_id bigint,
    search_id integer,
    rank integer,
    validation_id integer,
    is_decoy boolean DEFAULT false,
    score numeric,
    precursor_charge integer,
    calc_mass numeric,
    notes text,
    autovalidated boolean,
    rejected boolean,
    validated character varying(5),
    dynamic_rank boolean,
    percentdecoy double precision,
    rescored double precision,
    scorepeptide1matchedconservative smallint,
    scorepeptide2matchedconservative smallint,
    scorefragmentsmatchedconservative smallint,
    scorespectrumpeaksexplained real,
    scorespectrumintensityexplained real,
    scorelinksitedelta real,
    scoredelta real,
    scoremoddelta real,
    scoremgxrank smallint,
    scoremgcalpha real,
    scoremgcbeta real,
    scoremgc real,
    scoremgx real,
    scoremgxdelta real,
    assumed_precursor_mz double precision,
    scorecleavclpep1fragmatched boolean,
    scorecleavclpep2fragmatched boolean,
    scores real[]
);


ALTER TABLE spectrum_match OWNER TO bio_user;

--
-- Name: spectrum_peak; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE spectrum_peak (
    id bigint NOT NULL,
    spectrum_id bigint,
    mz numeric,
    intensity numeric
);


ALTER TABLE spectrum_peak OWNER TO bio_user;

--
-- Name: spectrum_source; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE spectrum_source (
    id integer NOT NULL,
    name character varying
);


ALTER TABLE spectrum_source OWNER TO bio_user;

--
-- Name: spectrum_source_id_seq; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE spectrum_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE spectrum_source_id_seq OWNER TO bio_user;

--
-- Name: spectrum_source_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE spectrum_source_id_seq OWNED BY spectrum_source.id;


--
-- Name: storage_ids; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE storage_ids (
    name character varying(200) NOT NULL,
    id_value bigint
);


ALTER TABLE storage_ids OWNER TO bio_user;

--
-- Name: uniprot; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE uniprot (
    accession character varying(10) NOT NULL,
    name text,
    full_name text,
    gene text,
    organism text[],
    sequence text,
    keywords text[],
    comments text[],
    locations text[],
    features json,
    go character(9)[]
);


ALTER TABLE uniprot OWNER TO bio_user;

--
-- Name: user_groups; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE user_groups (
    id integer NOT NULL,
    name character varying(100),
    max_search_count integer,
    max_spectra integer,
    max_aas integer,
    search_lifetime_days integer,
    super_user boolean,
    see_all boolean,
    can_add_search boolean,
    max_searches_per_day integer
);


ALTER TABLE user_groups OWNER TO bio_user;

--
-- Name: COLUMN user_groups.max_search_count; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN user_groups.max_search_count IS 'Max number of searches for this user type';


--
-- Name: COLUMN user_groups.max_spectra; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN user_groups.max_spectra IS 'Max number of spectra uploadable by this user type';


--
-- Name: COLUMN user_groups.max_aas; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN user_groups.max_aas IS 'Max number of amino acids (fasta size) uploadable by this user type';


--
-- Name: COLUMN user_groups.search_lifetime_days; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN user_groups.search_lifetime_days IS 'Retention lifetime of searches for this user type';


--
-- Name: COLUMN user_groups.super_user; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN user_groups.super_user IS 'Can this user type see all other users data and change their user settings?';


--
-- Name: COLUMN user_groups.see_all; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN user_groups.see_all IS 'Can this user type see all other users non-private searches, seqs, acqs?';


--
-- Name: COLUMN user_groups.can_add_search; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN user_groups.can_add_search IS 'Can this user type add new searches?';


--
-- Name: COLUMN user_groups.max_searches_per_day; Type: COMMENT; Schema: public; Owner: bio_user
--

COMMENT ON COLUMN user_groups.max_searches_per_day IS 'Throttle on number of searches per calendar day for this user type';


--
-- Name: user_groups_id; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE user_groups_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_groups_id OWNER TO bio_user;

--
-- Name: user_groups_id; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE user_groups_id OWNED BY user_groups.id;


--
-- Name: user_in_group; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE user_in_group (
    user_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE user_in_group OWNER TO bio_user;

--
-- Name: users_id; Type: SEQUENCE; Schema: public; Owner: bio_user
--

CREATE SEQUENCE users_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id OWNER TO bio_user;

--
-- Name: users_id; Type: SEQUENCE OWNED BY; Schema: public; Owner: bio_user
--

ALTER SEQUENCE users_id OWNED BY users.id;


--
-- Name: v_get_blocks; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW v_get_blocks AS
 SELECT blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS current_statement_in_blocking_process
   FROM (((pg_locks blocked_locks
     JOIN pg_stat_activity blocked_activity ON ((blocked_activity.pid = blocked_locks.pid)))
     JOIN pg_locks blocking_locks ON (((blocking_locks.locktype = blocked_locks.locktype) AND (NOT (blocking_locks.database IS DISTINCT FROM blocked_locks.database)) AND (NOT (blocking_locks.relation IS DISTINCT FROM blocked_locks.relation)) AND (NOT (blocking_locks.page IS DISTINCT FROM blocked_locks.page)) AND (NOT (blocking_locks.tuple IS DISTINCT FROM blocked_locks.tuple)) AND (NOT (blocking_locks.virtualxid IS DISTINCT FROM blocked_locks.virtualxid)) AND (NOT (blocking_locks.transactionid IS DISTINCT FROM blocked_locks.transactionid)) AND (NOT (blocking_locks.classid IS DISTINCT FROM blocked_locks.classid)) AND (NOT (blocking_locks.objid IS DISTINCT FROM blocked_locks.objid)) AND (NOT (blocking_locks.objsubid IS DISTINCT FROM blocked_locks.objsubid)) AND (blocking_locks.pid <> blocked_locks.pid))))
     JOIN pg_stat_activity blocking_activity ON ((blocking_activity.pid = blocking_locks.pid)))
  WHERE (NOT blocked_locks.granted);


ALTER TABLE v_get_blocks OWNER TO postgres;

--
-- Name: v_getqueries; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW v_getqueries AS
 SELECT pg_stat_activity.pid,
    pg_stat_activity.client_addr,
    age(clock_timestamp(), pg_stat_activity.query_start) AS age,
    pg_stat_activity.state,
    pg_stat_activity.usename,
    substr(pg_stat_activity.query, 0, 100) AS substr,
    pg_stat_activity.backend_start
   FROM pg_stat_activity
  WHERE ((pg_stat_activity.query <> '<IDLE>'::text) AND (pg_stat_activity.query !~~* '%pg_stat_activity%'::text))
  ORDER BY pg_stat_activity.query_start DESC;


ALTER TABLE v_getqueries OWNER TO postgres;

--
-- Name: v_gettablesizes; Type: VIEW; Schema: public; Owner: bio_user
--

CREATE VIEW v_gettablesizes AS
 SELECT (((n.nspname)::text || '.'::text) || (c.relname)::text) AS relation,
    pg_size_pretty(pg_relation_size((c.oid)::regclass)) AS prettysize,
    pg_relation_size((c.oid)::regclass) AS size
   FROM (pg_class c
     LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE (n.nspname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name]))
  ORDER BY (pg_relation_size((c.oid)::regclass)) DESC;


ALTER TABLE v_gettablesizes OWNER TO bio_user;

--
-- Name: v_serachestoberestarted; Type: VIEW; Schema: public; Owner: bio_user
--

CREATE VIEW v_serachestoberestarted AS
 SELECT search.id
   FROM search
  WHERE ((NOT ((lower((search.status)::text) ~~ 'completed'::text) OR (lower((search.status)::text) ~~ 'unfinished:%'::text) OR (lower((search.status)::text) ~~ 'queuing'::text) OR (lower((search.status)::text) ~~ 'paused'::text) OR (lower((search.status)::text) ~~ 'xilauncher: requested xi version%'::text))) AND ((search.hidden IS NULL) OR (NOT search.hidden)) AND (search.ping < (now() - '24:00:00'::interval)) AND (search.ping > (now() - '60 days'::interval)));


ALTER TABLE v_serachestoberestarted OWNER TO bio_user;

--
-- Name: version_number; Type: TABLE; Schema: public; Owner: bio_user
--

CREATE TABLE version_number (
    component character varying(100),
    version_upper integer,
    version_lower integer,
    version_internal integer,
    description text,
    directory_path text,
    current boolean,
    date timestamp without time zone DEFAULT now()
);


ALTER TABLE version_number OWNER TO bio_user;

--
-- Name: xi_config; Type: VIEW; Schema: public; Owner: bio_user
--

CREATE VIEW xi_config AS
 SELECT s.search_id,
    s.description
   FROM ( SELECT 1000 AS o,
            s_1.id AS search_id,
            ('custom:'::text || (ps.customsettings)::text) AS description
           FROM (search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
          WHERE (ps.customsettings IS NOT NULL)
        UNION
         SELECT 20 AS o,
            s_1.id AS search_id,
            ((c.description || ';id:'::text) || c.id) AS description
           FROM ((search s_1
             JOIN chosen_crosslinker cc ON ((cc.paramset_id = s_1.paramset_id)))
             JOIN crosslinker c ON ((cc.crosslinker_id = c.id)))
        UNION
         SELECT 30 AS o,
            s_1.id AS search_id,
            ((i.description || ';id:'::text) || i.id) AS description
           FROM ((search s_1
             JOIN chosen_ions ci ON ((ci.paramset_id = s_1.paramset_id)))
             JOIN ion i ON ((ci.ion_id = i.id)))
        UNION
         SELECT 10 AS o,
            s_1.id AS search_id,
            ('modification:fixed:'::text || m.description) AS description
           FROM ((search s_1
             LEFT JOIN chosen_modification cm ON ((cm.paramset_id = s_1.paramset_id)))
             JOIN modification m ON ((m.id = cm.mod_id)))
          WHERE (cm.fixed = true)
        UNION
         SELECT 10 AS o,
            s_1.id AS search_id,
            ('modification:variable:'::text || m.description) AS description
           FROM ((search s_1
             JOIN chosen_modification cm ON ((cm.paramset_id = s_1.paramset_id)))
             JOIN modification m ON ((m.id = cm.mod_id)))
          WHERE (cm.fixed = false)
        UNION
         SELECT 40 AS o,
            s_1.id AS search_id,
            ((l.description || ';id:'::text) || l.id) AS description
           FROM ((search s_1
             JOIN chosen_losses cl ON ((cl.paramset_id = s_1.paramset_id)))
             JOIN loss l ON ((cl.loss_id = l.id)))
        UNION
         SELECT 20 AS o,
            s_1.id AS search_id,
            ('label:heavy:'::text || label.description) AS description
           FROM ((search s_1
             JOIN chosen_label_scheme cl ON ((cl.paramset_id = s_1.paramset_id)))
             JOIN label label ON ((label.id = cl.label_id)))
          WHERE (cl.scheme_id = 1)
        UNION
         SELECT 20 AS o,
            s_1.id AS search_id,
            ('label:medium:'::text || label.description) AS description
           FROM ((search s_1
             JOIN chosen_label_scheme cl ON ((cl.paramset_id = s_1.paramset_id)))
             JOIN label label ON ((label.id = cl.label_id)))
          WHERE (cl.scheme_id = 2)
        UNION
         SELECT 90 AS o,
            s_1.id AS search_id,
                CASE
                    WHEN ("substring"(e.description, 1, 10) = 'digestion:'::text) THEN e.description
                    ELSE ('digestion:'::text || e.description)
                END AS description
           FROM ((search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
             JOIN enzyme e ON ((ps.enzyme_chosen = e.id)))
        UNION
         SELECT 80 AS o,
            s_1.id AS search_id,
            (('tolerance:precursor:'::text || ps.ms_tol) || (ps.ms_tol_unit)::text) AS description
           FROM (search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
        UNION
         SELECT 80 AS o,
            s_1.id AS search_id,
            (('tolerance:fragment:'::text || ps.ms2_tol) || (ps.ms2_tol_unit)::text) AS description
           FROM (search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
        UNION
         SELECT 80 AS o,
            s_1.id AS search_id,
            ('missedcleavages:'::text || ps.missed_cleavages) AS description
           FROM (search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
        UNION
         SELECT 80 AS o,
            s_1.id AS search_id,
            ('topmgchits:'::text || ps.top_alpha_matches) AS description
           FROM (search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
        UNION
         SELECT 100 AS o,
            s_1.id AS search_id,
            ('synthetic:'::text || ps.synthetic) AS description
           FROM (search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
        UNION
         SELECT 0 AS o,
            '-1'::integer AS search_id,
            (((bs.name)::text || ':'::text) || bs.setting) AS description
           FROM base_setting bs) s
  ORDER BY s.o, s.description;


ALTER TABLE xi_config OWNER TO bio_user;

--
-- Name: xi_config_desc; Type: VIEW; Schema: public; Owner: bio_user
--

CREATE VIEW xi_config_desc AS
 SELECT s.search_id,
    s.description,
    s.guisetting
   FROM ( SELECT ((1000)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#manually defined settings for the search'::text AS description,
            true AS guisetting
           FROM search s_1
        UNION
         SELECT 1000 AS o,
            s_1.id AS search_id,
            ('custom:'::text || (ps.customsettings)::text) AS description,
            true AS guisetting
           FROM (search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
          WHERE ((ps.customsettings IS NOT NULL) AND ((ps.customsettings)::text <> ''::text))
        UNION
         SELECT ((20)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#cross-linker selected for the search'::text AS description,
            true AS guisetting
           FROM search s_1
        UNION
         SELECT 20 AS o,
            s_1.id AS search_id,
            ((c.description || ';id:'::text) || c.id) AS description,
            true AS guisetting
           FROM ((search s_1
             JOIN chosen_crosslinker cc ON ((cc.paramset_id = s_1.paramset_id)))
             JOIN crosslinker c ON ((cc.crosslinker_id = c.id)))
        UNION
         SELECT ((30)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#Ions to considere'::text AS description,
            true AS guisetting
           FROM search s_1
        UNION
         SELECT 30 AS o,
            s_1.id AS search_id,
            ((i.description || ';id:'::text) || i.id) AS description,
            true AS guisetting
           FROM ((search s_1
             JOIN chosen_ions ci ON ((ci.paramset_id = s_1.paramset_id)))
             JOIN ion i ON ((ci.ion_id = i.id)))
        UNION
         SELECT ((10)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#Modifications selected as fixed'::text AS description,
            true AS guisetting
           FROM search s_1
        UNION
         SELECT 10 AS o,
            s_1.id AS search_id,
            ('modification:fixed:'::text || m.description) AS description,
            true AS guisetting
           FROM ((search s_1
             LEFT JOIN chosen_modification cm ON ((cm.paramset_id = s_1.paramset_id)))
             JOIN modification m ON ((m.id = cm.mod_id)))
          WHERE (cm.fixed = true)
        UNION
         SELECT ((11)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#Modifications selected as variable'::text AS description,
            true AS guisetting
           FROM search s_1
        UNION
         SELECT 11 AS o,
            s_1.id AS search_id,
            ('modification:variable:'::text || m.description) AS description,
            true AS guisetting
           FROM ((search s_1
             JOIN chosen_modification cm ON ((cm.paramset_id = s_1.paramset_id)))
             JOIN modification m ON ((m.id = cm.mod_id)))
          WHERE (cm.fixed = false)
        UNION
         SELECT ((40)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#losses to be considered'::text AS description,
            true AS guisetting
           FROM search s_1
        UNION
         SELECT 40 AS o,
            s_1.id AS search_id,
            ((l.description || ';id:'::text) || l.id) AS description,
            true AS guisetting
           FROM ((search s_1
             JOIN chosen_losses cl ON ((cl.paramset_id = s_1.paramset_id)))
             JOIN loss l ON ((cl.loss_id = l.id)))
        UNION
         SELECT DISTINCT ((50)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#Heavy label selected'::text AS description,
            true AS guisetting
           FROM ((search s_1
             JOIN chosen_label_scheme cl ON ((cl.paramset_id = s_1.paramset_id)))
             JOIN label label ON ((label.id = cl.label_id)))
          WHERE (cl.scheme_id = 1)
        UNION
         SELECT 50 AS o,
            s_1.id AS search_id,
            ('label:heavy:'::text || label.description) AS description,
            true AS guisetting
           FROM ((search s_1
             JOIN chosen_label_scheme cl ON ((cl.paramset_id = s_1.paramset_id)))
             JOIN label label ON ((label.id = cl.label_id)))
          WHERE (cl.scheme_id = 1)
        UNION
         SELECT DISTINCT ((51)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#Mediaun label selected'::text AS description,
            true AS guisetting
           FROM ((search s_1
             JOIN chosen_label_scheme cl ON ((cl.paramset_id = s_1.paramset_id)))
             JOIN label label ON ((label.id = cl.label_id)))
          WHERE (cl.scheme_id = 1)
        UNION
         SELECT 51 AS o,
            s_1.id AS search_id,
            ('label:medium:'::text || label.description) AS description,
            true AS guisetting
           FROM ((search s_1
             JOIN chosen_label_scheme cl ON ((cl.paramset_id = s_1.paramset_id)))
             JOIN label label ON ((label.id = cl.label_id)))
          WHERE (cl.scheme_id = 2)
        UNION
         SELECT ((90)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#enzyme defined for digestion'::text AS description,
            true AS guisetting
           FROM search s_1
        UNION
         SELECT 90 AS o,
            s_1.id AS search_id,
                CASE
                    WHEN ("substring"(e.description, 1, 10) = 'digestion:'::text) THEN e.description
                    ELSE ('digestion:'::text || e.description)
                END AS description,
            true AS guisetting
           FROM ((search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
             JOIN enzyme e ON ((ps.enzyme_chosen = e.id)))
        UNION
         SELECT ((80)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#Tolerance for matching the precursor mass'::text AS description,
            true AS guisetting
           FROM search s_1
        UNION
         SELECT 80 AS o,
            s_1.id AS search_id,
            (('tolerance:precursor:'::text || ps.ms_tol) || (ps.ms_tol_unit)::text) AS description,
            true AS guisetting
           FROM (search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
        UNION
         SELECT ((81)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#Tolerance for matching the fragment masses'::text AS description,
            true AS guisetting
           FROM search s_1
        UNION
         SELECT 81 AS o,
            s_1.id AS search_id,
            (('tolerance:fragment:'::text || ps.ms2_tol) || (ps.ms2_tol_unit)::text) AS description,
            true AS guisetting
           FROM (search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
        UNION
         SELECT ((85)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#How many missed cleavages are to be considered.
# Be aware that variable modification or linked aminoacids are not known at the time of digest'::text AS description,
            true AS guisetting
           FROM search s_1
        UNION
         SELECT 85 AS o,
            s_1.id AS search_id,
            ('missedcleavages:'::text || ps.missed_cleavages) AS description,
            true AS guisetting
           FROM (search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
        UNION
         SELECT ((86)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#How many alpha-peptide candidates to considere'::text AS description,
            true AS guisetting
           FROM search s_1
        UNION
         SELECT 86 AS o,
            s_1.id AS search_id,
            ('topmgchits:'::text || ps.top_alpha_matches) AS description,
            true AS guisetting
           FROM (search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
        UNION
         SELECT ((100)::numeric - 0.1) AS o,
            s_1.id AS search_id,
            '#################
#deprecated'::text AS description,
            false AS guisetting
           FROM search s_1
        UNION
         SELECT 100 AS o,
            s_1.id AS search_id,
            ('synthetic:'::text || ps.synthetic) AS description,
            false AS guisetting
           FROM (search s_1
             JOIN parameter_set ps ON ((s_1.paramset_id = ps.id)))
        UNION
         SELECT 0 AS o,
            '-1'::integer AS search_id,
            (((bs.name)::text || ':'::text) || bs.setting) AS description,
            false AS guisetting
           FROM base_setting bs) s
  ORDER BY s.o, s.description;


ALTER TABLE xi_config_desc OWNER TO bio_user;

--
-- Name: acquisition id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY acquisition ALTER COLUMN id SET DEFAULT nextval('acquisition_id'::regclass);


--
-- Name: base_setting id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY base_setting ALTER COLUMN id SET DEFAULT nextval('base_setting_id_seq'::regclass);


--
-- Name: crosslinker id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY crosslinker ALTER COLUMN id SET DEFAULT nextval('crosslinker_id_seq'::regclass);


--
-- Name: enzyme id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY enzyme ALTER COLUMN id SET DEFAULT nextval('enzyme_id_seq'::regclass);


--
-- Name: ion id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY ion ALTER COLUMN id SET DEFAULT nextval('ion_id_seq'::regclass);


--
-- Name: label id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY label ALTER COLUMN id SET DEFAULT nextval('label_id_seq'::regclass);


--
-- Name: label_scheme id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY label_scheme ALTER COLUMN id SET DEFAULT nextval('label_scheme_id_seq'::regclass);


--
-- Name: loss id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY loss ALTER COLUMN id SET DEFAULT nextval('loss_id_seq'::regclass);


--
-- Name: match_type id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY match_type ALTER COLUMN id SET DEFAULT nextval('match_type_id_seq'::regclass);


--
-- Name: modification id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY modification ALTER COLUMN id SET DEFAULT nextval('modification_id_seq'::regclass);


--
-- Name: parameter_set id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY parameter_set ALTER COLUMN id SET DEFAULT nextval('parameter_set_id'::regclass);


--
-- Name: peaklistfile id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY peaklistfile ALTER COLUMN id SET DEFAULT nextval('peaklistfile_id_seq'::regclass);


--
-- Name: search id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY search ALTER COLUMN id SET DEFAULT nextval('search_id'::regclass);


--
-- Name: sequence_file id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY sequence_file ALTER COLUMN id SET DEFAULT nextval('sequence_file_id'::regclass);


--
-- Name: spectrum_source id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY spectrum_source ALTER COLUMN id SET DEFAULT nextval('spectrum_source_id_seq'::regclass);


--
-- Name: user_groups id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY user_groups ALTER COLUMN id SET DEFAULT nextval('user_groups_id'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id'::regclass);


--
-- Name: xiversions id; Type: DEFAULT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY xiversions ALTER COLUMN id SET DEFAULT nextval('seq_xiversion_ids'::regclass);


--
-- Name: acquisition acquisition_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY acquisition
    ADD CONSTRAINT acquisition_pkey PRIMARY KEY (id);


--
-- Name: base_setting base_setting_name_key; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY base_setting
    ADD CONSTRAINT base_setting_name_key UNIQUE (name);


--
-- Name: base_setting base_setting_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY base_setting
    ADD CONSTRAINT base_setting_pkey PRIMARY KEY (id);


--
-- Name: chosen_crosslinker chosen_crosslinker_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_crosslinker
    ADD CONSTRAINT chosen_crosslinker_pkey PRIMARY KEY (paramset_id, crosslinker_id);


--
-- Name: chosen_ions chosen_ions_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_ions
    ADD CONSTRAINT chosen_ions_pkey PRIMARY KEY (paramset_id, ion_id);


--
-- Name: chosen_label_scheme chosen_label_scheme_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_label_scheme
    ADD CONSTRAINT chosen_label_scheme_pkey PRIMARY KEY (paramset_id, scheme_id, label_id);


--
-- Name: chosen_losses chosen_losses_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_losses
    ADD CONSTRAINT chosen_losses_pkey PRIMARY KEY (paramset_id, loss_id);


--
-- Name: chosen_modification chosen_modification_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_modification
    ADD CONSTRAINT chosen_modification_pkey PRIMARY KEY (paramset_id, mod_id, fixed);


--
-- Name: crosslinker crosslinker_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY crosslinker
    ADD CONSTRAINT crosslinker_pkey PRIMARY KEY (id);


--
-- Name: enzyme enzyme_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY enzyme
    ADD CONSTRAINT enzyme_pkey PRIMARY KEY (id);


--
-- Name: has_protein has_protein_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY has_protein
    ADD CONSTRAINT has_protein_pkey PRIMARY KEY (peptide_id, protein_id, peptide_position);


--
-- Name: ion ion_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY ion
    ADD CONSTRAINT ion_pkey PRIMARY KEY (id);


--
-- Name: label label_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY label
    ADD CONSTRAINT label_pkey PRIMARY KEY (id);


--
-- Name: label_scheme label_scheme_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY label_scheme
    ADD CONSTRAINT label_scheme_pkey PRIMARY KEY (id);


--
-- Name: layouts layouts_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY layouts
    ADD CONSTRAINT layouts_pkey PRIMARY KEY (search_id, user_id, "time");


--
-- Name: loss loss_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY loss
    ADD CONSTRAINT loss_pkey PRIMARY KEY (id);


--
-- Name: match_type match_type_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY match_type
    ADD CONSTRAINT match_type_pkey PRIMARY KEY (id);


--
-- Name: matched_peptide matched_peptide_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY matched_peptide
    ADD CONSTRAINT matched_peptide_pkey PRIMARY KEY (match_id, peptide_id, match_type, link_position);


--
-- Name: modification modification_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY modification
    ADD CONSTRAINT modification_pkey PRIMARY KEY (id);


--
-- Name: parameter_set parameter_set_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY parameter_set
    ADD CONSTRAINT parameter_set_pkey PRIMARY KEY (id);


--
-- Name: peptide peptide_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY peptide
    ADD CONSTRAINT peptide_pkey PRIMARY KEY (id);


--
-- Name: fdrlevel pk_fdrlevel; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY fdrlevel
    ADD CONSTRAINT pk_fdrlevel PRIMARY KEY (level_id);


--
-- Name: peaklistfile pk_peaklistfileid; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY peaklistfile
    ADD CONSTRAINT pk_peaklistfileid PRIMARY KEY (id);


--
-- Name: spectrum_source pk_spectrum_source; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY spectrum_source
    ADD CONSTRAINT pk_spectrum_source PRIMARY KEY (id);


--
-- Name: xiversions pk_xiversion; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY xiversions
    ADD CONSTRAINT pk_xiversion PRIMARY KEY (id);


--
-- Name: protein protein_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY protein
    ADD CONSTRAINT protein_pkey PRIMARY KEY (id);


--
-- Name: run run_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY run
    ADD CONSTRAINT run_pkey PRIMARY KEY (acq_id, run_id);


--
-- Name: search_acquisition search_acquisition_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY search_acquisition
    ADD CONSTRAINT search_acquisition_pkey PRIMARY KEY (search_id, acq_id, run_id);


--
-- Name: search search_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY search
    ADD CONSTRAINT search_pkey PRIMARY KEY (id);


--
-- Name: search_sequencedb search_sequencedb_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY search_sequencedb
    ADD CONSTRAINT search_sequencedb_pkey PRIMARY KEY (search_id, seqdb_id);


--
-- Name: sequence_file sequence_file_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY sequence_file
    ADD CONSTRAINT sequence_file_pkey PRIMARY KEY (id);


--
-- Name: spectrum_match spectrum_match_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY spectrum_match
    ADD CONSTRAINT spectrum_match_pkey PRIMARY KEY (id);

ALTER TABLE spectrum_match CLUSTER ON spectrum_match_pkey;


--
-- Name: spectrum spectrum_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY spectrum
    ADD CONSTRAINT spectrum_pkey PRIMARY KEY (id);


--
-- Name: storage_ids storage_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY storage_ids
    ADD CONSTRAINT storage_ids_pkey PRIMARY KEY (name);


--
-- Name: uniprot uniprot_trembl_pk; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY uniprot
    ADD CONSTRAINT uniprot_trembl_pk PRIMARY KEY (accession);


--
-- Name: user_groups user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY user_groups
    ADD CONSTRAINT user_groups_pkey PRIMARY KEY (id);


--
-- Name: user_in_group user_in_group_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY user_in_group
    ADD CONSTRAINT user_in_group_pkey PRIMARY KEY (user_id, group_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_user_name_key; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_user_name_key UNIQUE (user_name);


--
-- Name: xiversions xiversions_version_key; Type: CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY xiversions
    ADD CONSTRAINT xiversions_version_key UNIQUE (version);


--
-- Name: isdecoy_searchid_idx; Type: INDEX; Schema: public; Owner: bio_user
--

CREATE INDEX isdecoy_searchid_idx ON spectrum_match USING btree (is_decoy, search_id);


--
-- Name: matched_peptide_link_position; Type: INDEX; Schema: public; Owner: bio_user
--

CREATE INDEX matched_peptide_link_position ON matched_peptide USING btree (link_position);


--
-- Name: matched_peptide_match_id_btree; Type: INDEX; Schema: public; Owner: bio_user
--

CREATE INDEX matched_peptide_match_id_btree ON matched_peptide USING btree (match_id);


--
-- Name: matched_peptide_search_idx; Type: INDEX; Schema: public; Owner: bio_user
--

CREATE INDEX matched_peptide_search_idx ON matched_peptide USING btree (search_id);


--
-- Name: protein_accession_number_idx; Type: INDEX; Schema: public; Owner: bio_user
--

CREATE INDEX protein_accession_number_idx ON protein USING btree (accession_number);


--
-- Name: spectrum_match_dynamic_rank_search_id_idx; Type: INDEX; Schema: public; Owner: bio_user
--

CREATE INDEX spectrum_match_dynamic_rank_search_id_idx ON spectrum_match USING btree (dynamic_rank, search_id);


--
-- Name: spectrum_match_rescored_idx; Type: INDEX; Schema: public; Owner: bio_user
--

CREATE INDEX spectrum_match_rescored_idx ON spectrum_match USING btree (rescored);


--
-- Name: spectrum_match_search_id_idx; Type: INDEX; Schema: public; Owner: bio_user
--

CREATE INDEX spectrum_match_search_id_idx ON spectrum_match USING btree (search_id);


--
-- Name: spectrum_match_spectrum_id; Type: INDEX; Schema: public; Owner: bio_user
--

CREATE INDEX spectrum_match_spectrum_id ON spectrum_match USING btree (spectrum_id);


--
-- Name: spectrum_peak_spectrum_idx; Type: INDEX; Schema: public; Owner: bio_user
--

CREATE INDEX spectrum_peak_spectrum_idx ON spectrum_peak USING btree (spectrum_id);


--
-- Name: version_index_component; Type: INDEX; Schema: public; Owner: bio_user
--

CREATE INDEX version_index_component ON version_number USING btree (component, current);


--
-- Name: search trigger_search_ping_on_update; Type: TRIGGER; Schema: public; Owner: bio_user
--

CREATE TRIGGER trigger_search_ping_on_update BEFORE UPDATE ON search FOR EACH ROW EXECUTE PROCEDURE search_ping_on_update();


--
-- Name: xiversions trigger_xiversions_single_default; Type: TRIGGER; Schema: public; Owner: bio_user
--

CREATE TRIGGER trigger_xiversions_single_default BEFORE UPDATE ON xiversions FOR EACH ROW EXECUTE PROCEDURE xiversions_single_default();


--
-- Name: acquisition acquisition_uploadedby_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY acquisition
    ADD CONSTRAINT acquisition_uploadedby_fkey FOREIGN KEY (uploadedby) REFERENCES users(id);


--
-- Name: chosen_crosslinker chosen_crosslinker_crosslinker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_crosslinker
    ADD CONSTRAINT chosen_crosslinker_crosslinker_id_fkey FOREIGN KEY (crosslinker_id) REFERENCES crosslinker(id);


--
-- Name: chosen_crosslinker chosen_crosslinker_paramset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_crosslinker
    ADD CONSTRAINT chosen_crosslinker_paramset_id_fkey FOREIGN KEY (paramset_id) REFERENCES parameter_set(id) ON DELETE CASCADE;


--
-- Name: chosen_ions chosen_ions_ion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_ions
    ADD CONSTRAINT chosen_ions_ion_id_fkey FOREIGN KEY (ion_id) REFERENCES ion(id);


--
-- Name: chosen_ions chosen_ions_paramset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_ions
    ADD CONSTRAINT chosen_ions_paramset_id_fkey FOREIGN KEY (paramset_id) REFERENCES parameter_set(id) ON DELETE CASCADE;


--
-- Name: chosen_label_scheme chosen_label_scheme_label_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_label_scheme
    ADD CONSTRAINT chosen_label_scheme_label_id_fkey FOREIGN KEY (label_id) REFERENCES label(id);


--
-- Name: chosen_label_scheme chosen_label_scheme_paramset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_label_scheme
    ADD CONSTRAINT chosen_label_scheme_paramset_id_fkey FOREIGN KEY (paramset_id) REFERENCES parameter_set(id) ON DELETE CASCADE;


--
-- Name: chosen_label_scheme chosen_label_scheme_scheme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_label_scheme
    ADD CONSTRAINT chosen_label_scheme_scheme_id_fkey FOREIGN KEY (scheme_id) REFERENCES label_scheme(id);


--
-- Name: chosen_losses chosen_losses_loss_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_losses
    ADD CONSTRAINT chosen_losses_loss_id_fkey FOREIGN KEY (loss_id) REFERENCES loss(id);


--
-- Name: chosen_losses chosen_losses_paramset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_losses
    ADD CONSTRAINT chosen_losses_paramset_id_fkey FOREIGN KEY (paramset_id) REFERENCES parameter_set(id) ON DELETE CASCADE;


--
-- Name: chosen_modification chosen_modification_mod_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_modification
    ADD CONSTRAINT chosen_modification_mod_id_fkey FOREIGN KEY (mod_id) REFERENCES modification(id);


--
-- Name: chosen_modification chosen_modification_paramset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY chosen_modification
    ADD CONSTRAINT chosen_modification_paramset_id_fkey FOREIGN KEY (paramset_id) REFERENCES parameter_set(id) ON DELETE CASCADE;


--
-- Name: protein fk_protein_sequence_file; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY protein
    ADD CONSTRAINT fk_protein_sequence_file FOREIGN KEY (seq_id) REFERENCES sequence_file(id);


--
-- Name: spectrum fk_spectrum_peaklist; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY spectrum
    ADD CONSTRAINT fk_spectrum_peaklist FOREIGN KEY (peaklist_id) REFERENCES peaklistfile(id);


--
-- Name: spectrum fk_spectrum_spectrum_source; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY spectrum
    ADD CONSTRAINT fk_spectrum_spectrum_source FOREIGN KEY (source_id) REFERENCES spectrum_source(id);


--
-- Name: has_protein has_protein_peptide_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY has_protein
    ADD CONSTRAINT has_protein_peptide_id_fkey FOREIGN KEY (peptide_id) REFERENCES peptide(id) ON DELETE CASCADE;


--
-- Name: has_protein has_protein_protein_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY has_protein
    ADD CONSTRAINT has_protein_protein_id_fkey FOREIGN KEY (protein_id) REFERENCES protein(id) ON DELETE CASCADE;


--
-- Name: matched_peptide matched_peptide_crosslinker_fk; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY matched_peptide
    ADD CONSTRAINT matched_peptide_crosslinker_fk FOREIGN KEY (crosslinker_id) REFERENCES crosslinker(id);


--
-- Name: matched_peptide matched_peptide_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY matched_peptide
    ADD CONSTRAINT matched_peptide_match_id_fkey FOREIGN KEY (match_id) REFERENCES spectrum_match(id) ON DELETE CASCADE;


--
-- Name: matched_peptide matched_peptide_match_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY matched_peptide
    ADD CONSTRAINT matched_peptide_match_type_fkey FOREIGN KEY (match_type) REFERENCES match_type(id);


--
-- Name: matched_peptide matched_peptide_peptide_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY matched_peptide
    ADD CONSTRAINT matched_peptide_peptide_id_fkey FOREIGN KEY (peptide_id) REFERENCES peptide(id) ON DELETE CASCADE;


--
-- Name: parameter_set parameter_set_enzyme_chosen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY parameter_set
    ADD CONSTRAINT parameter_set_enzyme_chosen_fkey FOREIGN KEY (enzyme_chosen) REFERENCES enzyme(id);


--
-- Name: run run_acq_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY run
    ADD CONSTRAINT run_acq_id_fkey FOREIGN KEY (acq_id) REFERENCES acquisition(id) ON DELETE CASCADE;


--
-- Name: search_acquisition search_acquisition_acq_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY search_acquisition
    ADD CONSTRAINT search_acquisition_acq_id_fkey FOREIGN KEY (acq_id, run_id) REFERENCES run(acq_id, run_id) ON DELETE CASCADE;


--
-- Name: search_acquisition search_acquisition_search_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY search_acquisition
    ADD CONSTRAINT search_acquisition_search_id_fkey FOREIGN KEY (search_id) REFERENCES search(id) ON DELETE CASCADE;


--
-- Name: search search_paramset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY search
    ADD CONSTRAINT search_paramset_id_fkey FOREIGN KEY (paramset_id) REFERENCES parameter_set(id);


--
-- Name: search_sequencedb search_sequencedb_search_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY search_sequencedb
    ADD CONSTRAINT search_sequencedb_search_id_fkey FOREIGN KEY (search_id) REFERENCES search(id) ON DELETE CASCADE;


--
-- Name: search_sequencedb search_sequencedb_seqdb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY search_sequencedb
    ADD CONSTRAINT search_sequencedb_seqdb_id_fkey FOREIGN KEY (seqdb_id) REFERENCES sequence_file(id) ON DELETE CASCADE;


--
-- Name: search search_uploadedby_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY search
    ADD CONSTRAINT search_uploadedby_fkey FOREIGN KEY (uploadedby) REFERENCES users(id);


--
-- Name: search search_visible_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY search
    ADD CONSTRAINT search_visible_group_fkey FOREIGN KEY (visible_group) REFERENCES user_groups(id);


--
-- Name: sequence_file sequence_file_uploadedby_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY sequence_file
    ADD CONSTRAINT sequence_file_uploadedby_fkey FOREIGN KEY (uploadedby) REFERENCES users(id);


--
-- Name: spectrum spectrum_acq_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY spectrum
    ADD CONSTRAINT spectrum_acq_id_fkey FOREIGN KEY (acq_id, run_id) REFERENCES run(acq_id, run_id) ON DELETE CASCADE;


--
-- Name: spectrum_match spectrum_match_search_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY spectrum_match
    ADD CONSTRAINT spectrum_match_search_id_fkey FOREIGN KEY (search_id) REFERENCES search(id) ON DELETE CASCADE;


--
-- Name: spectrum_match spectrum_match_spectrum_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY spectrum_match
    ADD CONSTRAINT spectrum_match_spectrum_id_fkey FOREIGN KEY (spectrum_id) REFERENCES spectrum(id) ON DELETE CASCADE;


--
-- Name: user_in_group user_in_group_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY user_in_group
    ADD CONSTRAINT user_in_group_group_id_fkey FOREIGN KEY (group_id) REFERENCES user_groups(id);


--
-- Name: user_in_group user_in_group_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bio_user
--

ALTER TABLE ONLY user_in_group
    ADD CONSTRAINT user_in_group_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: comma_concate(text, text); Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON FUNCTION comma_concate(text, text) TO bio_user;


--
-- Name: f_export(integer); Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON FUNCTION f_export(sid integer) TO bio_user;


--
-- Name: f_export(integer, boolean); Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON FUNCTION f_export(sid integer, dynamicrank boolean) TO bio_user;


--
-- Name: f_matched_proteins(integer, integer); Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON FUNCTION f_matched_proteins(sid integer, matchtype integer) TO bio_user;


--
-- Name: getdefaultxiversion(); Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON FUNCTION getdefaultxiversion() TO bio_user;


--
-- Name: randomstring(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION randomstring() TO bio_user;


--
-- Name: reserve_ids(character varying, bigint); Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON FUNCTION reserve_ids(sequence_name character varying, count bigint) TO bio_user;


--
-- Name: reserve_ids2(character varying, bigint); Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON FUNCTION reserve_ids2(sequence_name character varying, count bigint) TO bio_user;


--
-- Name: search_ping_on_update(); Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON FUNCTION search_ping_on_update() TO bio_user;


--
-- Name: xiversions_single_default(); Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON FUNCTION xiversions_single_default() TO bio_user;


--
-- Name: search; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE search TO bio_user;


--
-- Name: acquisition; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE acquisition TO bio_user;


--
-- Name: acquisition_id; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE acquisition_id TO bio_user;


--
-- Name: base_setting; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE base_setting TO bio_user;


--
-- Name: base_setting_id_seq; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE base_setting_id_seq TO bio_user;


--
-- Name: chosen_crosslinker; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE chosen_crosslinker TO bio_user;


--
-- Name: chosen_ions; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE chosen_ions TO bio_user;


--
-- Name: chosen_label_scheme; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE chosen_label_scheme TO bio_user;


--
-- Name: chosen_losses; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE chosen_losses TO bio_user;


--
-- Name: chosen_modification; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE chosen_modification TO bio_user;


--
-- Name: crosslinker; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE crosslinker TO bio_user;


--
-- Name: crosslinker_id_seq; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE crosslinker_id_seq TO bio_user;


--
-- Name: enzyme; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE enzyme TO bio_user;


--
-- Name: enzyme_id_seq; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE enzyme_id_seq TO bio_user;


--
-- Name: fdrlevel; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE fdrlevel TO bio_user;


--
-- Name: has_protein; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE has_protein TO bio_user;


--
-- Name: iaminberlin; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE iaminberlin TO bio_user;


--
-- Name: ion; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE ion TO bio_user;


--
-- Name: ion_id_seq; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE ion_id_seq TO bio_user;


--
-- Name: label; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE label TO bio_user;


--
-- Name: label_id_seq; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE label_id_seq TO bio_user;


--
-- Name: label_scheme; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE label_scheme TO bio_user;


--
-- Name: label_scheme_id_seq; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE label_scheme_id_seq TO bio_user;


--
-- Name: layouts; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE layouts TO bio_user;


--
-- Name: loss; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE loss TO bio_user;


--
-- Name: loss_id_seq; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE loss_id_seq TO bio_user;


--
-- Name: manual_annotations; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE manual_annotations TO bio_user;


--
-- Name: match_type; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE match_type TO bio_user;


--
-- Name: match_type_id_seq; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE match_type_id_seq TO bio_user;


--
-- Name: matched_peptide; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE matched_peptide TO bio_user;


--
-- Name: modification; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE modification TO bio_user;


--
-- Name: modification_id_seq; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE modification_id_seq TO bio_user;


--
-- Name: parameter_set; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE parameter_set TO bio_user;


--
-- Name: users; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE users TO bio_user;


--
-- Name: opentargetmodificationsearches; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE opentargetmodificationsearches TO bio_user;


--
-- Name: parameter_set_id; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE parameter_set_id TO bio_user;


--
-- Name: peaklistfile; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE peaklistfile TO bio_user;


--
-- Name: peaklistfile_id_seq; Type: ACL; Schema: public; Owner: bio_user
--

GRANT SELECT ON SEQUENCE peaklistfile_id_seq TO bio_user;


--
-- Name: peptide; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE peptide TO bio_user;


--
-- Name: protein; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE protein TO bio_user;


--
-- Name: run; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE run TO bio_user;


--
-- Name: score_id_seq; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE score_id_seq TO bio_user;


--
-- Name: search_acquisition; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE search_acquisition TO bio_user;


--
-- Name: search_id; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE search_id TO bio_user;


--
-- Name: search_sequencedb; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE search_sequencedb TO bio_user;


--
-- Name: xiversions; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE xiversions TO bio_user;


--
-- Name: seq_xiversion_ids; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE seq_xiversion_ids TO bio_user;


--
-- Name: sequence_file; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE sequence_file TO bio_user;


--
-- Name: sequence_file_id; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE sequence_file_id TO bio_user;


--
-- Name: showblocks; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE showblocks TO bio_user;


--
-- Name: spectrum; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE spectrum TO bio_user;


--
-- Name: spectrum_match; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE spectrum_match TO bio_user;


--
-- Name: spectrum_peak; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE spectrum_peak TO bio_user;


--
-- Name: spectrum_source; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE spectrum_source TO bio_user;


--
-- Name: spectrum_source_id_seq; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE spectrum_source_id_seq TO bio_user;


--
-- Name: storage_ids; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE storage_ids TO bio_user;


--
-- Name: uniprot; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE uniprot TO bio_user;


--
-- Name: user_groups; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE user_groups TO bio_user;


--
-- Name: user_groups_id; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE user_groups_id TO bio_user;


--
-- Name: user_in_group; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE user_in_group TO bio_user;


--
-- Name: users_id; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON SEQUENCE users_id TO bio_user;


--
-- Name: v_gettablesizes; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE v_gettablesizes TO bio_user;


--
-- Name: version_number; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE version_number TO bio_user;


--
-- Name: xi_config; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE xi_config TO bio_user;


--
-- Name: xi_config_desc; Type: ACL; Schema: public; Owner: bio_user
--

GRANT ALL ON TABLE xi_config_desc TO bio_user;


--
-- PostgreSQL database dump complete
--

