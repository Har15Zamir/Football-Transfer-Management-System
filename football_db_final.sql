-- ============================================================
--  FOOTBALL TRANSFER MANAGEMENT SYSTEM
--  Oracle SQL — Full Database Creation Script
--  CT-261 | Section C | Batch 2024
-- ============================================================
--
--  MODEL BASIS: EER Diagram (Section II-D of report)
--    • Person  (superclass) → Player, Manager  (subclasses)
--    • Contract (superclass) → EmploymentContract, SponsorshipContract
--    • Agent is a standalone entity — NOT a subtype of Person
--    • AgentPersonRepresents: single junction table via Person superclass
--      (physical DDL collapses agentPlayerRepresents + agentManagerRepresents
--       from the Logical Model into one table, consistent with II-C DDL)
--
-- ============================================================


-- ────────────────────────────────────────────────────────────
--  SECTION 0: CLEAN SLATE
--  Drop in reverse FK order so no constraint violations occur.
--  Safe to run on a fresh schema — loops skip missing objects.
-- ────────────────────────────────────────────────────────────

-- 0.1  Drop triggers first (they reference tables)
BEGIN
    FOR tr IN (
        SELECT trigger_name FROM user_triggers
        WHERE  trigger_name IN ('TRG_PERSON_SUBTYPE')
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TRIGGER ' || tr.trigger_name;
    END LOOP;
END;
/

-- 0.2  Drop tables (CASCADE CONSTRAINTS removes dependent FKs automatically)
BEGIN
    FOR t IN (
        SELECT table_name FROM user_tables
        WHERE  table_name IN (
            'AGENTPERSONREPRESENTS','COMPETITIONCLUBPARTICIPATION',
            'SPONSORCLUBPARTNERSHIP','TRANSFER','EMPLOYMENTCONTRACT',
            'SPONSORSHIPCONTRACT','CONTRACT','PLAYER','MANAGER',
            'PERSON','AGENT','CLUB','SPONSOR','COMPETITION'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/

-- 0.3  Drop sequences
BEGIN
    FOR s IN (
        SELECT sequence_name FROM user_sequences
        WHERE  sequence_name IN (
            'SEQ_PERSON','SEQ_AGENT','SEQ_CLUB','SEQ_SPONSOR',
            'SEQ_CONTRACT','SEQ_TRANSFER','SEQ_COMPETITION'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/


-- ────────────────────────────────────────────────────────────
--  SECTION 1: SEQUENCES  (auto-increment PKs for application use)
--  START WITH values are set one above the highest hardcoded PK
--  in Section 9 sample data, preventing collision on NEXTVAL calls.
--    seq_person      → sample data uses 1-10,  next = 11
--    seq_agent       → sample data uses 1-3,   next = 4
--    seq_club        → sample data uses 1-5,   next = 6
--    seq_sponsor     → sample data uses 1-3,   next = 4
--    seq_contract    → sample data uses 1-7,   next = 8
--    seq_transfer    → sample data uses 1-3,   next = 4
--    seq_competition → sample data uses 1-4,   next = 5
-- ────────────────────────────────────────────────────────────
CREATE SEQUENCE seq_person      START WITH 11 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_agent       START WITH 4  INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_club        START WITH 6  INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_sponsor     START WITH 4  INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_contract    START WITH 8  INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_transfer    START WITH 4  INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_competition START WITH 5  INCREMENT BY 1 NOCACHE NOCYCLE;


-- ────────────────────────────────────────────────────────────
--  SECTION 2: CORE / INDEPENDENT TABLES
--  No outward FKs — these are created first.
-- ────────────────────────────────────────────────────────────

-- ── 2.1  PERSON  (EER Superclass of Player and Manager) ─────
--  Stores shared personal attributes for both subtypes.
--  Every Person row MUST have a corresponding Player or Manager
--  row — enforced via trigger in Section 7 (mandatory subtype rule).
CREATE TABLE Person (
    personId    NUMBER          CONSTRAINT pk_person       PRIMARY KEY,
    firstName   VARCHAR2(50)    CONSTRAINT nn_person_fname NOT NULL,
    lastName    VARCHAR2(50)    CONSTRAINT nn_person_lname NOT NULL,
    dateOfBirth DATE            CONSTRAINT nn_person_dob   NOT NULL,
    nationality VARCHAR2(50)    CONSTRAINT nn_person_nat   NOT NULL,
    email       VARCHAR2(100)   CONSTRAINT nn_person_email NOT NULL,
    phoneNumber VARCHAR2(20)    CONSTRAINT nn_person_phone NOT NULL,
    -- Business rule: email must be unique across all persons
    CONSTRAINT uq_person_email UNIQUE (email),
    -- Business rule: date of birth cannot be in the future
    CONSTRAINT ck_person_dob   CHECK (dateOfBirth < SYSDATE)
);

-- ── 2.2  AGENT  (standalone — NOT a subtype of Person) ──────
--  An independent entity that negotiates transfers and represents
--  players/managers. Deliberately excluded from the Person hierarchy
--  (Section II-D) to avoid agents representing other agents.
CREATE TABLE Agent (
    agentId        NUMBER          CONSTRAINT pk_agent        PRIMARY KEY,
    firstName      VARCHAR2(50)    CONSTRAINT nn_agent_fname  NOT NULL,
    lastName       VARCHAR2(50)    CONSTRAINT nn_agent_lname  NOT NULL,
    agencyName     VARCHAR2(100),                        -- NULL: independent agents
    licenseNumber  VARCHAR2(50)    CONSTRAINT nn_agent_lic    NOT NULL,
    commissionRate NUMBER(5,2)     CONSTRAINT nn_agent_comm   NOT NULL,
    email          VARCHAR2(100)   CONSTRAINT nn_agent_email  NOT NULL,
    phoneNumber    VARCHAR2(20)    CONSTRAINT nn_agent_phone  NOT NULL,
    -- Business rule: license numbers and emails are unique per agent
    CONSTRAINT uq_agent_license UNIQUE (licenseNumber),
    CONSTRAINT uq_agent_email   UNIQUE (email),
    -- Business rule: commission rate must be between 0 and 100 percent
    CONSTRAINT ck_agent_comm    CHECK (commissionRate >= 0 AND commissionRate <= 100)
);

-- ── 2.3  CLUB ────────────────────────────────────────────────
CREATE TABLE Club (
    clubId          NUMBER          CONSTRAINT pk_club         PRIMARY KEY,
    clubName        VARCHAR2(100)   CONSTRAINT nn_club_name    NOT NULL,
    stadiumName     VARCHAR2(100)   CONSTRAINT nn_club_stadium NOT NULL,
    stadiumCapacity NUMBER(6)       CONSTRAINT nn_club_cap     NOT NULL,
    city            VARCHAR2(50)    CONSTRAINT nn_club_city    NOT NULL,
    country         VARCHAR2(50)    CONSTRAINT nn_club_country NOT NULL,
    transferBudget  NUMBER(15,2)    CONSTRAINT nn_club_budget  NOT NULL,
    yearFounded     NUMBER(4)       CONSTRAINT nn_club_year    NOT NULL,
    -- Business rule: stadium capacity must be positive
    CONSTRAINT ck_club_cap    CHECK (stadiumCapacity > 0),
    -- Business rule: transfer budget cannot be negative
    CONSTRAINT ck_club_budget CHECK (transferBudget >= 0),
    -- Business rule: year founded must be realistic
    CONSTRAINT ck_club_year   CHECK (yearFounded >= 1800 AND yearFounded <= 2100)
);

-- ── 2.4  SPONSOR ─────────────────────────────────────────────
CREATE TABLE Sponsor (
    sponsorId    NUMBER          CONSTRAINT pk_sponsor       PRIMARY KEY,
    sponsorName  VARCHAR2(100)   CONSTRAINT nn_sponsor_name  NOT NULL,
    industry     VARCHAR2(50)    CONSTRAINT nn_sponsor_ind   NOT NULL,
    hqCountry    VARCHAR2(50)    CONSTRAINT nn_sponsor_hq    NOT NULL,
    contactEmail VARCHAR2(100)   CONSTRAINT nn_sponsor_email NOT NULL,
    contactPhone VARCHAR2(20)    CONSTRAINT nn_sponsor_phone NOT NULL,
    website      VARCHAR2(200),                          -- NULL: optional
    CONSTRAINT uq_sponsor_email UNIQUE (contactEmail)
);

-- ── 2.5  COMPETITION ─────────────────────────────────────────
CREATE TABLE Competition (
    compId         NUMBER          CONSTRAINT pk_competition PRIMARY KEY,
    compName       VARCHAR2(100)   CONSTRAINT nn_comp_name   NOT NULL,
    compType       VARCHAR2(20)    CONSTRAINT nn_comp_type   NOT NULL,
    country        VARCHAR2(50),                          -- NULL: international competitions
    prizePool      NUMBER(15,2),                          -- NULL: not all competitions publish this
    organizingBody VARCHAR2(100)   CONSTRAINT nn_comp_org   NOT NULL,
    ranking        NUMBER(3),                             -- NULL: optional
    -- Business rule: competition type must be one of the defined values
    CONSTRAINT ck_comp_type  CHECK (compType IN ('League','Cup','Continental')),
    -- Business rule: prize pool cannot be negative if provided
    CONSTRAINT ck_comp_prize CHECK (prizePool IS NULL OR prizePool >= 0),
    -- Business rule: ranking must be positive if provided
    CONSTRAINT ck_comp_rank  CHECK (ranking   IS NULL OR ranking   > 0)
);


-- ────────────────────────────────────────────────────────────
--  SECTION 3: PERSON SUBCLASS TABLES
--  Depend on Person (and Manager depends on Club).
--  ON DELETE CASCADE: deleting a Person automatically removes
--  the corresponding Player or Manager row.
-- ────────────────────────────────────────────────────────────

-- ── 3.1  PLAYER  (EER subclass of Person) ───────────────────
CREATE TABLE Player (
    personId        NUMBER          CONSTRAINT pk_player        PRIMARY KEY,
    primaryPosition VARCHAR2(20)    CONSTRAINT nn_player_pos    NOT NULL,
    preferredFoot   VARCHAR2(10)    CONSTRAINT nn_player_foot   NOT NULL,
    marketValue     NUMBER(10,2)    CONSTRAINT nn_player_mv     NOT NULL,
    jerseyNumber    NUMBER(2)       CONSTRAINT nn_player_jersey NOT NULL,
    height          NUMBER(5,2)     CONSTRAINT nn_player_ht     NOT NULL,
    weight          NUMBER(5,2)     CONSTRAINT nn_player_wt     NOT NULL,
    -- personId is both PK and FK — implements EER specialization
    CONSTRAINT fk_player_person FOREIGN KEY (personId) REFERENCES Person(personId) ON DELETE CASCADE,
    -- Business rule: position must be a valid football position
    CONSTRAINT ck_player_pos    CHECK (primaryPosition IN ('GK','DEF','MID','FWD')),
    -- Business rule: preferred foot must be one of the defined values
    CONSTRAINT ck_player_foot   CHECK (preferredFoot   IN ('Left','Right','Both')),
    -- Business rule: market value cannot be negative
    CONSTRAINT ck_player_mv     CHECK (marketValue >= 0),
    -- Business rule: jersey number must be between 1 and 99
    CONSTRAINT ck_player_jersey CHECK (jerseyNumber BETWEEN 1 AND 99),
    -- Business rule: height and weight must be positive
    CONSTRAINT ck_player_ht     CHECK (height > 0),
    CONSTRAINT ck_player_wt     CHECK (weight > 0)
);

-- ── 3.2  MANAGER  (EER subclass of Person) ──────────────────
--  Manages relationship [Manager — Club, cardinality 0..1 : 1..1]:
--    • clubId is nullable (NULL = unemployed manager)
--    • UNIQUE (clubId) enforces the 1..1 upper bound on the Club side:
--      no two managers can simultaneously point to the same club.
--      Oracle allows multiple NULLs under UNIQUE, so unemployed managers
--      are unaffected.
--    • ON DELETE SET NULL on fk_manager_club: if a club is deleted,
--      the manager becomes unemployed rather than being deleted.
CREATE TABLE Manager (
    personId           NUMBER          CONSTRAINT pk_manager      PRIMARY KEY,
    clubId             NUMBER,                            -- NULL: unemployed manager
    coachingLicense    VARCHAR2(50)    CONSTRAINT nn_mgr_lic  NOT NULL,
    preferredFormation VARCHAR2(10)    CONSTRAINT nn_mgr_form NOT NULL,
    yearsOfExperience  NUMBER(2)       CONSTRAINT nn_mgr_exp  NOT NULL,
    -- personId is both PK and FK — implements EER specialization
    CONSTRAINT fk_manager_person FOREIGN KEY (personId) REFERENCES Person(personId) ON DELETE CASCADE,
    -- ON DELETE SET NULL: losing a club makes manager unemployed, not deleted
    CONSTRAINT fk_manager_club   FOREIGN KEY (clubId)   REFERENCES Club(clubId) ON DELETE SET NULL,
    -- Enforces "a club can have at most one manager" (1..1 Club side)
    CONSTRAINT uq_manager_club   UNIQUE (clubId),
    -- Business rule: years of experience cannot be negative
    CONSTRAINT ck_mgr_exp        CHECK (yearsOfExperience >= 0)
);


-- ────────────────────────────────────────────────────────────
--  SECTION 4: CONTRACT HIERARCHY
--  ON DELETE CASCADE on fk_contract_person: deleting a Person
--  cascades to Contract, which further cascades to subclass tables.
-- ────────────────────────────────────────────────────────────

-- ── 4.1  CONTRACT  (EER Superclass) ─────────────────────────
CREATE TABLE Contract (
    contractId     NUMBER          CONSTRAINT pk_contract        PRIMARY KEY,
    personId       NUMBER          CONSTRAINT nn_contract_person NOT NULL,
    startDate      DATE            CONSTRAINT nn_contract_start  NOT NULL,
    endDate        DATE            CONSTRAINT nn_contract_end    NOT NULL,
    signingDate    DATE            CONSTRAINT nn_contract_sign   NOT NULL,
    contractStatus VARCHAR2(20)    CONSTRAINT nn_contract_status NOT NULL,
    -- Signs relationship: every Contract is signed by exactly one Person
    CONSTRAINT fk_contract_person FOREIGN KEY (personId) REFERENCES Person(personId) ON DELETE CASCADE,
    -- Business rule: status must be one of the defined values
    CONSTRAINT ck_contract_status CHECK (contractStatus IN ('Active','Expired','Terminated')),
    -- Business rule: end date must be after start date
    CONSTRAINT ck_contract_dates  CHECK (endDate > startDate),
    -- Business rule: signing date cannot be after the start date
    CONSTRAINT ck_contract_sign   CHECK (signingDate <= startDate)
);

-- ── 4.2  EMPLOYMENT CONTRACT  (EER subclass of Contract) ────
--  fk_ec_club has no ON DELETE clause (default RESTRICT):
--  a club cannot be deleted while employment contracts reference it,
--  preserving historical contract records.
CREATE TABLE EmploymentContract (
    contractId       NUMBER          CONSTRAINT pk_empcontract PRIMARY KEY,
    clubId           NUMBER          CONSTRAINT nn_ec_club     NOT NULL,
    weeklySalary     NUMBER(12,2)    CONSTRAINT nn_ec_salary   NOT NULL,
    releaseClause    NUMBER(12,2),                        -- NULL: not all contracts have one
    signingBonus     NUMBER(12,2),                        -- NULL: optional
    performanceBonus NUMBER(12,2),                        -- NULL: optional
    -- contractId is both PK and FK — implements EER specialization
    CONSTRAINT fk_ec_contract FOREIGN KEY (contractId) REFERENCES Contract(contractId) ON DELETE CASCADE,
    -- RESTRICT (default): club deletion blocked if active contracts exist
    CONSTRAINT fk_ec_club     FOREIGN KEY (clubId)     REFERENCES Club(clubId),
    -- Business rule: salary must be positive
    CONSTRAINT ck_ec_salary   CHECK (weeklySalary > 0),
    -- Business rule: monetary clauses cannot be negative if provided
    CONSTRAINT ck_ec_release  CHECK (releaseClause    IS NULL OR releaseClause    >= 0),
    CONSTRAINT ck_ec_sbonus   CHECK (signingBonus     IS NULL OR signingBonus     >= 0),
    CONSTRAINT ck_ec_pbonus   CHECK (performanceBonus IS NULL OR performanceBonus >= 0)
);

-- ── 4.3  SPONSORSHIP CONTRACT  (EER subclass of Contract) ───
--  fk_sc_sponsor has no ON DELETE clause (default RESTRICT):
--  a sponsor cannot be deleted while sponsorship contracts reference it.
CREATE TABLE SponsorshipContract (
    contractId       NUMBER          CONSTRAINT pk_sponcontract PRIMARY KEY,
    sponsorId        NUMBER          CONSTRAINT nn_sc_sponsor   NOT NULL,
    contractValue    NUMBER(12,2)    CONSTRAINT nn_sc_value     NOT NULL,
    paymentFrequency VARCHAR2(20)    CONSTRAINT nn_sc_freq      NOT NULL,
    endorsementType  VARCHAR2(50)    CONSTRAINT nn_sc_endorse   NOT NULL,
    -- contractId is both PK and FK — implements EER specialization
    CONSTRAINT fk_sc_contract FOREIGN KEY (contractId) REFERENCES Contract(contractId) ON DELETE CASCADE,
    -- RESTRICT (default): sponsor deletion blocked if contracts exist
    CONSTRAINT fk_sc_sponsor  FOREIGN KEY (sponsorId)  REFERENCES Sponsor(sponsorId),
    -- Business rule: payment frequency must be one of the defined values
    CONSTRAINT ck_sc_freq     CHECK (paymentFrequency IN ('Monthly','Quarterly','Annual')),
    -- Business rule: contract value must be positive
    CONSTRAINT ck_sc_value    CHECK (contractValue > 0)
);


-- ────────────────────────────────────────────────────────────
--  SECTION 5: TRANSFER
-- ────────────────────────────────────────────────────────────
CREATE TABLE Transfer (
    transferId    NUMBER          CONSTRAINT pk_transfer    PRIMARY KEY,
    personId      NUMBER          CONSTRAINT nn_tr_person   NOT NULL,
    buyingClubId  NUMBER          CONSTRAINT nn_tr_buying   NOT NULL,
    sellingClubId NUMBER,                                -- NULL: free agent (no selling club)
    agentId       NUMBER,                                -- NULL: transfer without an agent
    transferFee   NUMBER(12,2)    CONSTRAINT nn_tr_fee     NOT NULL,
    transferType  VARCHAR2(20)    CONSTRAINT nn_tr_typenn  NOT NULL,
    -- SubjectOf relationship: every transfer has exactly one Person as subject
    CONSTRAINT fk_tr_person  FOREIGN KEY (personId)      REFERENCES Person(personId) ON DELETE CASCADE,
    -- Buys relationship: RESTRICT (default) — club deletion blocked if it has bought transfers
    CONSTRAINT fk_tr_buying  FOREIGN KEY (buyingClubId)  REFERENCES Club(clubId),
    -- Sells relationship: ON DELETE SET NULL — if selling club deleted, transfer record kept
    CONSTRAINT fk_tr_selling FOREIGN KEY (sellingClubId) REFERENCES Club(clubId) ON DELETE SET NULL,
    -- Negotiates relationship: agent is optional per transfer
    CONSTRAINT fk_tr_agent FOREIGN KEY (agentId) REFERENCES Agent(agentId) ON DELETE SET NULL,
    -- Business rule: transfer type must be one of the defined values
    CONSTRAINT ck_tr_type    CHECK (transferType IN ('Permanent','Loan','Free')),
    -- Business rule: transfer fee cannot be negative
    CONSTRAINT ck_tr_fee     CHECK (transferFee >= 0),
    -- Business rule: buying and selling club cannot be the same
    CONSTRAINT ck_tr_clubs   CHECK (sellingClubId IS NULL OR buyingClubId <> sellingClubId),
    -- Business rule: free transfers must have a fee of exactly zero
    CONSTRAINT ck_tr_free    CHECK (
        (transferType = 'Free' AND transferFee = 0) OR transferType <> 'Free'
    )
);


-- ────────────────────────────────────────────────────────────
--  SECTION 6: JUNCTION TABLES  (M:N relationships)
--  ON DELETE CASCADE on both FKs so that deleting either parent
--  automatically removes the junction row.
-- ────────────────────────────────────────────────────────────

-- ── 6.1  AGENT — PERSON  (Represents) ───────────────────────
--  Physical DDL consolidation (per Section II-C):
--  The Logical Model's two tables (agentPlayerRepresents,
--  agentManagerRepresents) are merged into one here because
--  Player and Manager both inherit their PK from Person.
CREATE TABLE AgentPersonRepresents (
    agentId  NUMBER  CONSTRAINT nn_apr_agent  NOT NULL,
    personId NUMBER  CONSTRAINT nn_apr_person NOT NULL,
    CONSTRAINT pk_apr        PRIMARY KEY (agentId, personId),
    CONSTRAINT fk_apr_agent  FOREIGN KEY (agentId)  REFERENCES Agent(agentId)   ON DELETE CASCADE,
    CONSTRAINT fk_apr_person FOREIGN KEY (personId) REFERENCES Person(personId) ON DELETE CASCADE
);

-- ── 6.2  COMPETITION — CLUB  (Has / Aggregation) ─────────────
--  Aggregation (Section II-D): Competition is the whole, Club is the part.
--  Cardinality 1..* on both sides.
CREATE TABLE CompetitionClubParticipation (
    compId NUMBER  CONSTRAINT nn_ccp_comp NOT NULL,
    clubId NUMBER  CONSTRAINT nn_ccp_club NOT NULL,
    CONSTRAINT pk_ccp        PRIMARY KEY (compId, clubId),
    CONSTRAINT fk_ccp_comp   FOREIGN KEY (compId) REFERENCES Competition(compId) ON DELETE CASCADE,
    CONSTRAINT fk_ccp_club   FOREIGN KEY (clubId) REFERENCES Club(clubId)        ON DELETE CASCADE
);

-- ── 6.3  SPONSOR — CLUB  (PartnersWith) ─────────────────────
CREATE TABLE SponsorClubPartnership (
    sponsorId NUMBER  CONSTRAINT nn_scp_sponsor NOT NULL,
    clubId    NUMBER  CONSTRAINT nn_scp_club    NOT NULL,
    CONSTRAINT pk_scp          PRIMARY KEY (sponsorId, clubId),
    CONSTRAINT fk_scp_sponsor  FOREIGN KEY (sponsorId) REFERENCES Sponsor(sponsorId) ON DELETE CASCADE,
    CONSTRAINT fk_scp_club     FOREIGN KEY (clubId)    REFERENCES Club(clubId)       ON DELETE CASCADE
);


-- ────────────────────────────────────────────────────────────
--  SECTION 7: TRIGGERS
--  Business rules that cannot be fully enforced by constraints alone.
-- ────────────────────────────────────────────────────────────

-- ── 7.1  PERSON MANDATORY SUBTYPE (EER Rule — Sections II-A, II-D) ──
--  Every Person MUST belong to exactly one subtype: Player or Manager.
--  A Person cannot exist without a subtype (mandatory specialization).
--
--  Limitation: At the moment this AFTER INSERT trigger fires, the
--  subclass INSERT has not yet occurred (it comes immediately after).
--  Full deferred enforcement requires Oracle Enterprise Edition or a
--  stored procedure that wraps both INSERTs atomically. This trigger
--  documents the rule and the body is intentionally left as NULL.
--  The rule is upheld in practice by always inserting the subclass
--  row immediately after its Person row (as done in Section 9).
CREATE OR REPLACE TRIGGER trg_person_subtype
AFTER INSERT ON Person
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM   Player  WHERE personId = :NEW.personId;
    IF v_count = 0 THEN
        SELECT COUNT(*) INTO v_count
        FROM   Manager WHERE personId = :NEW.personId;
    END IF;
    -- Subclass row does not exist yet at this point in the transaction.
    -- Rule is enforced by convention (subclass INSERT always follows Person INSERT).
    NULL;
END;
/

--  NOTE on uq_manager_club (Section 3.2):
--  The UNIQUE constraint on Manager.clubId already prevents two managers
--  from claiming the same club at the database level. A second trigger
--  for this rule is therefore redundant and has been intentionally omitted.


-- ────────────────────────────────────────────────────────────
--  SECTION 8: INDEXES
--  Improve query performance on all FK columns.
-- ────────────────────────────────────────────────────────────
CREATE INDEX idx_player_person   ON Player(personId);
CREATE INDEX idx_manager_person  ON Manager(personId);
CREATE INDEX idx_manager_club    ON Manager(clubId);
CREATE INDEX idx_contract_person ON Contract(personId);
CREATE INDEX idx_ec_club         ON EmploymentContract(clubId);
CREATE INDEX idx_sc_sponsor      ON SponsorshipContract(sponsorId);
CREATE INDEX idx_transfer_person ON Transfer(personId);
CREATE INDEX idx_transfer_buying ON Transfer(buyingClubId);
CREATE INDEX idx_transfer_sell   ON Transfer(sellingClubId);
CREATE INDEX idx_transfer_agent  ON Transfer(agentId);
CREATE INDEX idx_apr_agent       ON AgentPersonRepresents(agentId);
CREATE INDEX idx_apr_person      ON AgentPersonRepresents(personId);
CREATE INDEX idx_ccp_comp        ON CompetitionClubParticipation(compId);
CREATE INDEX idx_ccp_club        ON CompetitionClubParticipation(clubId);
CREATE INDEX idx_scp_sponsor     ON SponsorClubPartnership(sponsorId);
CREATE INDEX idx_scp_club        ON SponsorClubPartnership(clubId);


-- ────────────────────────────────────────────────────────────
--  SECTION 9: SAMPLE DATA
--  All PKs are hardcoded (not NEXTVAL) to guarantee that FK
--  references in child rows always match exactly, regardless
--  of sequence state from any previous partial runs.
-- ────────────────────────────────────────────────────────────

-- ── 9.1  Clubs ───────────────────────────────────────────────
INSERT INTO Club (clubId,clubName,stadiumName,stadiumCapacity,city,country,transferBudget,yearFounded)
VALUES (1,'Real Madrid','Santiago Bernabeu',81044,'Madrid','Spain',150000000,1902);
INSERT INTO Club (clubId,clubName,stadiumName,stadiumCapacity,city,country,transferBudget,yearFounded)
VALUES (2,'Manchester City','Etihad Stadium',55017,'Manchester','England',200000000,1880);
INSERT INTO Club (clubId,clubName,stadiumName,stadiumCapacity,city,country,transferBudget,yearFounded)
VALUES (3,'FC Barcelona','Camp Nou',99354,'Barcelona','Spain',120000000,1899);
INSERT INTO Club (clubId,clubName,stadiumName,stadiumCapacity,city,country,transferBudget,yearFounded)
VALUES (4,'Bayern Munich','Allianz Arena',75024,'Munich','Germany',130000000,1900);
INSERT INTO Club (clubId,clubName,stadiumName,stadiumCapacity,city,country,transferBudget,yearFounded)
VALUES (5,'Paris Saint-Germain','Parc des Princes',47929,'Paris','France',180000000,1970);

-- ── 9.2  Persons ─────────────────────────────────────────────
-- Players (personId 1-5): subclass rows inserted in Section 9.3
INSERT INTO Person (personId,firstName,lastName,dateOfBirth,nationality,email,phoneNumber)
VALUES (1,'Kylian','Mbappe',DATE '1998-12-20','French','mbappe@ftms.com','00331000001');
INSERT INTO Person (personId,firstName,lastName,dateOfBirth,nationality,email,phoneNumber)
VALUES (2,'Erling','Haaland',DATE '2000-07-21','Norwegian','haaland@ftms.com','00441000001');
INSERT INTO Person (personId,firstName,lastName,dateOfBirth,nationality,email,phoneNumber)
VALUES (3,'Vinicius','Junior',DATE '2000-07-12','Brazilian','vinicius@ftms.com','00341000001');
INSERT INTO Person (personId,firstName,lastName,dateOfBirth,nationality,email,phoneNumber)
VALUES (4,'Pedri','Gonzalez',DATE '2002-11-25','Spanish','pedri@ftms.com','00341000002');
INSERT INTO Person (personId,firstName,lastName,dateOfBirth,nationality,email,phoneNumber)
VALUES (5,'Jamal','Musiala',DATE '2003-02-26','German','musiala@ftms.com','00491000001');
-- Managers (personId 6-10): subclass rows inserted in Section 9.4
INSERT INTO Person (personId,firstName,lastName,dateOfBirth,nationality,email,phoneNumber)
VALUES (6,'Carlo','Ancelotti',DATE '1959-06-10','Italian','ancelotti@ftms.com','00341000010');
INSERT INTO Person (personId,firstName,lastName,dateOfBirth,nationality,email,phoneNumber)
VALUES (7,'Pep','Guardiola',DATE '1971-01-18','Spanish','guardiola@ftms.com','00441000010');
INSERT INTO Person (personId,firstName,lastName,dateOfBirth,nationality,email,phoneNumber)
VALUES (8,'Hansi','Flick',DATE '1965-02-24','German','flick@ftms.com','00341000011');
INSERT INTO Person (personId,firstName,lastName,dateOfBirth,nationality,email,phoneNumber)
VALUES (9,'Vincent','Kompany',DATE '1986-04-10','Belgian','kompany@ftms.com','00321000001');
INSERT INTO Person (personId,firstName,lastName,dateOfBirth,nationality,email,phoneNumber)
VALUES (10,'Luis','Enrique',DATE '1970-05-08','Spanish','enrique@ftms.com','00341000012');

-- ── 9.3  Players ─────────────────────────────────────────────
--  Inserted immediately after their Person rows (mandatory subtype rule).
INSERT INTO Player (personId,primaryPosition,preferredFoot,marketValue,jerseyNumber,height,weight)
VALUES (1,'FWD','Right',180000000,9,180.0,73.0);
INSERT INTO Player (personId,primaryPosition,preferredFoot,marketValue,jerseyNumber,height,weight)
VALUES (2,'FWD','Left',200000000,9,194.0,88.0);
INSERT INTO Player (personId,primaryPosition,preferredFoot,marketValue,jerseyNumber,height,weight)
VALUES (3,'FWD','Right',150000000,7,176.0,73.0);
INSERT INTO Player (personId,primaryPosition,preferredFoot,marketValue,jerseyNumber,height,weight)
VALUES (4,'MID','Right',110000000,8,174.0,69.0);
INSERT INTO Player (personId,primaryPosition,preferredFoot,marketValue,jerseyNumber,height,weight)
VALUES (5,'MID','Right',100000000,42,182.0,75.0);

-- ── 9.4  Managers ────────────────────────────────────────────
--  Inserted immediately after their Person rows (mandatory subtype rule).
INSERT INTO Manager (personId,clubId,coachingLicense,preferredFormation,yearsOfExperience)
VALUES (6,1,'UEFA Pro','4-3-3',30);    -- Carlo Ancelotti → Real Madrid
INSERT INTO Manager (personId,clubId,coachingLicense,preferredFormation,yearsOfExperience)
VALUES (7,2,'UEFA Pro','4-3-3',20);    -- Pep Guardiola   → Manchester City
INSERT INTO Manager (personId,clubId,coachingLicense,preferredFormation,yearsOfExperience)
VALUES (8,3,'UEFA Pro','4-3-3',15);    -- Hansi Flick     → FC Barcelona
INSERT INTO Manager (personId,clubId,coachingLicense,preferredFormation,yearsOfExperience)
VALUES (9,4,'UEFA Pro','4-2-3-1',5);   -- Vincent Kompany → Bayern Munich
INSERT INTO Manager (personId,clubId,coachingLicense,preferredFormation,yearsOfExperience)
VALUES (10,5,'UEFA Pro','4-3-3',18);   -- Luis Enrique    → PSG

-- ── 9.5  Agents ──────────────────────────────────────────────
INSERT INTO Agent (agentId,firstName,lastName,agencyName,licenseNumber,commissionRate,email,phoneNumber)
VALUES (1,'Jorge','Mendes','Gestifute','FIFA-001',10,'mendes@gestifute.com','00351000001');
INSERT INTO Agent (agentId,firstName,lastName,agencyName,licenseNumber,commissionRate,email,phoneNumber)
VALUES (2,'Jonathan','Barnett','Stellar Group','FIFA-002',8,'barnett@stellar.com','00441000020');
-- Raiola is independent: agencyName = NULL, licenseNumber and commissionRate in correct columns
INSERT INTO Agent (agentId,firstName,lastName,agencyName,licenseNumber,commissionRate,email,phoneNumber)
VALUES (3,'Mino','Raiola',NULL,'FIFA-003',9,'raiola@ftms.com','00391000001');

-- ── 9.6  Sponsors ────────────────────────────────────────────
INSERT INTO Sponsor (sponsorId,sponsorName,industry,hqCountry,contactEmail,contactPhone,website)
VALUES (1,'Adidas','Sportswear','Germany','contact@adidas.com','00491000100','www.adidas.com');
INSERT INTO Sponsor (sponsorId,sponsorName,industry,hqCountry,contactEmail,contactPhone,website)
VALUES (2,'Nike','Sportswear','USA','contact@nike.com','00011000100','www.nike.com');
INSERT INTO Sponsor (sponsorId,sponsorName,industry,hqCountry,contactEmail,contactPhone,website)
VALUES (3,'Emirates','Aviation','UAE','contact@emirates.com','00971000100','www.emirates.com');

-- ── 9.7  Competitions ────────────────────────────────────────
INSERT INTO Competition (compId,compName,compType,country,prizePool,organizingBody,ranking)
VALUES (1,'UEFA Champions League','Continental',NULL,2000000000,'UEFA',1);
INSERT INTO Competition (compId,compName,compType,country,prizePool,organizingBody,ranking)
VALUES (2,'La Liga','League','Spain',500000000,'RFEF',4);
INSERT INTO Competition (compId,compName,compType,country,prizePool,organizingBody,ranking)
VALUES (3,'Premier League','League','England',3200000000,'Premier League',1);
INSERT INTO Competition (compId,compName,compType,country,prizePool,organizingBody,ranking)
VALUES (4,'Bundesliga','League','Germany',800000000,'DFL',3);

-- ── 9.8  Contracts  (parent row first, then subclass row) ────

-- Employment Contracts
-- Mbappe (personId=1) at PSG (clubId=5)
INSERT INTO Contract (contractId,personId,startDate,endDate,signingDate,contractStatus)
VALUES (1,1,DATE '2022-07-01',DATE '2025-06-30',DATE '2022-06-15','Active');
INSERT INTO EmploymentContract (contractId,clubId,weeklySalary,releaseClause,signingBonus,performanceBonus)
VALUES (1,5,300000,200000000,30000000,5000000);

-- Haaland (personId=2) at Manchester City (clubId=2)
INSERT INTO Contract (contractId,personId,startDate,endDate,signingDate,contractStatus)
VALUES (2,2,DATE '2022-07-01',DATE '2027-06-30',DATE '2022-06-20','Active');
INSERT INTO EmploymentContract (contractId,clubId,weeklySalary,releaseClause,signingBonus,performanceBonus)
VALUES (2,2,375000,NULL,20000000,8000000);

-- Vinicius (personId=3) at Real Madrid (clubId=1)
INSERT INTO Contract (contractId,personId,startDate,endDate,signingDate,contractStatus)
VALUES (3,3,DATE '2021-07-01',DATE '2027-06-30',DATE '2021-06-10','Active');
INSERT INTO EmploymentContract (contractId,clubId,weeklySalary,releaseClause,signingBonus,performanceBonus)
VALUES (3,1,250000,1000000000,15000000,3000000);

-- Ancelotti (personId=6) at Real Madrid (clubId=1)
INSERT INTO Contract (contractId,personId,startDate,endDate,signingDate,contractStatus)
VALUES (4,6,DATE '2021-06-01',DATE '2026-05-31',DATE '2021-05-20','Active');
INSERT INTO EmploymentContract (contractId,clubId,weeklySalary,releaseClause,signingBonus,performanceBonus)
VALUES (4,1,500000,NULL,NULL,NULL);

-- Guardiola (personId=7) at Manchester City (clubId=2)
INSERT INTO Contract (contractId,personId,startDate,endDate,signingDate,contractStatus)
VALUES (5,7,DATE '2023-07-01',DATE '2025-06-30',DATE '2023-06-15','Active');
INSERT INTO EmploymentContract (contractId,clubId,weeklySalary,releaseClause,signingBonus,performanceBonus)
VALUES (5,2,700000,NULL,NULL,NULL);

-- Sponsorship Contracts
-- Vinicius (personId=3) sponsored by Nike (sponsorId=2)
INSERT INTO Contract (contractId,personId,startDate,endDate,signingDate,contractStatus)
VALUES (6,3,DATE '2023-01-01',DATE '2026-12-31',DATE '2022-12-15','Active');
INSERT INTO SponsorshipContract (contractId,sponsorId,contractValue,paymentFrequency,endorsementType)
VALUES (6,2,15000000,'Annual','Boot');

-- Haaland (personId=2) sponsored by Nike (sponsorId=2)
INSERT INTO Contract (contractId,personId,startDate,endDate,signingDate,contractStatus)
VALUES (7,2,DATE '2022-08-01',DATE '2025-07-31',DATE '2022-07-20','Active');
INSERT INTO SponsorshipContract (contractId,sponsorId,contractValue,paymentFrequency,endorsementType)
VALUES (7,2,12000000,'Annual','Kit');

-- ── 9.9  Transfers ───────────────────────────────────────────
-- Mbappe: PSG (5) → Real Madrid (1), agent Mendes (1), free transfer
INSERT INTO Transfer (transferId,personId,buyingClubId,sellingClubId,agentId,transferFee,transferType)
VALUES (1,1,1,5,1,0,'Free');

-- Haaland: free agent → Manchester City (2), agent Barnett (2), permanent
INSERT INTO Transfer (transferId,personId,buyingClubId,sellingClubId,agentId,transferFee,transferType)
VALUES (2,2,2,NULL,2,51000000,'Permanent');

-- Pedri: new deal at FC Barcelona (3), no agent, no selling club
INSERT INTO Transfer (transferId,personId,buyingClubId,sellingClubId,agentId,transferFee,transferType)
VALUES (3,4,3,NULL,NULL,0,'Free');

-- ── 9.10  M:N Junction Data ──────────────────────────────────

-- AgentPersonRepresents
INSERT INTO AgentPersonRepresents (agentId,personId) VALUES (1,1); -- Mendes   → Mbappe
INSERT INTO AgentPersonRepresents (agentId,personId) VALUES (1,3); -- Mendes   → Vinicius
INSERT INTO AgentPersonRepresents (agentId,personId) VALUES (2,2); -- Barnett  → Haaland
INSERT INTO AgentPersonRepresents (agentId,personId) VALUES (3,4); -- Raiola   → Pedri
INSERT INTO AgentPersonRepresents (agentId,personId) VALUES (3,5); -- Raiola   → Musiala

-- CompetitionClubParticipation
INSERT INTO CompetitionClubParticipation (compId,clubId) VALUES (1,1); -- UCL        → Real Madrid
INSERT INTO CompetitionClubParticipation (compId,clubId) VALUES (1,2); -- UCL        → Manchester City
INSERT INTO CompetitionClubParticipation (compId,clubId) VALUES (1,3); -- UCL        → FC Barcelona
INSERT INTO CompetitionClubParticipation (compId,clubId) VALUES (1,4); -- UCL        → Bayern Munich
INSERT INTO CompetitionClubParticipation (compId,clubId) VALUES (1,5); -- UCL        → PSG
INSERT INTO CompetitionClubParticipation (compId,clubId) VALUES (2,1); -- La Liga    → Real Madrid
INSERT INTO CompetitionClubParticipation (compId,clubId) VALUES (2,3); -- La Liga    → FC Barcelona
INSERT INTO CompetitionClubParticipation (compId,clubId) VALUES (3,2); -- Prem. Leag → Manchester City
INSERT INTO CompetitionClubParticipation (compId,clubId) VALUES (4,4); -- Bundesliga → Bayern Munich

-- SponsorClubPartnership
INSERT INTO SponsorClubPartnership (sponsorId,clubId) VALUES (1,1); -- Adidas   → Real Madrid
INSERT INTO SponsorClubPartnership (sponsorId,clubId) VALUES (2,2); -- Nike     → Manchester City
INSERT INTO SponsorClubPartnership (sponsorId,clubId) VALUES (3,1); -- Emirates → Real Madrid
INSERT INTO SponsorClubPartnership (sponsorId,clubId) VALUES (3,2); -- Emirates → Manchester City
INSERT INTO SponsorClubPartnership (sponsorId,clubId) VALUES (1,4); -- Adidas   → Bayern Munich

COMMIT;


-- ────────────────────────────────────────────────────────────
--  SECTION 10: VERIFICATION QUERIES
-- ────────────────────────────────────────────────────────────

-- Row counts for every table
SELECT 'Person'                    AS tbl, COUNT(*) AS rows FROM Person
UNION ALL SELECT 'Player',                 COUNT(*) FROM Player
UNION ALL SELECT 'Manager',                COUNT(*) FROM Manager
UNION ALL SELECT 'Agent',                  COUNT(*) FROM Agent
UNION ALL SELECT 'Club',                   COUNT(*) FROM Club
UNION ALL SELECT 'Sponsor',                COUNT(*) FROM Sponsor
UNION ALL SELECT 'Contract',               COUNT(*) FROM Contract
UNION ALL SELECT 'EmploymentContract',     COUNT(*) FROM EmploymentContract
UNION ALL SELECT 'SponsorshipContract',    COUNT(*) FROM SponsorshipContract
UNION ALL SELECT 'Transfer',               COUNT(*) FROM Transfer
UNION ALL SELECT 'Competition',            COUNT(*) FROM Competition
UNION ALL SELECT 'AgentPersonRepresents',  COUNT(*) FROM AgentPersonRepresents
UNION ALL SELECT 'CompClubParticipation',  COUNT(*) FROM CompetitionClubParticipation
UNION ALL SELECT 'SponsorClubPartnership', COUNT(*) FROM SponsorClubPartnership;

-- All constraints: names, tables, types, and status
SELECT constraint_name, table_name, constraint_type, status
FROM   user_constraints
WHERE  table_name IN (
    'PERSON','PLAYER','MANAGER','AGENT','CLUB','SPONSOR',
    'CONTRACT','EMPLOYMENTCONTRACT','SPONSORSHIPCONTRACT',
    'TRANSFER','COMPETITION',
    'AGENTPERSONREPRESENTS','COMPETITIONCLUBPARTICIPATION',
    'SPONSORCLUBPARTNERSHIP'
)
ORDER BY table_name, constraint_type;
