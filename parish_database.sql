-- Parish Management Database Schema
-- Supports tracking parishioners, families, sacraments, preparation courses,
-- pastoral events, and service participation.

CREATE TABLE families (
    family_id        SERIAL PRIMARY KEY,
    family_name      VARCHAR(120) NOT NULL,
    address_line1    VARCHAR(150),
    address_line2    VARCHAR(150),
    city             VARCHAR(80),
    postal_code      VARCHAR(20),
    phone_primary    VARCHAR(30),
    email            VARCHAR(120),
    notes            TEXT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE parishioners (
    parishioner_id   SERIAL PRIMARY KEY,
    family_id        INTEGER REFERENCES families(family_id) ON DELETE SET NULL,
    first_name       VARCHAR(60) NOT NULL,
    last_name        VARCHAR(80) NOT NULL,
    gender           VARCHAR(20),
    birth_date       DATE,
    baptism_parish   VARCHAR(120),
    marital_status   VARCHAR(40),
    phone_mobile     VARCHAR(30),
    phone_home       VARCHAR(30),
    email            VARCHAR(120),
    address_override BOOLEAN DEFAULT FALSE,
    address_line1    VARCHAR(150),
    address_line2    VARCHAR(150),
    city             VARCHAR(80),
    postal_code      VARCHAR(20),
    emergency_contact_name  VARCHAR(120),
    emergency_contact_phone VARCHAR(30),
    registration_date DATE DEFAULT CURRENT_DATE,
    status           VARCHAR(40) DEFAULT 'Active',
    occupation       VARCHAR(120),
    notes            TEXT
);

CREATE TABLE sacraments (
    sacrament_id   SERIAL PRIMARY KEY,
    name           VARCHAR(80) UNIQUE NOT NULL,
    description    TEXT
);

INSERT INTO sacraments (name, description) VALUES
    ('Baptism', 'Initiation sacrament'),
    ('First Communion', 'First Eucharist reception'),
    ('Confirmation', 'Sacrament of Confirmation'),
    ('Marriage', 'Sacrament of Matrimony'),
    ('Holy Orders', 'Ordination to ministry'),
    ('Anointing of the Sick', 'Sacrament of healing');

CREATE TABLE parishioner_sacraments (
    parishioner_sacrament_id SERIAL PRIMARY KEY,
    parishioner_id  INTEGER NOT NULL REFERENCES parishioners(parishioner_id) ON DELETE CASCADE,
    sacrament_id    INTEGER NOT NULL REFERENCES sacraments(sacrament_id) ON DELETE RESTRICT,
    sacrament_date  DATE,
    parish_name     VARCHAR(120),
    celebrant       VARCHAR(120),
    certificate_no  VARCHAR(60),
    notes           TEXT,
    CONSTRAINT unique_parishioner_sacrament UNIQUE (parishioner_id, sacrament_id)
);

CREATE TABLE sacrament_preparation_courses (
    course_id       SERIAL PRIMARY KEY,
    sacrament_id    INTEGER NOT NULL REFERENCES sacraments(sacrament_id) ON DELETE CASCADE,
    title           VARCHAR(120) NOT NULL,
    start_date      DATE,
    end_date        DATE,
    coordinator     VARCHAR(120),
    location        VARCHAR(150),
    notes           TEXT
);

CREATE TABLE course_registrations (
    course_registration_id SERIAL PRIMARY KEY,
    course_id       INTEGER NOT NULL REFERENCES sacrament_preparation_courses(course_id) ON DELETE CASCADE,
    parishioner_id  INTEGER NOT NULL REFERENCES parishioners(parishioner_id) ON DELETE CASCADE,
    registration_date DATE DEFAULT CURRENT_DATE,
    attendance_status VARCHAR(40) DEFAULT 'Enrolled',
    completion_date DATE,
    certificate_issued BOOLEAN DEFAULT FALSE,
    UNIQUE (course_id, parishioner_id)
);

CREATE TABLE ministries (
    ministry_id     SERIAL PRIMARY KEY,
    name            VARCHAR(120) NOT NULL,
    description     TEXT,
    coordinator     VARCHAR(120),
    meeting_schedule VARCHAR(120)
);

CREATE TABLE ministry_participation (
    ministry_participation_id SERIAL PRIMARY KEY,
    ministry_id     INTEGER NOT NULL REFERENCES ministries(ministry_id) ON DELETE CASCADE,
    parishioner_id  INTEGER NOT NULL REFERENCES parishioners(parishioner_id) ON DELETE CASCADE,
    start_date      DATE,
    end_date        DATE,
    role            VARCHAR(80),
    notes           TEXT,
    UNIQUE (ministry_id, parishioner_id, start_date)
);

CREATE TABLE pastoral_events (
    event_id        SERIAL PRIMARY KEY,
    title           VARCHAR(150) NOT NULL,
    description     TEXT,
    event_type      VARCHAR(60),
    start_datetime  TIMESTAMP,
    end_datetime    TIMESTAMP,
    location        VARCHAR(150),
    created_by      VARCHAR(120),
    notes           TEXT
);

CREATE TABLE event_registrations (
    event_registration_id SERIAL PRIMARY KEY,
    event_id        INTEGER NOT NULL REFERENCES pastoral_events(event_id) ON DELETE CASCADE,
    parishioner_id  INTEGER REFERENCES parishioners(parishioner_id) ON DELETE SET NULL,
    guest_name      VARCHAR(120),
    registration_date DATE DEFAULT CURRENT_DATE,
    attendance_status VARCHAR(40) DEFAULT 'Registered',
    notes           TEXT
);

CREATE TABLE donations (
    donation_id     SERIAL PRIMARY KEY,
    parishioner_id  INTEGER REFERENCES parishioners(parishioner_id) ON DELETE SET NULL,
    donation_date   DATE DEFAULT CURRENT_DATE,
    amount          NUMERIC(10,2) NOT NULL,
    donation_type   VARCHAR(60),
    payment_method  VARCHAR(40),
    receipt_number  VARCHAR(60),
    intention       VARCHAR(150),
    notes           TEXT
);

CREATE TABLE pastoral_visits (
    visit_id        SERIAL PRIMARY KEY,
    parishioner_id  INTEGER REFERENCES parishioners(parishioner_id) ON DELETE CASCADE,
    visit_date      DATE NOT NULL,
    minister_name   VARCHAR(120),
    purpose         VARCHAR(120),
    notes           TEXT
);

CREATE VIEW parishioner_overview AS
SELECT
    p.parishioner_id,
    p.first_name,
    p.last_name,
    COALESCE(p.address_line1, f.address_line1) AS address_line1,
    COALESCE(p.city, f.city) AS city,
    p.phone_mobile,
    p.email,
    p.status,
    ARRAY_AGG(s.name ORDER BY s.name) FILTER (WHERE s.name IS NOT NULL) AS sacraments
FROM parishioners p
LEFT JOIN families f ON p.family_id = f.family_id
LEFT JOIN parishioner_sacraments ps ON ps.parishioner_id = p.parishioner_id
LEFT JOIN sacraments s ON s.sacrament_id = ps.sacrament_id
GROUP BY p.parishioner_id, p.first_name, p.last_name, f.address_line1, f.city, p.address_line1, p.city, p.phone_mobile, p.email, p.status;

CREATE INDEX idx_parishioners_last_name ON parishioners(last_name);
CREATE INDEX idx_parishioner_sacraments_sacrament ON parishioner_sacraments(sacrament_id);
CREATE INDEX idx_donations_parishioner ON donations(parishioner_id);

-- End of schema
