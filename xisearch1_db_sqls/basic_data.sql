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

SET search_path = public, pg_catalog;

--
-- Data for Name: base_setting; Type: TABLE DATA; Schema: public; Owner: bio_user
--

COPY base_setting (id, name, setting) FROM stdin;
1	base_directory_path	/Users/salman/xi_data/
4	IsotopPattern	Averagin
5	minCharge	3
12	TOPMATCHESONLY	false
13	topmgxhits	10
3	EVALUATELINEARS	true
2	UseCPUs	-2
11	sqlbuffer	100
10	BufferOutput	4000
9	BufferInput	1000
35	mgcpeaks	10
36	MINIMUM_TOP_SCORE	0
37	FRAGMENTTREE	FU
\.


--
-- Name: base_setting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bio_user
--

SELECT pg_catalog.setval('base_setting_id_seq', 37, true);


--
-- Data for Name: ion; Type: TABLE DATA; Schema: public; Owner: bio_user
--

COPY ion (id, name, description, is_default) FROM stdin;
1	b-ion	fragment:BIon	t
2	y-ion	fragment:YIon	t
3	precursor-ion	fragment:PeptideIon	t
4	c-ion	fragment:CIon	\N
5	x-ion	fragment:XIon	\N
6	a-ion	fragment:AIon	\N
7	z-ion	fragment:ZIon	\N
8	double_frag	fragment:BLikeDoubleFragmentation	\N
33	DSSO-A	loss:CleavableCrossLinkerPeptide:MASS:54.0105647;NAME:A	\N
34	DSSO-S	loss:CleavableCrossLinkerPeptide:MASS:103.9932001;NAME:S	\N
35	DSSO-T	loss:CleavableCrossLinkerPeptide:MASS:85.9826354;NAME:T	\N
\.


--
-- Name: ion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bio_user
--

SELECT pg_catalog.setval('ion_id_seq', 35, true);


--
-- Data for Name: loss; Type: TABLE DATA; Schema: public; Owner: bio_user
--

COPY loss (id, name, lost_mass, description, is_default) FROM stdin;
1	- H20	\N	loss:AminoAcidRestrictedLoss:NAME:H20;aminoacids:S,T,D,E;MASS:18.01056027;cterm	t
2	- NH3	\N	loss:AminoAcidRestrictedLoss:NAME:NH3;aminoacids:R,K,N,Q;MASS:17.02654493;nterm	t
4	- CH3SOH	\N	loss:AminoAcidRestrictedLoss:NAME:CH3SOH;aminoacids:Mox;MASS:63.99828547	t
3	- SO2	\N	loss:AminoAcidRestrictedLoss:NAME:SO2;aminoacids:Mox;MASS:63.96189	\N
5	- a ion	\N	loss:AIonLoss	\N
6	- H3PO4	97.976895625	loss:AminoAcidRestrictedLoss:NAME:H3PO4;aminoacids:Sp,Tp;MASS:97.976895625	\N
7	- Y-H3PO4	97.976895625	loss:AminoAcidRestrictedLoss:NAME:H3PO4;aminoacids:Yp;MASS:97.976895625	\N
13	Cross-Linker Break	\N	loss:CrosslinkerModified	\N
14	DTB_TS_1_211	211.144652925	loss:AminoAcidRestrictedLoss:NAME:DTB_TS_211;aminoacids:K,S,T,Y;MASS:211.144652925	\N
\.


--
-- Name: loss_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bio_user
--

SELECT pg_catalog.setval('loss_id_seq', 13, true);


--
-- Data for Name: match_type; Type: TABLE DATA; Schema: public; Owner: bio_user
--

COPY match_type (id, name) FROM stdin;
1	alpha
2	beta
3	linear
4	gamma
\.


--
-- Name: match_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bio_user
--

SELECT pg_catalog.setval('match_type_id_seq', 8, true);


--
-- Data for Name: storage_ids; Type: TABLE DATA; Schema: public; Owner: bio_user
--

COPY storage_ids (name, id_value) FROM stdin;
peak_annotation_id	1
fragment_id	1
peak_cluster_id	1
spectrum_id	1
spectrum_match_id	1
peptide_id	1
protein_id	1
run_id	1
peakfile_id	1
peak_id	1
\.


--
-- PostgreSQL database dump complete
--

