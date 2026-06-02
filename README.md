# Football Transfer Management System (DBMS Solution)

A comprehensive Database Management System (DBMS) designed for football clubs, agents, and governing leagues to centralize and optimize the management of player transfers, player contracts, agent mappings, and complex financial transactions.

## 📋 Table of Contents
1. [Project Overview](#-project-overview)
2. [Problem Statement & Requirements](#-problem-statement--requirements)
3. [Database Architecture & Modeling](#-database-architecture--modeling)
   - [Conceptual Model](#conceptual-model)
   - [Logical Model](#logical-model)
   - [Physical Design](#physical-design)
   - [Enhanced ER (EER) Concepts](#enhanced-er-eer-concepts)
4. [Functional Dependencies & Normalization](#-functional-dependencies--normalization)
5. [Database Schema (DDL)](#-database-schema-ddl)
6. [Analytical SQL Queries](#-analytical-sql-queries)
7. [Team Members & Contributions](#-team-members--contributions)

---

## 📌 Project Overview
- **Course Title:** Database Management Systems
- **Course Code:** CT-261
- **Project Type:** Complex Computing Problem (CCP)
- **Instructor:** Dr. Raheela Asif
- **Target Audience:** Section C, Batch 2024

---

## 💼 Problem Statement & Requirements

### Business Context
Modern football ecosystems require an integrated database system to handle the high volume of player movements, intricate contract structures, and agent multi-party negotiations. Mid-level clubs frequently struggle with fragmented spreadsheets and manual record-keeping, which lead to:
* Data inconsistencies and duplications.
* Missed transfer deadlines and regulatory non-compliance.
* Disastrous financial miscalculations due to hidden agent fee structures.
* The absence of centralized historical audit trails for negotiation tracking.

### Core Business Requirements
1. **Player Tracking:** Centralize complete player profiles, including market value, specific positions, and nationalities.
2. **Transfer Operations:** Document dual-party operations (buying and selling clubs), historical tracking of exact fee values, dates, and deal types (e.g., Loan vs. Permanent transfers).
3. **Contract Management:** Track current active and expired contracts detailing wage components, start dates, and expiration markers.
4. **Agent Registry:** Maintain strict data on agents, including contact networks and individual standard commission rates.
5. **League Association:** Model multi-league landscapes where distinct clubs belong to designated regional leagues.
6. **Inheritance Structuring:** Implement a generic `Person` supertype to share unified personal details between specialized roles (`Player` and `Agent`).

---

## 🏗️ Database Architecture & Modeling

### Conceptual Model
The conceptual phase outlines seven core entity sets connected via structural constraints, abstracting any underlying technical components like data types or specific cardinalities:
* **Entities:** `Person`, `Player`, `Agent`, `Club`, `Contract`, `Transfer`, `League`.
* **Supertype Hierarchy:** `Person` acts as the root superclass. `Player` and `Agent` derive attributes directly via structural `IsA` subtyping relationships.

### Logical Model
Translates abstract conceptual constructs into logical tables with structural primary keys (PK), foreign keys (FK), and rigid multi-relational cardinalities:

| Table | Primary Key | Column Attributes / Foreign Keys |
| :--- | :--- | :--- |
| **Person** | `personId` | name, dateOfBirth, nationality, contactInfo |
| **Player** | `playerId` | `personId` (FK ➔ Person), position, marketValue, `agentId` (FK ➔ Agent) |
| **Agent** | `agentId` | `personId` (FK ➔ Person), commissionRate |
| **Club** | `clubId` | name, country, budget, `leagueId` (FK ➔ League) |
| **Contract**| `contractId` | salary, startDate, endDate, `playerId` (FK ➔ Player), `clubId` (FK ➔ Club) |
| **Transfer**| `transferId` | fee, transferDate, transferType, `playerId` (FK ➔ Player), `sellingClubId` (FK ➔ Club, NULLable), `buyingClubId` (FK ➔ Club), `agentId` (FK ➔ Agent) |
| **League** | `leagueId` | name, country |

#### Core Mappings & Cardinalities
* **Signs / Holds:** `Contract (0..*)` ➔ `Player (1..1)` and `Club (1..1)`. A player or club can possess multiple sequential contracts; a distinct contract belongs exclusively to one player and one club.
* **Transfers (Buys / Sells):** `Transfer (0..*)` ➔ Buying `Club (1..1)` / Selling `Club (0..1)`. Free agent signings have no selling club (`NULL`).
* **Competes In:** `Club (0..*)` ➔ `League (1..1)`. A club competes within one league; a league aggregates many clubs.

### Physical Design
Implements real data type configurations to guarantee database integrity across platforms:
* **Numeric Identifiers:** All structural keys map to `INT` formats. Primary keys employ `AUTO_INCREMENT`.
* **String Metrics:** Varying lengths assigned dynamically via `VARCHAR` (e.g., `VARCHAR(100)` for corporate names, `VARCHAR(30)` for sports positions).
* **Financial Precisions:** Fixed-point accuracy using `DECIMAL(15,2)` to safeguard parameters like `fee`, `budget`, and `marketValue`.
* **Temporal Attributes:** Rigid tracking via `DATE` constraints on player births, transfer frames, and contract ranges.

### Enhanced ER (EER) Concepts
1. **Specialization & Generalization:** Modeled using a `{Mandatory, Or}` constraint loop. **Mandatory** ensures any registered entity must actively resolve into a concrete role, preventing isolated entities. **Or (Disjoint)** rules out invalid cross-role states (a person cannot simultaneously act as a player and an agent).
2. **Aggregation:** The structural link connecting `League` to `Club` uses aggregation semantics (`Has`). This explicitly maps a strict whole-part compositional layer where a `League` operates as the structural container entity holding dependent `Club` parts.

---

## 📐 Functional Dependencies & Normalization

To ensure data integrity and remove structural anomalies, the layout was normalized systematically from an Unnormalized Form (UNF) through to **Boyce-Codd Normal Form (BCNF)**. 

### Progression Summary
* **1NF:** Ensured atomic attributes and selected `transferId` as a unique row identifier. Evaluated and flagged remaining partial/transitive dependencies (e.g., player and club names depending on their respective IDs rather than the transfer sequence itself).
* **2NF:** Eliminated partial dependencies by splitting entity-specific fields into separate tables (`Player`, `Agent`, `Club`, `Transfer`).
* **3NF:** Isolated transitive contract elements (`salary`, `startDate`, `endDate`) out of the core transactional tables into a dedicated `Contract` table.
* **BCNF:** Validated every functional dependency ($X \rightarrow Y$), confirming that every left-hand determinant ($X$) serves explicitly as a structural superkey or primary key across all seven generated tables.

---
