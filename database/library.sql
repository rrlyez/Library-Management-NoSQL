--
-- PostgreSQL database dump
--

\restrict G0AlYhhkg56OZVggZGoCeFZIbo7iAhdfwRqcJnFAbqOR5dfgYOHSGSrp0IEdJqz

-- Dumped from database version 18.2
-- Dumped by pg_dump version 18.2

-- Started on 2026-10-15 03:53:01

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 19471)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 5237 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- TOC entry 256 (class 1255 OID 19463)
-- Name: calculate_fine(date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_fine(p_due_date date, p_return_date date) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    days_late INTEGER;
BEGIN
    days_late := p_return_date - p_due_date;

    IF days_late > 0 THEN
        RETURN days_late * 5.00;
    ELSE
        RETURN 0.00;
    END IF;
END;
$$;


ALTER FUNCTION public.calculate_fine(p_due_date date, p_return_date date) OWNER TO postgres;

--
-- TOC entry 259 (class 1255 OID 19466)
-- Name: create_service_order(integer, integer, integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.create_service_order(IN p_reader_id integer, IN p_service_id integer, IN p_employee_id integer, IN p_quantity integer, IN p_updated_by integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_price DECIMAL(10,2);
BEGIN
    SELECT price
    INTO v_price
    FROM services
    WHERE service_id = p_service_id
      AND is_deleted = FALSE;

    INSERT INTO service_orders (
        reader_id,
        service_id,
        employee_id,
        quantity,
        total_price,
        order_date,
        status,
        updated_at,
        updated_by
    )
    VALUES (
        p_reader_id,
        p_service_id,
        p_employee_id,
        p_quantity,
        v_price * p_quantity,
        CURRENT_TIMESTAMP,
        'new',
        CURRENT_TIMESTAMP,
        p_updated_by
    );
END;
$$;


ALTER PROCEDURE public.create_service_order(IN p_reader_id integer, IN p_service_id integer, IN p_employee_id integer, IN p_quantity integer, IN p_updated_by integer) OWNER TO postgres;

--
-- TOC entry 255 (class 1255 OID 19462)
-- Name: get_available_copies(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_available_copies(p_book_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    copies_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO copies_count
    FROM book_copies
    WHERE book_id = p_book_id
      AND status = 'available'
      AND is_deleted = FALSE;

    RETURN copies_count;
END;
$$;


ALTER FUNCTION public.get_available_copies(p_book_id integer) OWNER TO postgres;

--
-- TOC entry 257 (class 1255 OID 19464)
-- Name: issue_book(integer, integer, integer, date, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.issue_book(IN p_copy_id integer, IN p_reader_id integer, IN p_employee_id integer, IN p_due_date date, IN p_updated_by integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO issues (
        copy_id,
        reader_id,
        employee_id,
        issue_date,
        due_date,
        return_date,
        status,
        updated_at,
        updated_by
    )
    VALUES (
        p_copy_id,
        p_reader_id,
        p_employee_id,
        CURRENT_DATE,
        p_due_date,
        NULL,
        'issued',
        CURRENT_TIMESTAMP,
        p_updated_by
    );

    UPDATE book_copies
    SET status = 'issued'
    WHERE copy_id = p_copy_id;
END;
$$;


ALTER PROCEDURE public.issue_book(IN p_copy_id integer, IN p_reader_id integer, IN p_employee_id integer, IN p_due_date date, IN p_updated_by integer) OWNER TO postgres;

--
-- TOC entry 258 (class 1255 OID 19465)
-- Name: return_book(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.return_book(IN p_issue_id integer, IN p_updated_by integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_copy_id INTEGER;
BEGIN
    SELECT copy_id
    INTO v_copy_id
    FROM issues
    WHERE issue_id = p_issue_id;

    UPDATE issues
    SET return_date = CURRENT_DATE,
        status = 'returned',
        updated_at = CURRENT_TIMESTAMP,
        updated_by = p_updated_by
    WHERE issue_id = p_issue_id;

    UPDATE book_copies
    SET status = 'available'
    WHERE copy_id = v_copy_id;
END;
$$;


ALTER PROCEDURE public.return_book(IN p_issue_id integer, IN p_updated_by integer) OWNER TO postgres;

--
-- TOC entry 260 (class 1255 OID 19467)
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 237 (class 1259 OID 19132)
-- Name: book_copies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.book_copies (
    copy_id integer NOT NULL,
    book_id integer NOT NULL,
    branch_id integer NOT NULL,
    inventory_number character varying(50) NOT NULL,
    status character varying(30) NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE public.book_copies OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 19073)
-- Name: books; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.books (
    book_id integer NOT NULL,
    title character varying(255) NOT NULL,
    isbn character varying(20) NOT NULL,
    publish_year integer,
    publisher_id integer NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    updated_at timestamp without time zone,
    updated_by integer
);


ALTER TABLE public.books OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 19178)
-- Name: issues; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.issues (
    issue_id integer NOT NULL,
    copy_id integer NOT NULL,
    reader_id integer NOT NULL,
    employee_id integer NOT NULL,
    issue_date date NOT NULL,
    due_date date NOT NULL,
    return_date date,
    status character varying(30) NOT NULL,
    updated_at timestamp without time zone,
    updated_by integer
);


ALTER TABLE public.issues OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 19158)
-- Name: readers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.readers (
    reader_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    phone character varying(30),
    email character varying(150),
    registration_date date NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    updated_at timestamp without time zone,
    updated_by integer
);


ALTER TABLE public.readers OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 19453)
-- Name: active_issues; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.active_issues AS
 SELECT i.issue_id,
    r.first_name,
    r.last_name,
    b.title,
    i.issue_date,
    i.due_date,
    i.status
   FROM (((public.issues i
     JOIN public.readers r ON ((i.reader_id = r.reader_id)))
     JOIN public.book_copies bc ON ((i.copy_id = bc.copy_id)))
     JOIN public.books b ON ((bc.book_id = b.book_id)))
  WHERE (i.return_date IS NULL);


ALTER VIEW public.active_issues OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 19004)
-- Name: authors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.authors (
    author_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL
);


ALTER TABLE public.authors OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 19003)
-- Name: authors_author_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.authors_author_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.authors_author_id_seq OWNER TO postgres;

--
-- TOC entry 5238 (class 0 OID 0)
-- Dependencies: 222
-- Name: authors_author_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.authors_author_id_seq OWNED BY public.authors.author_id;


--
-- TOC entry 227 (class 1259 OID 19025)
-- Name: library_branches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.library_branches (
    branch_id integer NOT NULL,
    name character varying(150) NOT NULL,
    address character varying(255) NOT NULL,
    phone character varying(30)
);


ALTER TABLE public.library_branches OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 19448)
-- Name: available_books; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.available_books AS
 SELECT b.book_id,
    b.title,
    bc.copy_id,
    bc.inventory_number,
    lb.name AS branch_name
   FROM ((public.books b
     JOIN public.book_copies bc ON ((b.book_id = bc.book_id)))
     JOIN public.library_branches lb ON ((bc.branch_id = lb.branch_id)))
  WHERE (((bc.status)::text = 'available'::text) AND (b.is_deleted = false) AND (bc.is_deleted = false));


ALTER VIEW public.available_books OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 19097)
-- Name: book_authors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.book_authors (
    book_id integer NOT NULL,
    author_id integer NOT NULL
);


ALTER TABLE public.book_authors OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 19131)
-- Name: book_copies_copy_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.book_copies_copy_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.book_copies_copy_id_seq OWNER TO postgres;

--
-- TOC entry 5239 (class 0 OID 0)
-- Dependencies: 236
-- Name: book_copies_copy_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.book_copies_copy_id_seq OWNED BY public.book_copies.copy_id;


--
-- TOC entry 235 (class 1259 OID 19114)
-- Name: book_genres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.book_genres (
    book_id integer NOT NULL,
    genre_id integer NOT NULL
);


ALTER TABLE public.book_genres OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 19072)
-- Name: books_book_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.books_book_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.books_book_id_seq OWNER TO postgres;

--
-- TOC entry 5240 (class 0 OID 0)
-- Dependencies: 232
-- Name: books_book_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.books_book_id_seq OWNED BY public.books.book_id;


--
-- TOC entry 229 (class 1259 OID 19035)
-- Name: employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employees (
    employee_id integer NOT NULL,
    branch_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    "position" character varying(100) NOT NULL,
    email character varying(150)
);


ALTER TABLE public.employees OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 19034)
-- Name: employees_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employees_employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employees_employee_id_seq OWNER TO postgres;

--
-- TOC entry 5241 (class 0 OID 0)
-- Dependencies: 228
-- Name: employees_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employees_employee_id_seq OWNED BY public.employees.employee_id;


--
-- TOC entry 245 (class 1259 OID 19241)
-- Name: fines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fines (
    fine_id integer NOT NULL,
    issue_id integer NOT NULL,
    reader_id integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    reason character varying(255),
    status character varying(30) NOT NULL
);


ALTER TABLE public.fines OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 19240)
-- Name: fines_fine_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fines_fine_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fines_fine_id_seq OWNER TO postgres;

--
-- TOC entry 5242 (class 0 OID 0)
-- Dependencies: 244
-- Name: fines_fine_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fines_fine_id_seq OWNED BY public.fines.fine_id;


--
-- TOC entry 225 (class 1259 OID 19014)
-- Name: genres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genres (
    genre_id integer NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.genres OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 19013)
-- Name: genres_genre_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.genres_genre_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.genres_genre_id_seq OWNER TO postgres;

--
-- TOC entry 5243 (class 0 OID 0)
-- Dependencies: 224
-- Name: genres_genre_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.genres_genre_id_seq OWNED BY public.genres.genre_id;


--
-- TOC entry 240 (class 1259 OID 19177)
-- Name: issues_issue_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.issues_issue_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.issues_issue_id_seq OWNER TO postgres;

--
-- TOC entry 5244 (class 0 OID 0)
-- Dependencies: 240
-- Name: issues_issue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.issues_issue_id_seq OWNED BY public.issues.issue_id;


--
-- TOC entry 226 (class 1259 OID 19024)
-- Name: library_branches_branch_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.library_branches_branch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.library_branches_branch_id_seq OWNER TO postgres;

--
-- TOC entry 5245 (class 0 OID 0)
-- Dependencies: 226
-- Name: library_branches_branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.library_branches_branch_id_seq OWNED BY public.library_branches.branch_id;


--
-- TOC entry 251 (class 1259 OID 19311)
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    payment_id integer NOT NULL,
    reader_id integer NOT NULL,
    fine_id integer,
    service_order_id integer,
    amount numeric(10,2) NOT NULL,
    payment_date timestamp without time zone NOT NULL,
    payment_method character varying(30) NOT NULL
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 19310)
-- Name: payments_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payments_payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payments_payment_id_seq OWNER TO postgres;

--
-- TOC entry 5246 (class 0 OID 0)
-- Dependencies: 250
-- Name: payments_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payments_payment_id_seq OWNED BY public.payments.payment_id;


--
-- TOC entry 221 (class 1259 OID 18995)
-- Name: publishers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.publishers (
    publisher_id integer NOT NULL,
    name character varying(150) NOT NULL,
    address character varying(255),
    phone character varying(30)
);


ALTER TABLE public.publishers OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 18994)
-- Name: publishers_publisher_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.publishers_publisher_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.publishers_publisher_id_seq OWNER TO postgres;

--
-- TOC entry 5247 (class 0 OID 0)
-- Dependencies: 220
-- Name: publishers_publisher_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.publishers_publisher_id_seq OWNED BY public.publishers.publisher_id;


--
-- TOC entry 254 (class 1259 OID 19458)
-- Name: reader_fines; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.reader_fines AS
 SELECT f.fine_id,
    r.reader_id,
    r.first_name,
    r.last_name,
    f.amount,
    f.reason,
    f.status
   FROM (public.fines f
     JOIN public.readers r ON ((f.reader_id = r.reader_id)));


ALTER VIEW public.reader_fines OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 19157)
-- Name: readers_reader_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.readers_reader_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.readers_reader_id_seq OWNER TO postgres;

--
-- TOC entry 5248 (class 0 OID 0)
-- Dependencies: 238
-- Name: readers_reader_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.readers_reader_id_seq OWNED BY public.readers.reader_id;


--
-- TOC entry 243 (class 1259 OID 19212)
-- Name: reservations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservations (
    reservation_id integer NOT NULL,
    reader_id integer NOT NULL,
    book_id integer NOT NULL,
    branch_id integer NOT NULL,
    reservation_date timestamp without time zone NOT NULL,
    expiration_date timestamp without time zone NOT NULL,
    status character varying(30) NOT NULL
);


ALTER TABLE public.reservations OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 19211)
-- Name: reservations_reservation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reservations_reservation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reservations_reservation_id_seq OWNER TO postgres;

--
-- TOC entry 5249 (class 0 OID 0)
-- Dependencies: 242
-- Name: reservations_reservation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reservations_reservation_id_seq OWNED BY public.reservations.reservation_id;


--
-- TOC entry 249 (class 1259 OID 19275)
-- Name: service_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_orders (
    service_order_id integer NOT NULL,
    reader_id integer NOT NULL,
    service_id integer NOT NULL,
    employee_id integer NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    total_price numeric(10,2) NOT NULL,
    order_date timestamp without time zone NOT NULL,
    status character varying(30) NOT NULL,
    updated_at timestamp without time zone,
    updated_by integer
);


ALTER TABLE public.service_orders OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 19274)
-- Name: service_orders_service_order_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.service_orders_service_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.service_orders_service_order_id_seq OWNER TO postgres;

--
-- TOC entry 5250 (class 0 OID 0)
-- Dependencies: 248
-- Name: service_orders_service_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_orders_service_order_id_seq OWNED BY public.service_orders.service_order_id;


--
-- TOC entry 247 (class 1259 OID 19263)
-- Name: services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.services (
    service_id integer NOT NULL,
    name character varying(150) NOT NULL,
    description character varying(255),
    price numeric(10,2) NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE public.services OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 19262)
-- Name: services_service_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.services_service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.services_service_id_seq OWNER TO postgres;

--
-- TOC entry 5251 (class 0 OID 0)
-- Dependencies: 246
-- Name: services_service_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.services_service_id_seq OWNED BY public.services.service_id;


--
-- TOC entry 231 (class 1259 OID 19052)
-- Name: user_accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_accounts (
    user_id integer NOT NULL,
    employee_id integer NOT NULL,
    username character varying(100) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(50) NOT NULL
);


ALTER TABLE public.user_accounts OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 19051)
-- Name: user_accounts_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_accounts_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_accounts_user_id_seq OWNER TO postgres;

--
-- TOC entry 5252 (class 0 OID 0)
-- Dependencies: 230
-- Name: user_accounts_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_accounts_user_id_seq OWNED BY public.user_accounts.user_id;


--
-- TOC entry 4954 (class 2604 OID 19007)
-- Name: authors author_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authors ALTER COLUMN author_id SET DEFAULT nextval('public.authors_author_id_seq'::regclass);


--
-- TOC entry 4961 (class 2604 OID 19135)
-- Name: book_copies copy_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_copies ALTER COLUMN copy_id SET DEFAULT nextval('public.book_copies_copy_id_seq'::regclass);


--
-- TOC entry 4959 (class 2604 OID 19076)
-- Name: books book_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books ALTER COLUMN book_id SET DEFAULT nextval('public.books_book_id_seq'::regclass);


--
-- TOC entry 4957 (class 2604 OID 19038)
-- Name: employees employee_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees ALTER COLUMN employee_id SET DEFAULT nextval('public.employees_employee_id_seq'::regclass);


--
-- TOC entry 4967 (class 2604 OID 19244)
-- Name: fines fine_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fines ALTER COLUMN fine_id SET DEFAULT nextval('public.fines_fine_id_seq'::regclass);


--
-- TOC entry 4955 (class 2604 OID 19017)
-- Name: genres genre_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres ALTER COLUMN genre_id SET DEFAULT nextval('public.genres_genre_id_seq'::regclass);


--
-- TOC entry 4965 (class 2604 OID 19181)
-- Name: issues issue_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.issues ALTER COLUMN issue_id SET DEFAULT nextval('public.issues_issue_id_seq'::regclass);


--
-- TOC entry 4956 (class 2604 OID 19028)
-- Name: library_branches branch_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.library_branches ALTER COLUMN branch_id SET DEFAULT nextval('public.library_branches_branch_id_seq'::regclass);


--
-- TOC entry 4972 (class 2604 OID 19314)
-- Name: payments payment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments ALTER COLUMN payment_id SET DEFAULT nextval('public.payments_payment_id_seq'::regclass);


--
-- TOC entry 4953 (class 2604 OID 18998)
-- Name: publishers publisher_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishers ALTER COLUMN publisher_id SET DEFAULT nextval('public.publishers_publisher_id_seq'::regclass);


--
-- TOC entry 4963 (class 2604 OID 19161)
-- Name: readers reader_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.readers ALTER COLUMN reader_id SET DEFAULT nextval('public.readers_reader_id_seq'::regclass);


--
-- TOC entry 4966 (class 2604 OID 19215)
-- Name: reservations reservation_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations ALTER COLUMN reservation_id SET DEFAULT nextval('public.reservations_reservation_id_seq'::regclass);


--
-- TOC entry 4970 (class 2604 OID 19278)
-- Name: service_orders service_order_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_orders ALTER COLUMN service_order_id SET DEFAULT nextval('public.service_orders_service_order_id_seq'::regclass);


--
-- TOC entry 4968 (class 2604 OID 19266)
-- Name: services service_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services ALTER COLUMN service_id SET DEFAULT nextval('public.services_service_id_seq'::regclass);


--
-- TOC entry 4958 (class 2604 OID 19055)
-- Name: user_accounts user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_accounts ALTER COLUMN user_id SET DEFAULT nextval('public.user_accounts_user_id_seq'::regclass);


--
-- TOC entry 5203 (class 0 OID 19004)
-- Dependencies: 223
-- Data for Name: authors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.authors (author_id, first_name, last_name) FROM stdin;
1	Anna	Ivanchenko
2	Max	Romanenko
3	Tom	Smit
\.


--
-- TOC entry 5214 (class 0 OID 19097)
-- Dependencies: 234
-- Data for Name: book_authors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.book_authors (book_id, author_id) FROM stdin;
1	1
2	2
3	3
\.


--
-- TOC entry 5217 (class 0 OID 19132)
-- Dependencies: 237
-- Data for Name: book_copies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.book_copies (copy_id, book_id, branch_id, inventory_number, status, is_deleted, deleted_at) FROM stdin;
2	2	1	2	available	f	\N
3	3	2	3	issued	f	\N
1	1	1	1	available	f	\N
\.


--
-- TOC entry 5215 (class 0 OID 19114)
-- Dependencies: 235
-- Data for Name: book_genres; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.book_genres (book_id, genre_id) FROM stdin;
1	1
2	2
3	3
\.


--
-- TOC entry 5213 (class 0 OID 19073)
-- Dependencies: 233
-- Data for Name: books; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.books (book_id, title, isbn, publish_year, publisher_id, is_deleted, deleted_at, updated_at, updated_by) FROM stdin;
2	Book 2	222222	2005	2	f	\N	2026-10-14 21:53:47.881918	1
3	Book 3	333333	2010	1	f	\N	2026-10-14 21:53:47.881918	2
1	Book 1 Updated	111111	2001	1	f	\N	2026-10-15 03:00:52.100009	1
\.


--
-- TOC entry 5209 (class 0 OID 19035)
-- Dependencies: 229
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employees (employee_id, branch_id, first_name, last_name, "position", email) FROM stdin;
1	1	Kate	Brown	Librarian	kate@mail.com
2	2	Alex	Green	Manager	alex@mail.com
\.


--
-- TOC entry 5225 (class 0 OID 19241)
-- Dependencies: 245
-- Data for Name: fines; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fines (fine_id, issue_id, reader_id, amount, reason, status) FROM stdin;
1	1	1	10.00	Late return	unpaid
\.


--
-- TOC entry 5205 (class 0 OID 19014)
-- Dependencies: 225
-- Data for Name: genres; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.genres (genre_id, name) FROM stdin;
1	Fantasy
2	Detective
3	Drama
\.


--
-- TOC entry 5221 (class 0 OID 19178)
-- Dependencies: 241
-- Data for Name: issues; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.issues (issue_id, copy_id, reader_id, employee_id, issue_date, due_date, return_date, status, updated_at, updated_by) FROM stdin;
1	2	1	1	2026-10-01	2026-10-10	2026-10-15	returned	2026-10-15 00:23:49.176227	1
3	3	2	1	2026-10-15	2026-10-25	\N	issued	2026-10-15 03:49:06.033568	1
2	1	2	1	2026-10-15	2026-10-25	2026-10-15	returned	2026-10-15 03:49:06.057393	1
\.


--
-- TOC entry 5207 (class 0 OID 19025)
-- Dependencies: 227
-- Data for Name: library_branches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.library_branches (branch_id, name, address, phone) FROM stdin;
1	Library 1	Street 1	111
2	Library 2	Street 2	222
\.


--
-- TOC entry 5231 (class 0 OID 19311)
-- Dependencies: 251
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (payment_id, reader_id, fine_id, service_order_id, amount, payment_date, payment_method) FROM stdin;
1	1	1	\N	10.00	2026-10-03 00:00:00	cash
2	1	\N	1	10.00	2026-10-03 00:00:00	card
\.


--
-- TOC entry 5201 (class 0 OID 18995)
-- Dependencies: 221
-- Data for Name: publishers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.publishers (publisher_id, name, address, phone) FROM stdin;
1	Publisher 1	Address 1	111
2	Publisher 2	Address 2	222
\.


--
-- TOC entry 5219 (class 0 OID 19158)
-- Dependencies: 239
-- Data for Name: readers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.readers (reader_id, first_name, last_name, phone, email, registration_date, is_deleted, deleted_at, updated_at, updated_by) FROM stdin;
2	Ivan	Black	222	ivan@mail.com	2026-02-01	f	\N	2026-10-14 21:53:47.881918	2
3	Mia	Grey	333	mia@mail.com	2026-03-01	f	\N	2026-10-14 21:53:47.881918	1
1	Olya	White	999	olya@mail.com	2026-01-01	f	\N	2026-10-15 03:02:14.15393	1
\.


--
-- TOC entry 5223 (class 0 OID 19212)
-- Dependencies: 243
-- Data for Name: reservations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reservations (reservation_id, reader_id, book_id, branch_id, reservation_date, expiration_date, status) FROM stdin;
1	2	1	1	2026-10-01 00:00:00	2026-10-05 00:00:00	active
\.


--
-- TOC entry 5229 (class 0 OID 19275)
-- Dependencies: 249
-- Data for Name: service_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_orders (service_order_id, reader_id, service_id, employee_id, quantity, total_price, order_date, status, updated_at, updated_by) FROM stdin;
1	1	1	1	2	10.00	2026-10-02 00:00:00	completed	2026-10-14 21:53:47.881918	1
2	2	1	1	3	15.00	2026-10-15 00:27:47.061044	new	2026-10-15 00:27:47.061044	1
\.


--
-- TOC entry 5227 (class 0 OID 19263)
-- Dependencies: 247
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.services (service_id, name, description, price, is_deleted, deleted_at) FROM stdin;
1	Print	Printing	5.00	f	\N
2	Scan	Scanning	3.00	f	\N
\.


--
-- TOC entry 5211 (class 0 OID 19052)
-- Dependencies: 231
-- Data for Name: user_accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_accounts (user_id, employee_id, username, password_hash, role) FROM stdin;
1	1	kate	123	librarian
2	2	alex	456	manager
\.


--
-- TOC entry 5253 (class 0 OID 0)
-- Dependencies: 222
-- Name: authors_author_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.authors_author_id_seq', 3, true);


--
-- TOC entry 5254 (class 0 OID 0)
-- Dependencies: 236
-- Name: book_copies_copy_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.book_copies_copy_id_seq', 3, true);


--
-- TOC entry 5255 (class 0 OID 0)
-- Dependencies: 232
-- Name: books_book_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.books_book_id_seq', 3, true);


--
-- TOC entry 5256 (class 0 OID 0)
-- Dependencies: 228
-- Name: employees_employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employees_employee_id_seq', 2, true);


--
-- TOC entry 5257 (class 0 OID 0)
-- Dependencies: 244
-- Name: fines_fine_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fines_fine_id_seq', 1, true);


--
-- TOC entry 5258 (class 0 OID 0)
-- Dependencies: 224
-- Name: genres_genre_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.genres_genre_id_seq', 3, true);


--
-- TOC entry 5259 (class 0 OID 0)
-- Dependencies: 240
-- Name: issues_issue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.issues_issue_id_seq', 3, true);


--
-- TOC entry 5260 (class 0 OID 0)
-- Dependencies: 226
-- Name: library_branches_branch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.library_branches_branch_id_seq', 2, true);


--
-- TOC entry 5261 (class 0 OID 0)
-- Dependencies: 250
-- Name: payments_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payments_payment_id_seq', 2, true);


--
-- TOC entry 5262 (class 0 OID 0)
-- Dependencies: 220
-- Name: publishers_publisher_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.publishers_publisher_id_seq', 2, true);


--
-- TOC entry 5263 (class 0 OID 0)
-- Dependencies: 238
-- Name: readers_reader_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.readers_reader_id_seq', 3, true);


--
-- TOC entry 5264 (class 0 OID 0)
-- Dependencies: 242
-- Name: reservations_reservation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reservations_reservation_id_seq', 1, true);


--
-- TOC entry 5265 (class 0 OID 0)
-- Dependencies: 248
-- Name: service_orders_service_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_orders_service_order_id_seq', 2, true);


--
-- TOC entry 5266 (class 0 OID 0)
-- Dependencies: 246
-- Name: services_service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.services_service_id_seq', 2, true);


--
-- TOC entry 5267 (class 0 OID 0)
-- Dependencies: 230
-- Name: user_accounts_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_accounts_user_id_seq', 2, true);


--
-- TOC entry 4976 (class 2606 OID 19012)
-- Name: authors authors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (author_id);


--
-- TOC entry 4998 (class 2606 OID 19103)
-- Name: book_authors book_authors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_authors
    ADD CONSTRAINT book_authors_pkey PRIMARY KEY (book_id, author_id);


--
-- TOC entry 5002 (class 2606 OID 19146)
-- Name: book_copies book_copies_inventory_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_copies
    ADD CONSTRAINT book_copies_inventory_number_key UNIQUE (inventory_number);


--
-- TOC entry 5004 (class 2606 OID 19144)
-- Name: book_copies book_copies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_copies
    ADD CONSTRAINT book_copies_pkey PRIMARY KEY (copy_id);


--
-- TOC entry 5000 (class 2606 OID 19120)
-- Name: book_genres book_genres_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_genres
    ADD CONSTRAINT book_genres_pkey PRIMARY KEY (book_id, genre_id);


--
-- TOC entry 4992 (class 2606 OID 19086)
-- Name: books books_isbn_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_isbn_key UNIQUE (isbn);


--
-- TOC entry 4994 (class 2606 OID 19084)
-- Name: books books_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (book_id);


--
-- TOC entry 4984 (class 2606 OID 19045)
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (employee_id);


--
-- TOC entry 5014 (class 2606 OID 19251)
-- Name: fines fines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fines
    ADD CONSTRAINT fines_pkey PRIMARY KEY (fine_id);


--
-- TOC entry 4978 (class 2606 OID 19023)
-- Name: genres genres_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_name_key UNIQUE (name);


--
-- TOC entry 4980 (class 2606 OID 19021)
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (genre_id);


--
-- TOC entry 5010 (class 2606 OID 19190)
-- Name: issues issues_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (issue_id);


--
-- TOC entry 4982 (class 2606 OID 19033)
-- Name: library_branches library_branches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.library_branches
    ADD CONSTRAINT library_branches_pkey PRIMARY KEY (branch_id);


--
-- TOC entry 5020 (class 2606 OID 19321)
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (payment_id);


--
-- TOC entry 4974 (class 2606 OID 19002)
-- Name: publishers publishers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT publishers_pkey PRIMARY KEY (publisher_id);


--
-- TOC entry 5006 (class 2606 OID 19171)
-- Name: readers readers_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.readers
    ADD CONSTRAINT readers_email_key UNIQUE (email);


--
-- TOC entry 5008 (class 2606 OID 19169)
-- Name: readers readers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.readers
    ADD CONSTRAINT readers_pkey PRIMARY KEY (reader_id);


--
-- TOC entry 5012 (class 2606 OID 19224)
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (reservation_id);


--
-- TOC entry 5018 (class 2606 OID 19289)
-- Name: service_orders service_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_orders
    ADD CONSTRAINT service_orders_pkey PRIMARY KEY (service_order_id);


--
-- TOC entry 5016 (class 2606 OID 19273)
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (service_id);


--
-- TOC entry 4986 (class 2606 OID 19064)
-- Name: user_accounts user_accounts_employee_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_accounts
    ADD CONSTRAINT user_accounts_employee_id_key UNIQUE (employee_id);


--
-- TOC entry 4988 (class 2606 OID 19062)
-- Name: user_accounts user_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_accounts
    ADD CONSTRAINT user_accounts_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4990 (class 2606 OID 19066)
-- Name: user_accounts user_accounts_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_accounts
    ADD CONSTRAINT user_accounts_username_key UNIQUE (username);


--
-- TOC entry 4995 (class 1259 OID 19470)
-- Name: idx_books_title; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_books_title ON public.books USING btree (title);


--
-- TOC entry 4996 (class 1259 OID 19552)
-- Name: idx_books_title_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_books_title_gin ON public.books USING gin (title public.gin_trgm_ops);


--
-- TOC entry 5048 (class 2620 OID 19468)
-- Name: books trg_books_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_books_updated_at BEFORE UPDATE ON public.books FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5049 (class 2620 OID 19469)
-- Name: readers trg_readers_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_readers_updated_at BEFORE UPDATE ON public.readers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5025 (class 2606 OID 19109)
-- Name: book_authors fk_book_author_author; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_authors
    ADD CONSTRAINT fk_book_author_author FOREIGN KEY (author_id) REFERENCES public.authors(author_id);


--
-- TOC entry 5026 (class 2606 OID 19104)
-- Name: book_authors fk_book_author_book; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_authors
    ADD CONSTRAINT fk_book_author_book FOREIGN KEY (book_id) REFERENCES public.books(book_id);


--
-- TOC entry 5027 (class 2606 OID 19121)
-- Name: book_genres fk_book_genre_book; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_genres
    ADD CONSTRAINT fk_book_genre_book FOREIGN KEY (book_id) REFERENCES public.books(book_id);


--
-- TOC entry 5028 (class 2606 OID 19126)
-- Name: book_genres fk_book_genre_genre; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_genres
    ADD CONSTRAINT fk_book_genre_genre FOREIGN KEY (genre_id) REFERENCES public.genres(genre_id);


--
-- TOC entry 5023 (class 2606 OID 19087)
-- Name: books fk_book_publisher; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) REFERENCES public.publishers(publisher_id);


--
-- TOC entry 5024 (class 2606 OID 19092)
-- Name: books fk_book_updated_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT fk_book_updated_by FOREIGN KEY (updated_by) REFERENCES public.user_accounts(user_id);


--
-- TOC entry 5029 (class 2606 OID 19147)
-- Name: book_copies fk_copy_book; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_copies
    ADD CONSTRAINT fk_copy_book FOREIGN KEY (book_id) REFERENCES public.books(book_id);


--
-- TOC entry 5030 (class 2606 OID 19152)
-- Name: book_copies fk_copy_branch; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_copies
    ADD CONSTRAINT fk_copy_branch FOREIGN KEY (branch_id) REFERENCES public.library_branches(branch_id);


--
-- TOC entry 5021 (class 2606 OID 19046)
-- Name: employees fk_employee_branch; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_employee_branch FOREIGN KEY (branch_id) REFERENCES public.library_branches(branch_id);


--
-- TOC entry 5039 (class 2606 OID 19252)
-- Name: fines fk_fine_issue; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fines
    ADD CONSTRAINT fk_fine_issue FOREIGN KEY (issue_id) REFERENCES public.issues(issue_id);


--
-- TOC entry 5040 (class 2606 OID 19257)
-- Name: fines fk_fine_reader; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fines
    ADD CONSTRAINT fk_fine_reader FOREIGN KEY (reader_id) REFERENCES public.readers(reader_id);


--
-- TOC entry 5032 (class 2606 OID 19191)
-- Name: issues fk_issue_copy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_issue_copy FOREIGN KEY (copy_id) REFERENCES public.book_copies(copy_id);


--
-- TOC entry 5033 (class 2606 OID 19201)
-- Name: issues fk_issue_employee; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_issue_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id);


--
-- TOC entry 5034 (class 2606 OID 19196)
-- Name: issues fk_issue_reader; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_issue_reader FOREIGN KEY (reader_id) REFERENCES public.readers(reader_id);


--
-- TOC entry 5035 (class 2606 OID 19206)
-- Name: issues fk_issue_updated_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT fk_issue_updated_by FOREIGN KEY (updated_by) REFERENCES public.user_accounts(user_id);


--
-- TOC entry 5045 (class 2606 OID 19327)
-- Name: payments fk_payment_fine; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_payment_fine FOREIGN KEY (fine_id) REFERENCES public.fines(fine_id);


--
-- TOC entry 5046 (class 2606 OID 19322)
-- Name: payments fk_payment_reader; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_payment_reader FOREIGN KEY (reader_id) REFERENCES public.readers(reader_id);


--
-- TOC entry 5047 (class 2606 OID 19332)
-- Name: payments fk_payment_service_order; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_payment_service_order FOREIGN KEY (service_order_id) REFERENCES public.service_orders(service_order_id);


--
-- TOC entry 5031 (class 2606 OID 19172)
-- Name: readers fk_reader_updated_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.readers
    ADD CONSTRAINT fk_reader_updated_by FOREIGN KEY (updated_by) REFERENCES public.user_accounts(user_id);


--
-- TOC entry 5036 (class 2606 OID 19230)
-- Name: reservations fk_reservation_book; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_reservation_book FOREIGN KEY (book_id) REFERENCES public.books(book_id);


--
-- TOC entry 5037 (class 2606 OID 19235)
-- Name: reservations fk_reservation_branch; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_reservation_branch FOREIGN KEY (branch_id) REFERENCES public.library_branches(branch_id);


--
-- TOC entry 5038 (class 2606 OID 19225)
-- Name: reservations fk_reservation_reader; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_reservation_reader FOREIGN KEY (reader_id) REFERENCES public.readers(reader_id);


--
-- TOC entry 5041 (class 2606 OID 19300)
-- Name: service_orders fk_service_order_employee; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_orders
    ADD CONSTRAINT fk_service_order_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id);


--
-- TOC entry 5042 (class 2606 OID 19290)
-- Name: service_orders fk_service_order_reader; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_orders
    ADD CONSTRAINT fk_service_order_reader FOREIGN KEY (reader_id) REFERENCES public.readers(reader_id);


--
-- TOC entry 5043 (class 2606 OID 19295)
-- Name: service_orders fk_service_order_service; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_orders
    ADD CONSTRAINT fk_service_order_service FOREIGN KEY (service_id) REFERENCES public.services(service_id);


--
-- TOC entry 5044 (class 2606 OID 19305)
-- Name: service_orders fk_service_order_updated_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_orders
    ADD CONSTRAINT fk_service_order_updated_by FOREIGN KEY (updated_by) REFERENCES public.user_accounts(user_id);


--
-- TOC entry 5022 (class 2606 OID 19067)
-- Name: user_accounts fk_user_employee; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_accounts
    ADD CONSTRAINT fk_user_employee FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id);


-- Completed on 2026-10-15 03:53:02

--
-- PostgreSQL database dump complete
--

\unrestrict G0AlYhhkg56OZVggZGoCeFZIbo7iAhdfwRqcJnFAbqOR5dfgYOHSGSrp0IEdJqz

