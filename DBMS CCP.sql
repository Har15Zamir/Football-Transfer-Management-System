--  FOOTBALL TRANSFER MANAGEMENT SYSTEM

-- ────────────────────────────────────────────────────────────
--  SECTION 1: SEQUENCES
-- ────────────────────────────────────────────────────────────
CREATE SEQUENCE seq_person      START WITH 11 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_agent       START WITH 4  INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_club        START WITH 6  INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_sponsor     START WITH 4  INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_contract    START WITH 8  INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_transfer    START WITH 4  INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_competition START WITH 5  INCREMENT BY 1 NOCACHE;

-- ────────────────────────────────────────────────────────────
--  SECTION 2: CORE TABLES
-- ────────────────────────────────────────────────────────────

-- 2.1 PERSON
CREATE TABLE Person (
    personId    NUMBER          CONSTRAINT pk_person       PRIMARY KEY,
    firstName   VARCHAR2(50)    CONSTRAINT nn_person_fname NOT NULL,
    lastName    VARCHAR2(50)    CONSTRAINT nn_person_lname NOT NULL,
    dateOfBirth DATE            CONSTRAINT nn_person_dob   NOT NULL,
    nationality VARCHAR2(50)    CONSTRAINT nn_person_nat   NOT NULL,
    email       VARCHAR2(100)   CONSTRAINT nn_person_email NOT NULL,
    phoneNumber VARCHAR2(20)    CONSTRAINT nn_person_phone NOT NULL,
    CONSTRAINT uq_person_email UNIQUE (email),
    CONSTRAINT ck_person_dob   CHECK (dateOfBirth < TO_DATE('2027-01-01', 'YYYY-MM-DD'))
);

-- 2.2 AGENT
CREATE TABLE Agent (
    agentId        NUMBER          CONSTRAINT pk_agent        PRIMARY KEY,
    firstName      VARCHAR2(50)    CONSTRAINT nn_agent_fname  NOT NULL,
    lastName       VARCHAR2(50)    CONSTRAINT nn_agent_lname  NOT NULL,
    agencyName     VARCHAR2(100),
    licenseNumber  VARCHAR2(50)    CONSTRAINT nn_agent_lic    NOT NULL,
    commissionRate NUMBER(5,2)     CONSTRAINT nn_agent_comm   NOT NULL,
    email          VARCHAR2(100)   CONSTRAINT nn_agent_email  NOT NULL,
    phoneNumber    VARCHAR2(20)    CONSTRAINT nn_agent_phone  NOT NULL,
    CONSTRAINT uq_agent_license UNIQUE (licenseNumber),
    CONSTRAINT uq_agent_email   UNIQUE (email),
    CONSTRAINT ck_agent_comm    CHECK (commissionRate BETWEEN 0 AND 100)
);

-- 2.3 CLUB
CREATE TABLE Club (
    clubId          NUMBER          CONSTRAINT pk_club         PRIMARY KEY,
    clubName        VARCHAR2(100)   CONSTRAINT nn_club_name    NOT NULL,
    stadiumName     VARCHAR2(100)   CONSTRAINT nn_club_stadium NOT NULL,
    stadiumCapacity NUMBER(9)       CONSTRAINT nn_club_cap     NOT NULL,
    city            VARCHAR2(50)    CONSTRAINT nn_club_city    NOT NULL,
    country         VARCHAR2(50)    CONSTRAINT nn_club_country NOT NULL,
    transferBudget  NUMBER(15,2)    CONSTRAINT nn_club_budget  NOT NULL,
    yearFounded     NUMBER(4)       CONSTRAINT nn_club_year    NOT NULL,
    CONSTRAINT ck_club_cap    CHECK (stadiumCapacity > 0),
    CONSTRAINT ck_club_budget CHECK (transferBudget >= 0),
    CONSTRAINT ck_club_year   CHECK (yearFounded BETWEEN 1800 AND 2100)
);

-- 2.4 SPONSOR
CREATE TABLE Sponsor (
    sponsorId    NUMBER          CONSTRAINT pk_sponsor       PRIMARY KEY,
    sponsorName  VARCHAR2(100)   CONSTRAINT nn_sponsor_name  NOT NULL,
    industry     VARCHAR2(50)    CONSTRAINT nn_sponsor_ind   NOT NULL,
    hqCountry    VARCHAR2(50)    CONSTRAINT nn_sponsor_hq    NOT NULL,
    contactEmail VARCHAR2(100)   CONSTRAINT nn_sponsor_email NOT NULL,
    contactPhone VARCHAR2(20)    CONSTRAINT nn_sponsor_phone NOT NULL,
    website      VARCHAR2(200),
    CONSTRAINT uq_sponsor_email UNIQUE (contactEmail)
);

-- 2.5 COMPETITION
CREATE TABLE Competition (
    compId         NUMBER          CONSTRAINT pk_competition PRIMARY KEY,
    compName       VARCHAR2(100)   CONSTRAINT nn_comp_name   NOT NULL,
    compType       VARCHAR2(20)    CONSTRAINT nn_comp_type   NOT NULL,
    country        VARCHAR2(50),
    prizePool      NUMBER(15,2),
    organizingBody VARCHAR2(100)   CONSTRAINT nn_comp_org   NOT NULL,
    ranking        NUMBER(3),
    CONSTRAINT ck_comp_type  CHECK (compType IN ('League','Cup','Continental')),
    CONSTRAINT ck_comp_prize CHECK (prizePool IS NULL OR prizePool >= 0)
);

-- ────────────────────────────────────────────────────────────
--  SECTION 3: SUBCLASSES
-- ────────────────────────────────────────────────────────────

-- 3.1 PLAYER
CREATE TABLE Player (
    personId        NUMBER          CONSTRAINT pk_player        PRIMARY KEY,
    primaryPosition VARCHAR2(20)    CONSTRAINT nn_player_pos    NOT NULL,
    preferredFoot   VARCHAR2(10)    CONSTRAINT nn_player_foot   NOT NULL,
    marketValue     NUMBER(15,2)    CONSTRAINT nn_player_mv     NOT NULL,
    jerseyNumber    NUMBER(2)       CONSTRAINT nn_player_jersey NOT NULL,
    height          NUMBER(5,2)     CONSTRAINT nn_player_ht     NOT NULL,
    weight          NUMBER(5,2)     CONSTRAINT nn_player_wt     NOT NULL,
    CONSTRAINT fk_player_person FOREIGN KEY (personId) REFERENCES Person(personId) ON DELETE CASCADE,
    CONSTRAINT ck_player_pos    CHECK (primaryPosition IN ('GK','DEF','MID','FWD')),
    CONSTRAINT ck_player_foot   CHECK (preferredFoot   IN ('Left','Right','Both')),
    CONSTRAINT ck_player_jersey CHECK (jerseyNumber BETWEEN 1 AND 99)
);

-- 3.2 MANAGER
CREATE TABLE Manager (
    personId           NUMBER          CONSTRAINT pk_manager      PRIMARY KEY,
    clubId             NUMBER          CONSTRAINT uq_manager_club UNIQUE,
    coachingLicense    VARCHAR2(50)    CONSTRAINT nn_mgr_lic      NOT NULL,
    preferredFormation VARCHAR2(10)    CONSTRAINT nn_mgr_form     NOT NULL,
    yearsOfExperience  NUMBER(2)       CONSTRAINT nn_mgr_exp      NOT NULL,
    CONSTRAINT fk_manager_person FOREIGN KEY (personId) REFERENCES Person(personId) ON DELETE CASCADE,
    CONSTRAINT fk_manager_club   FOREIGN KEY (clubId)   REFERENCES Club(clubId) ON DELETE SET NULL,
    CONSTRAINT ck_mgr_exp        CHECK (yearsOfExperience >= 0)
);

-- ────────────────────────────────────────────────────────────
--  SECTION 4: CONTRACTS
-- ────────────────────────────────────────────────────────────

CREATE TABLE Contract (
    contractId     NUMBER          CONSTRAINT pk_contract        PRIMARY KEY,
    personId       NUMBER          CONSTRAINT nn_contract_person NOT NULL,
    startDate      DATE            CONSTRAINT nn_contract_start  NOT NULL,
    endDate        DATE            CONSTRAINT nn_contract_end    NOT NULL,
    signingDate    DATE            CONSTRAINT nn_contract_sign   NOT NULL,
    contractStatus VARCHAR2(20)    CONSTRAINT nn_contract_status NOT NULL,
    CONSTRAINT fk_contract_person FOREIGN KEY (personId) REFERENCES Person(personId) ON DELETE CASCADE,
    CONSTRAINT ck_contract_status CHECK (contractStatus IN ('Active','Expired','Terminated')),
    CONSTRAINT ck_contract_dates  CHECK (endDate > startDate),
    CONSTRAINT ck_contract_sign   CHECK (signingDate <= startDate)
);

CREATE TABLE EmploymentContract (
    contractId       NUMBER          CONSTRAINT pk_empcontract PRIMARY KEY,
    clubId           NUMBER          CONSTRAINT nn_ec_club     NOT NULL,
    weeklySalary     NUMBER(12,2)    CONSTRAINT nn_ec_salary   NOT NULL,
    releaseClause    NUMBER(15,2),
    signingBonus     NUMBER(15,2),
    performanceBonus NUMBER(15,2),
    CONSTRAINT fk_ec_contract FOREIGN KEY (contractId) REFERENCES Contract(contractId) ON DELETE CASCADE,
    CONSTRAINT fk_ec_club     FOREIGN KEY (clubId)     REFERENCES Club(clubId),
    CONSTRAINT ck_ec_salary   CHECK (weeklySalary > 0)
);

CREATE TABLE SponsorshipContract (
    contractId       NUMBER          CONSTRAINT pk_sponcontract PRIMARY KEY,
    sponsorId        NUMBER          CONSTRAINT nn_sc_sponsor   NOT NULL,
    contractValue    NUMBER(15,2)    CONSTRAINT nn_sc_value     NOT NULL,
    paymentFrequency VARCHAR2(20)    CONSTRAINT nn_sc_freq      NOT NULL,
    endorsementType  VARCHAR2(50)    CONSTRAINT nn_sc_endorse   NOT NULL,
    CONSTRAINT fk_sc_contract FOREIGN KEY (contractId) REFERENCES Contract(contractId) ON DELETE CASCADE,
    CONSTRAINT fk_sc_sponsor  FOREIGN KEY (sponsorId)  REFERENCES Sponsor(sponsorId),
    CONSTRAINT ck_sc_freq     CHECK (paymentFrequency IN ('Monthly','Quarterly','Annual')),
    CONSTRAINT ck_sc_value    CHECK (contractValue > 0)
);

-- ────────────────────────────────────────────────────────────
--  SECTION 5: TRANSFER
-- ────────────────────────────────────────────────────────────
CREATE TABLE Transfer (
    transferId    NUMBER          CONSTRAINT pk_transfer    PRIMARY KEY,
    personId      NUMBER          CONSTRAINT nn_tr_person   NOT NULL,
    buyingClubId  NUMBER          CONSTRAINT nn_tr_buying   NOT NULL,
    sellingClubId NUMBER,
    agentId       NUMBER,
    transferFee   NUMBER(15,2)    CONSTRAINT nn_tr_fee     NOT NULL,
    transferType  VARCHAR2(20)    CONSTRAINT nn_tr_typenn  NOT NULL,
    CONSTRAINT fk_tr_person  FOREIGN KEY (personId)      REFERENCES Person(personId) ON DELETE CASCADE,
    CONSTRAINT fk_tr_buying  FOREIGN KEY (buyingClubId)  REFERENCES Club(clubId),
    CONSTRAINT fk_tr_selling FOREIGN KEY (sellingClubId) REFERENCES Club(clubId) ON DELETE SET NULL,
    CONSTRAINT fk_tr_agent   FOREIGN KEY (agentId)      REFERENCES Agent(agentId) ON DELETE SET NULL,
    CONSTRAINT ck_tr_type    CHECK (transferType IN ('Permanent','Loan','Free')),
    CONSTRAINT ck_tr_fee     CHECK (transferFee >= 0),
    CONSTRAINT ck_tr_clubs   CHECK (sellingClubId IS NULL OR buyingClubId <> sellingClubId)
);

-- ────────────────────────────────────────────────────────────
--  SECTION 6: JUNCTION TABLES
-- ────────────────────────────────────────────────────────────

CREATE TABLE AgentPersonRepresents (
    agentId  NUMBER  CONSTRAINT nn_apr_agent  NOT NULL,
    personId NUMBER  CONSTRAINT nn_apr_person NOT NULL,
    CONSTRAINT pk_apr        PRIMARY KEY (agentId, personId),
    CONSTRAINT fk_apr_agent  FOREIGN KEY (agentId)  REFERENCES Agent(agentId)   ON DELETE CASCADE,
    CONSTRAINT fk_apr_person FOREIGN KEY (personId) REFERENCES Person(personId) ON DELETE CASCADE
);

CREATE TABLE CompetitionClubParticipation (
    compId NUMBER  CONSTRAINT nn_ccp_comp NOT NULL,
    clubId NUMBER  CONSTRAINT nn_ccp_club NOT NULL,
    CONSTRAINT pk_ccp        PRIMARY KEY (compId, clubId),
    CONSTRAINT fk_ccp_comp   FOREIGN KEY (compId) REFERENCES Competition(compId) ON DELETE CASCADE,
    CONSTRAINT fk_ccp_club   FOREIGN KEY (clubId) REFERENCES Club(clubId)        ON DELETE CASCADE
);

CREATE TABLE SponsorClubPartnership (
    sponsorId NUMBER  CONSTRAINT nn_scp_sponsor NOT NULL,
    clubId    NUMBER  CONSTRAINT nn_scp_club    NOT NULL,
    CONSTRAINT pk_scp          PRIMARY KEY (sponsorId, clubId),
    CONSTRAINT fk_scp_sponsor  FOREIGN KEY (sponsorId) REFERENCES Sponsor(sponsorId) ON DELETE CASCADE,
    CONSTRAINT fk_scp_club     FOREIGN KEY (clubId)    REFERENCES Club(clubId)       ON DELETE CASCADE
);

-- ────────────────────────────────────────────────────────────
--  SECTION 7: TRIGGERS
3 wordws that rhyme with triggfer
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_person_subtype
AFTER INSERT ON Person
FOR EACH ROW
BEGIN
    NULL; 
END;
/

-- ────────────────────────────────────────────────────────────
--  SECTION 8: INDEXES
-- ────────────────────────────────────────────────────────────
CREATE INDEX idx_contract_person ON Contract(personId);
CREATE INDEX idx_ec_club         ON EmploymentContract(clubId);
CREATE INDEX idx_sc_sponsor      ON SponsorshipContract(sponsorId);
CREATE INDEX idx_transfer_person ON Transfer(personId);
CREATE INDEX idx_transfer_buying ON Transfer(buyingClubId);

-- ────────────────────────────────────────────────────────────
--  SECTION 9: SAMPLE DATA
-- ────────────────────────────────────────────────────────────

-- Clubs
INSERT INTO Club VALUES (1,'Real Madrid','Santiago Bernabeu',81044,'Madrid','Spain',150000000,1902);
INSERT INTO Club VALUES (2,'Manchester City','Etihad Stadium',55017,'Manchester','England',200000000,1880);
INSERT INTO Club VALUES (3,'FC Barcelona','Camp Nou',99354,'Barcelona','Spain',120000000,1899);
INSERT INTO Club VALUES (4,'Bayern Munich','Allianz Arena',75024,'Munich','Germany',130000000,1900);
INSERT INTO Club VALUES (5,'Paris Saint-Germain','Parc des Princes',47929,'Paris','France',180000000,1970);

-- Persons
INSERT INTO Person VALUES (1,'Kylian','Mbappe',DATE '1998-12-20','French','mbappe@ftms.com','00331000001');
INSERT INTO Person VALUES (2,'Erling','Haaland',DATE '2000-07-21','Norwegian','haaland@ftms.com','00441000001');
INSERT INTO Person VALUES (3,'Vinicius','Junior',DATE '2000-07-12','Brazilian','vinicius@ftms.com','00341000001');
INSERT INTO Person VALUES (4,'Pedri','Gonzalez',DATE '2002-11-25','Spanish','pedri@ftms.com','00341000002');
INSERT INTO Person VALUES (5,'Jamal','Musiala',DATE '2003-02-26','German','musiala@ftms.com','00491000001');
INSERT INTO Person VALUES (6,'Carlo','Ancelotti',DATE '1959-06-10','Italian','ancelotti@ftms.com','00341000010');
INSERT INTO Person VALUES (7,'Pep','Guardiola',DATE '1971-01-18','Spanish','guardiola@ftms.com','00441000010');
INSERT INTO Person VALUES (8,'Hansi','Flick',DATE '1965-02-24','German','flick@ftms.com','00341000011');
INSERT INTO Person VALUES (9,'Vincent','Kompany',DATE '1986-04-10','Belgian','kompany@ftms.com','00321000001');
INSERT INTO Person VALUES (10,'Luis','Enrique',DATE '1970-05-08','Spanish','enrique@ftms.com','00341000012');

-- Players & Managers
INSERT INTO Player VALUES (1,'FWD','Right',180000000,9,180.0,73.0);
INSERT INTO Player VALUES (2,'FWD','Left',200000000,9,194.0,88.0);
INSERT INTO Player VALUES (3,'FWD','Right',150000000,7,176.0,73.0);
INSERT INTO Player VALUES (4,'MID','Right',110000000,8,174.0,69.0);
INSERT INTO Player VALUES (5,'MID','Right',100000000,42,182.0,75.0);

INSERT INTO Manager VALUES (6,1,'UEFA Pro','4-3-3',30);
INSERT INTO Manager VALUES (7,2,'UEFA Pro','4-3-3',20);
INSERT INTO Manager VALUES (8,3,'UEFA Pro','4-3-3',15);
INSERT INTO Manager VALUES (9,4,'UEFA Pro','4-2-3-1',5);
INSERT INTO Manager VALUES (10,5,'UEFA Pro','4-3-3',18);

INSERT INTO Agent VALUES (1,'Jorge','Mendes','Gestifute','FIFA-001',10,'mendes@gestifute.com','00351000001');
INSERT INTO Sponsor VALUES (1,'Adidas','Sportswear','Germany','contact@adidas.com','00491000100','www.adidas.com');
INSERT INTO Competition VALUES (1,'Champions League','Continental',NULL,2000000000,'UEFA',1);

INSERT INTO Contract VALUES (1,1,DATE '2022-07-01',DATE '2025-06-30',DATE '2022-06-15','Active');
INSERT INTO EmploymentContract (contractId,clubId,weeklySalary) VALUES (1,5,300000);
INSERT INTO Transfer VALUES (1,1,1,5,1,0,'Free');
INSERT INTO AgentPersonRepresents VALUES (1,1);

COMMIT;

-- ────────────────────────────────────────────────────────────
--  SECTION 10: VERIFICATION
-- ────────────────────────────────────────────────────────────
SELECT 'SUCCESS' as Status, (SELECT COUNT(*) FROM Person) as Total_People FROM DUAL;
