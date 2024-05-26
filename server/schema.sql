--
-- PostgreSQL database dump
--

-- Dumped from database version 14.11 (Homebrew)
-- Dumped by pg_dump version 14.11 (Homebrew)

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

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.accounts (
    id integer NOT NULL,
    item_id integer,
    name text NOT NULL,
    masked_account_number text,
    created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    plaid_account_id text,
    friendly_account_name character varying(255),
    type character varying(255),
    sub_type character varying(255)
);


ALTER TABLE public.accounts OWNER TO default;

--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.accounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_id_seq OWNER TO default;

--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: balances; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.balances (
    id integer NOT NULL,
    user_id integer,
    account_id integer,
    available numeric(10,2),
    current numeric(10,2),
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.balances OWNER TO default;

--
-- Name: balances_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.balances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.balances_id_seq OWNER TO default;

--
-- Name: balances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.balances_id_seq OWNED BY public.balances.id;


--
-- Name: budget_preferences; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.budget_preferences (
    id integer NOT NULL,
    user_id integer,
    category text,
    sub_category text,
    budget_category text,
    created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    product_category text,
    fixed_amount integer
);


ALTER TABLE public.budget_preferences OWNER TO default;

--
-- Name: budget_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.budget_preferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.budget_preferences_id_seq OWNER TO default;

--
-- Name: budget_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.budget_preferences_id_seq OWNED BY public.budget_preferences.id;


--
-- Name: institutions; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.institutions (
    id integer NOT NULL,
    plaid_institution_id character varying(255),
    institution_name character varying(255),
    logo_path character varying(255)
);


ALTER TABLE public.institutions OWNER TO default;

--
-- Name: institution_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.institution_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.institution_id_seq OWNER TO default;

--
-- Name: institution_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.institution_id_seq OWNED BY public.institutions.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.items (
    id integer NOT NULL,
    user_id integer,
    access_token text NOT NULL,
    transaction_cursor text,
    is_active boolean DEFAULT false NOT NULL,
    created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    plaid_item_id text,
    institution_id integer,
    plaid_cursor character varying(255)
);


ALTER TABLE public.items OWNER TO default;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.items_id_seq OWNER TO default;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.transactions (
    id integer NOT NULL,
    account_id integer,
    user_id integer,
    category text,
    sub_category text,
    date date,
    authorized_date date,
    name text NOT NULL,
    amount numeric(10,2) NOT NULL,
    currency_code character(3),
    is_removed boolean DEFAULT false NOT NULL,
    pending boolean DEFAULT false NOT NULL,
    plaid_transaction_id text,
    plaid_account_id text,
    merchant_name character varying(255),
    logo_url text,
    product_category character varying(255),
    budget_category character varying(255)
);


ALTER TABLE public.transactions OWNER TO default;

--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transactions_id_seq OWNER TO default;

--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.users (
    id integer NOT NULL,
    firstname character varying(50),
    lastname character varying(50),
    phone character varying(50),
    created timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    monthly_income numeric(10,2),
    monthly_fixed_spend numeric(10,2),
    birth_date date,
    session_token text,
    has_entered_user_details boolean,
    has_completed_account_creation boolean,
    has_completed_notification_selection boolean,
    push_notifications_enabled boolean,
    sms_notifications_enabled boolean,
    has_edited_budget_preferences boolean DEFAULT false,
    has_completed_budget_customization boolean DEFAULT false
);


ALTER TABLE public.users OWNER TO default;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO default;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- Name: balances id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.balances ALTER COLUMN id SET DEFAULT nextval('public.balances_id_seq'::regclass);


--
-- Name: budget_preferences id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.budget_preferences ALTER COLUMN id SET DEFAULT nextval('public.budget_preferences_id_seq'::regclass);


--
-- Name: institutions id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.institutions ALTER COLUMN id SET DEFAULT nextval('public.institution_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Name: transactions id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: balances balances_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.balances
    ADD CONSTRAINT balances_pkey PRIMARY KEY (id);


--
-- Name: budget_preferences budget_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.budget_preferences
    ADD CONSTRAINT budget_preferences_pkey PRIMARY KEY (id);


--
-- Name: institutions institution_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.institutions
    ADD CONSTRAINT institution_pkey PRIMARY KEY (id);


--
-- Name: institutions institution_plaid_institution_id_key; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.institutions
    ADD CONSTRAINT institution_plaid_institution_id_key UNIQUE (plaid_institution_id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: balances balances_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.balances
    ADD CONSTRAINT balances_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: balances balances_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.balances
    ADD CONSTRAINT balances_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: budget_preferences budget_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.budget_preferences
    ADD CONSTRAINT budget_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: items items_institution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_institution_id_fkey FOREIGN KEY (institution_id) REFERENCES public.institutions(id);


--
-- Name: items items_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: transactions transactions_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: transactions transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

