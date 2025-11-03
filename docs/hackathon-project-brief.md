# Cloudfest USA 2025 - Hackathon Project Brief

## Project Title

FAIR Software Security Assistant

## Tagline

Automating vulnerability screening and policy enforcement for FAIR-based WordPress repositories.

## Project Leads

Carrie Dils - WordPress Developer, LinkedIn Learning Instructor, and FAIR Technical Steering Committee Co-chair
Brent Toderash - Project Director at Modern Earth, AspirePress Project Manager, and FAIR Technical Steering Committee Member
Elliot Taylor - Head of Engineering at Patchstack

## Project Description (Full)

Hosting providers adopting or recommending the FAIR Package Manager need to maintain secure, reliable WordPress repositories at scale. The FAIR Software Security Assistant automates security screening using vulnerability intelligence data from Patchstack, enabling hosting providers and end users to efficiently manage their repositories to maintain security without manual auditing overhead.

This open-source tool will automatically cross-reference packages against Patchstack's comprehensive vulnerability database to ensure synchronized repositories show the latest security information for each package. Hosting providers can apply customizable security policies to manage package approval workflows, ensuring only verified software reaches customer sites.

Proposed key features include automated vulnerability scanning by Patchstack, configurable risk-based approval workflows, compliance reporting, and audit trails. By combining FAIR's decentralized architecture with Patchstack's security intelligence, the tool will empower hosting providers to exercise enhanced control over their WordPress software supply chain to lower risk and improve security. Not only will this enable blocking installation of vulnerable packages, but as an added benefit, end users can opt in to auto-update patches for vulnerable packages that have already been installed.

## Project Description (Short)

The FAIR Software Security Assistant helps hosting providers maintain secure and trusted WordPress repositories. The open-source tool automatically screens plugins and themes distributed through FAIR against verified vulnerability data from Patchstack. It enforces customizable security policies to block or flag risky software, providing hosting teams with an automated, auditable workflow for managing package security at scale.

## Hackathon Goals

The project will deliver a working minimum viable product addressing hosting provider security workflows. Potential deliverables include:

#### Primary MVP Deliverables

* Repository monitoring system that provides current vulnerability labels to FAIR Aggregators or end users, and verifies the label before installing new or updated packages.
* Security analysis engine integrating Patchstack's vulnerability database for on-the-fly scanning.
* Basic policy engine for risk-based package approvals (approve/flag/block workflows).
* Minimal dashboard to visualize repository security status and flagged packages.

#### Stretch Goals (if time permits)

* Compliance reporting and audit trail generation
* Advanced policy configuration interface
* Integration documentation for hosting control panels
* Containerization for deployment
* Managed Vulnerability Disclosure Program (mVDP) integration
* End-user (WordPress site admin) dashboard access to tools & controls

Teams can focus on different components based on expertise: backend API integration, frontend dashboard development, security policy engine, or hosting platform integration.

## Skillsets

* Full-stack developers with API integration experience
* Frontend developers and UI/UX designers
* Security engineers and DevOps professionals
* WordPress and PHP developers
* System administrators with hosting infrastructure knowledge
* Backend developers experienced with data processing and automation

## Target Audience

* Cloud hosting providers and managed WordPress hosting companies
* Enterprise IT teams managing WordPress deployments
* FAIR repository maintainers
* WordPress agencies managing multiple client sites
* DevOps and infrastructure teams implementing FAIR

## Hashtags

#Security #Distributed #WordPress #FAIR #Patchstack

---

👇 INTERNAL ONLY  👇

### Potential team composition

**Team Backend/API (8-10 people)**

- FAIR repository monitoring and sync
- Patchstack API integration
- Data pipeline architecture

**Team Policy Engine (6-8 people)**

- Risk scoring algorithms
- Approval workflow logic
- Configuration management

**Team Frontend/Dashboard (6-8 people)**

- Security status visualization
- Repository management interface
- User experience design

**Floaters: Integration & DevOps (2-4 people)**

- Cross-team coordination
- API contracts
- Deployment preparation
