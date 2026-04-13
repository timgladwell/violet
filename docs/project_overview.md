# Project Overview

## Side hustle becomes full time job

- Andrea is a nurse practitioner (NP) licenced to provide medical services in Ontario, Canada. She has a side hustle business providing multiple menopause treatment services (broadly speaking, medical treatment like hormones and quality-of-life treatments like weight loss assistance).  
- Andrea already uses a hosted electronic medical records (EMR) solution, Avaros. This system is at the heart of her business - everything from client onboarding to billing.  
- Andrea’s side hustle is successful and growing. She’s ready to stop working for other people and transition this into her full-time job.  
- Her current business growth is organic (word of mouth, presenting at conferences). She wants to formalize her customer acquisition funnel and add an online presence that can support things like targeted advertisements.
- The business name is Ontario Menopause Clinic.

## Canada Health Act changes

- It was initially expected that NPs would be allowed OHIP direct billing by April 1st, 2026. That deadline has been extended to an indefinite future, and all services will continue to be paid by clients.

## Guiding Principles

- This is a new business - build for now and maybe into the next year, but YAGNI any decisions that have a longer timeline than that.  
- This is a new business - keep costs as low as possible (without infringing on any TOS, and without putting up any roadblocks). Leverage cost  $0 assets as much as possible - open source technologies, licence-free assets, and “free tier” software-as-a-service   

## Technical principles
- Andrea does not have dedicated technical support, so keep day-to-day technical literacy requirements low.
- Ensure that services have a defined time-to-recovery and recovery point time, and a service level agreement that clearly defines how incidents are identified and resolved.

## Scope

### Business setup
- Registration of domain
- Custom domain email
  - Low-technical-literacy required for day-to-day use
  - Must use a technology like IMAP where the single source of truth is the email host
  - Must easily work on an iphone and with Outlook
  - aliases for specific business functions (e.g. `billing@<domain>`) that can be converted to shared mailboxes if/when Andrea hires additional staff.
- Static marketing website
  - See @docs/website_design.md for more details

### Avaros
- Configure patient self-scheduling so that new patients can book a 15 minute intake appointment.
  - Self-scheduled intake process must require that the potential client fill out an intake form
- Determine the changes required to support the new billing requirements, and coordinate the cutover
  - Anticipate requiring Avaros support for this, including for determining what is the best path forward (e.g. reusing the same configurataion, or launching a new configuration and deprecating the existing configuration)

### Launch initial marketing campaigns
- Current business is word of mouth, no marketing yet performed. Initial marketing campagins should be treated as experiements to understand
  - literally, how to purchase advertisting
  - what does and doesn't work, and to start understanding the return on ad spend
