# CAPP ERP - Comprehensive Human Resource Management System

## 📋 Project Overview

**CAPP ERP** is a complete web-based **Human Resource Management and Enterprise Resource Planning (ERP) System** built with Ruby on Rails. It provides comprehensive solutions for managing employee lifecycle, contracts, payroll, documents, leaves, organizational structure, and business operations.

---

## 🎯 Core Functionalities

### 1. **Employee Management**
- Employee profile management (personal information, identities, addresses)
- Academic ranks and positions
- Employee status tracking
- User authentication and authorization
- Employee document management

### 2. **Organization & Department Management**
- Organization structure and hierarchy
- Department management
- Subdepartment management
- Department types and classifications
- Functional units and job positions

### 3. **Contract Management**
- Contract creation and lifecycle management
- Contract types and templates
- Contract details and amendments
- Contract date tracking
- Document association with contracts
- Temporary contract management

### 4. **Leave & Holiday Management**
- Holiday calendar management
- Holiday types and categories
- Leave requests and approvals
- Leave workflow management
- Holiday templates and scheduling
- Manager leave approval system
- Holiday problem/issue tracking

### 5. **Payroll & Benefits**
- Payslip generation and management
- Payslip details and calculations
- Benefits management
- Benefits tracking
- Salary benefits configuration
- Salary structure

### 6. **Task & Project Management**
- Task creation and assignment
- Survey tasks (G-surveys)
- Staff tasks
- Task dependencies and workflows
- Auto-testing tasks
- Task status tracking

### 7. **Document & Filing Management**
- Memorandum document (Mandoc) management
- Document classifications (outgoing, incoming, etc.)
- Document filing and archiving
- Archive levels and types
- Document release management
- Document priority management
- Document handling and workflows
- Media file attachment
- Digital signature management
- Regulatory document management

### 8. **Appointment Management**
- Appointment scheduling
- Appointment surveys
- Appointment tracking
- Calendar integration

### 9. **Attendance & Scheduling**
- Attendance tracking and monitoring
- Work shift management and selection
- Schedule week management
- Check-in/Check-out verification
- Shift issue management
- Attendance workflow

### 10. **Work & Assignment Management**
- Work assignment and tracking
- Work trip management
- Duty assignment
- Work operations management
- Operation stream tracking

### 11. **Survey & Assessment**
- Survey management
- Survey records and responses
- General surveys (G-surveys)
- Organization surveys
- Quarterly surveys (Q-surveys)
- Appointment-related surveys

### 12. **Notification & Communication**
- System notifications
- User notifications
- Email notifications (FCM - Firebase Cloud Messaging)
- Notification job scheduling
- Staff notices
- Document handling notifications

### 13. **Data Management & Compliance**
- User data export functionality
- Document compliance and review
- Regulatory compliance management
- Data archiving and retention
- System logs and error tracking

### 14. **Settings & Configuration**
- User settings and preferences
- System maintenance settings
- User type configuration
- User status configuration
- Holiday schedule configuration
- Shift and work pattern settings

### 15. **Reporting & Analytics**
- Dashboard and analytics
- Evaluation summaries
- Report generation
- Survey reporting

### 16. **Security & Access Control**
- Role-based access control
- Permission management
- User authentication with password hashing
- Session management with caching
- CSRF protection for forms

---

## 📁 Project Directory Structure

```
app/
├── api/
│   └── apps/
│       └── mapps.rb                      # Main API endpoints
│
├── controllers/                          # Request handlers (71+ controllers)
│   ├── academicranks_controller.rb      # Academic rank management
│   ├── appointments_controller.rb        # Appointment scheduling
│   ├── attends_controller.rb            # Attendance tracking
│   ├── contracts_controller.rb          # Contract management
│   ├── dashboards_controller.rb         # Dashboard/analytics
│   ├── departments_controller.rb        # Department management
│   ├── documents_controller.rb          # Document management
│   ├── education_controller.rb          # Education records
│   ├── forms_controller.rb              # Form management
│   ├── functions_controller.rb          # Function definitions
│   ├── gsurveys_controller.rb           # General surveys
│   ├── gtasks_controller.rb             # General/Group tasks
│   ├── holtemps_controller.rb           # Holiday templates
│   ├── leave_request_controller.rb      # Leave request processing
│   ├── mandocs_controller.rb            # Memo documents
│   ├── mandoc_outgoing_controller.rb    # Outgoing memo documents
│   ├── notifies_controller.rb           # Notification management
│   ├── organizations_controller.rb      # Organization structure
│   ├── payslips_controller.rb           # Payroll management
│   ├── permissions_controller.rb        # Permission management
│   ├── scheduleweeks_controller.rb      # Work schedule management
│   ├── sessions_controller.rb           # User authentication
│   ├── sign_document_controller.rb      # Digital signatures
│   ├── stasks_controller.rb             # Staff tasks
│   ├── survey_controller.rb             # Survey management
│   ├── users_controller.rb              # User management
│   ├── workshifts_controller.rb         # Work shift management
│   └── concerns/                        # Shared controller logic
│
├── models/                              # Database models (130+ models)
│   ├── user.rb                          # User model with associations
│   ├── contract.rb                      # Contract management
│   ├── mandoc.rb                        # Memorandum documents
│   ├── appointment.rb                   # Appointment scheduling
│   ├── attend.rb                        # Attendance records
│   ├── education.rb                     # Education background
│   ├── holiday.rb                       # Holiday management
│   ├── work.rb                          # Work assignments
│   ├── workshift.rb                     # Work shift definitions
│   ├── payslip.rb                       # Payroll data
│   ├── permission.rb                    # Permission definitions
│   ├── discipline.rb                    # Discipline records
│   ├── benefit.rb                       # Benefit definitions
│   ├── sanctionery.rb                   # Sanctions/Discipline
│   ├── signature.rb                     # Digital signatures
│   ├── snotice.rb                       # System notices
│   ├── deploy/ (with many associations)
│   └── concerns/                        # Shared model logic
│
├── services/                            # Business logic layer
│   ├── fcm_service.rb                   # Firebase Cloud Messaging
│   └── leave_workflow_service.rb        # Leave request workflows
│
├── jobs/                                # Background jobs
│   ├── notification_job.rb              # Send notifications
│   ├── send_notification_job.rb         # Async notification sending
│   ├── send_mandocuhandle_notification_job.rb
│   ├── check_appointsurvey_status_job.rb
│   └── update_checkout_job.rb           # Update checkout status
│
├── mailers/                             # Email handling
│   ├── user_mailer.rb                   # User-related emails
│   ├── attend_mailer.rb                 # Attendance emails
│   ├── holiday_mailer.rb                # Holiday notification emails
│   ├── system_mailer.rb                 # System emails
│   └── application_mailer.rb            # Base mailer class
│
├── helpers/                             # View helpers
│   └── remote_notification_helper.rb    # Notification helper methods
│
├── views/                               # View templates (ERB/HTML)
│   └── [Form views for all controllers]
│
├── assets/                              # Frontend resources
│   ├── config/
│   ├── fonts/
│   ├── images/
│   ├── javascripts/                     # Client-side logic
│   └── stylesheets/                     # CSS styling
│
└── channels/                            # WebSocket channels
    └── application_cable/               # Cable configuration
```

---

## 🔧 Technology Stack

### Backend
- **Framework**: Ruby on Rails (6+)
- **Language**: Ruby
- **Authentication**: bcrypt (password hashing with `has_secure_password`)
- **ORM**: ActiveRecord

### Database
- **Primary Database**: MySQL/MariaDB (inferred from Rails conventions)
- **Models**: 130+ ActiveRecord models
- **Associations**: Complex many-to-many and belongs-to relationships

### Key Libraries & Gems (inferred from code)
- **SimpleCaptcha**: CAPTCHA functionality for forms
- **FCM (Firebase Cloud Messaging)**: Push notification services
- **Rails ActionController**: HTTP request handling
- **ActionMailer**: Email delivery
- **ActiveJob**: Background job processing

### Frontend
- **Views**: Embedded Ruby (ERB) templates
- **Styling**: CSS/SCSS
- **JavaScripts**: Client-side interactions
- **Assets Pipeline**: Rails asset compilation

### Communication
- **WebSockets**: ActionCable for real-time updates
- **Email**: ActionMailer with system mailer configuration
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **HTTP APIs**: RESTful endpoints

---

## 🗄️ Database Schema Overview

### Core Entities

#### Users & Access
- **User**: Employee/staff profiles with password authentication
- **Permission**: Role-based permissions
- **Tbusertype**: User type classifications
- **Tbuserstatus**: User status tracking
- **Uctoken**: User token for API/session management

#### Organization
- **Organization**: Company/organization entities
- **Department**: Organizational departments
- **Subdepartment**: Sub-organizational units
- **Departmenttype/Tbdepartmenttype**: Department classifications
- **Function/Tfunction**: Business functions
- **Positionjob**: Job position definitions
- **Academicrank**: Academic/professional ranks

#### Employee Records
- **Identity**: Employee identity documents
- **Address**: Employee address records
- **Education**: Educational background
- **Relative**: Family/relative information
- **Social**: Social/demographic information
- **Bank**: Bank account information
- **Mediafile**: File attachments and media

#### Contract & Employment
- **Contract**: Employment contracts
- **Contracttype**: Contract type definitions
- **Contracttime**: Contract duration/timeline
- **Contractdetail**: Contract details and amendments
- **Tmpcontract**: Temporary contract records
- **Condoc**: Contract-related documents

#### Work & Tasks
- **Work**: Work assignments
- **Workin**: Work input/initialization
- **Workshift**: Shift definitions
- **Shiftselection**: Employee shift selections
- **Shiftissue**: Shift-related issues
- **Stask**: Staff task assignments
- **Gtask**: General/group tasks
- **Task/Taskdoc**: Task management

#### Attendance
- **Attend**: Attendance records
- **Attenddetail**: Attendance detail entries
- **Scheduleweek**: Weekly schedule planning

#### Leave & Holiday Management
- **Holiday**: Holiday definitions
- **Holtype/Holtypedetail**: Holiday type classifications
- **Holtemp**: Holiday templates
- **Holpro/Holprosdetail**: Holiday provisions and allocations
- **Holdetail**: Holiday usage details
- **App Register**: Leave application registry

#### Documents & Records
- **Mandoc**: Memorandum/official documents
- **Mandoctype**: Document type classifications
- **Mandocpriority**: Document priority levels
- **Mandocfrom**: Document origin/source
- **Mandocfile**: Document file attachments
- **Mandocbook**: Document registry/logbook
- **Mandocdhandle/Mandocuhandle**: Document handling records
- **Doc**: General documentation
- **Adoc**: Administrative documents
- **Bdoc**: Benefit documents
- **Condoc**: Contract documents
- **Discdoc**: Discipline documents
- **Ddoc**: Department documents
- **Holdoc**: Holiday documents
- **Idendoc**: Identity documents
- **Mydoc**: Personal documents
- **Reldoc**: Related documents
- **Revdoc**: Reviewed documents
- **Wdoc**: Work documents

#### Payroll & Benefits
- **Payslip**: Salary payment records
- **Payslipdetail**: Detailed payroll data
- **Benefit**: Benefit definitions
- **Sbenefit**: Staff benefits
- **Tbbenefit**: Benefits table/reference

#### Surveys & Evaluations
- **Survey**: Survey definitions
- **Surveyrecord**: Survey responses
- **Gsurvey**: General/group surveys
- **Qsurvey**: Quarterly surveys
- **Appointsurvey**: Appointment-related surveys
- **Oqsurvery**: Organization quarterly surveys
- **Review**: Performance reviews

#### Notifications & Communication
- **Notify**: Notification definitions
- **Snotice**: System notices for users

#### Archive & Compliance
- **Archive/Archarchive**: Document archiving
- **Tbarchivelevel**: Archive level definitions
- **Tbarchivetype**: Archive type classifications

#### Special Records
- **Discipline**: Discipline/violation records
- **Regulation**: Regulation/policy definitions
- **Maintenance**: Maintenance records
- **Hismaintenance**: Historical maintenance

---

## 🔄 Key Relationships & Workflows

### Authentication & Session Flow
1. User logs in via `SessionsController`
2. `ApplicationController` validates session and user credentials
3. User information cached in session for performance (production)
4. SimpleCaptcha validates form submission integrity

### Leave Request Workflow
1. User submits leave request via `LeaveRequestController`
2. `LeaveWorkflowService` processes the request
3. Manager approves/denies via `ManagerLeaveController`
4. Notifications sent via `NotificationJob`
5. Leave record created in `Holiday` and `Holdetail` models

### Document Handling Workflow
1. Document created via `MandocsController`
2. Document state tracked in `Mandoc` model
3. Users assigned to handle document via `MandocuHandler`
4. Digital signatures applied via `SignatureController`
5. Document finally archived via `Archive` system
6. Notifications sent at each step

### Notification System
1. Events trigger notification creation in `Notify` model
2. Jobs queued via `ActiveJob`
3. `NotificationJob` sends via email or FCM
4. `SendNotificationJob` handles async delivery
5. System notices stored in `Snotice` for display

### Attendance Tracking
1. User check-in: `Attend` record created via `AttendsController`
2. `UpdateCheckoutJob` validates check-out times
3. `Attenddetail` stores specific punch records
4. `Scheduleweek` provides expected work schedule
5. Discrepancies reported via `ShiftIssue`

---

## 🚀 Key Features & Modules

### 1. **Complete Employee Lifecycle Management**
   - Onboarding → Employment → Development → Offboarding
   - All employee data centralized in User model

### 2. **Comprehensive Document Management**
   - Over 20 document types supported
   - Version control and archiving
   - Digital signature integration
   - Workflow automation

### 3. **Advanced Payroll System**
   - Automated payslip generation
   - Benefits calculation and tracking
   - Multiple salary structures support

### 4. **Flexible Leave Management**
   - Multiple leave types
   - Holiday templates and policies
   - Workflow-based approvals
   - Leave provisions and allocations

### 5. **Real-time Notifications**
   - Firebase Cloud Messaging integration
   - Email notifications
   - In-app notifications
   - Scheduled notification jobs

### 6. **Work Scheduling & Time Tracking**
   - Flexible shift management
   - Attendance tracking with timestamps
   - Schedule conflict detection
   - Shift issue management

### 7. **Organizational Intelligence**
   - Complete organization hierarchy
   - Functional unit tracking
   - Department and position management
   - Academic rank system

### 8. **Survey & Assessment Tools**
   - Multiple survey types (general, quarterly, appointment)
   - Assessment and evaluation
   - Feedback collection

---

## 🔌 API & Integrations

### External Services
1. **Firebase Cloud Messaging (FCM)**
   - Push notification delivery
   - Implemented in `FcmService`

2. **Email Service**
   - ActionMailer configuration
   - Multiple mailer classes for different notifications

3. **File Storage**
   - Media file handling via `Mediafile` model
   - Document attachments via `MandocFile`

### Internal APIs
- RESTful endpoints via controllers
- API namespace structure in `app/api/apps/`

---

## 📊 Controller Architecture

### Main Controller Categories

**71+ Controllers** organized by domain:

- **Identity & Access**: `users_controller`, `sessions_controller`, `permissions_controller`
- **Organization**: `organization_controller`, `departments_controller`, `subdepartments_controller`
- **Employee**: `academicranks_controller`, `education_controller`, `functions_controller`
- **Contracts**: `contracts_controller`, `contracttimes_controller`, `contracttypes_controller`
- **Payroll**: `payslips_controller`, `sbenefits_controller`
- **Leave Management**: `leave_request_controller`, `manager_leave_controller`, `holtemps_controller`
- **Work & Attendance**: `works_controller`, `workshifts_controller`, `attends_controller`, `scheduleweeks_controller`
- **Documents**: `mandocs_controller`, `documents_controller`, `sign_document_controller`, `released_mandocs_controller`
- **Tasks**: `stasks_controller`, `gtasks_controller`, `tasks_controller`
- **Surveys**: `survey_controller`, `gsurveys_controller`
- **Communication**: `notifies_controller`, `appointments_controller`
- **Settings**: `msettings_controller`
- **Utilities**: `dashboards_controller`, `forms_controller`, `export_user_data_controller`, `dev_errors_controller`

---

## 🛡️ Security Features

1. **Authentication**
   - Password hashing with bcrypt (`has_secure_password`)
   - Session-based authentication
   - User token management (`Uctoken`)

2. **Authorization**
   - Role-based access control via `Permission` model
   - User type restrictions (`Tbusertype`)

3. **Data Protection**
   - CSRF protection in forms
   - Encrypted password storage
   - Session caching with UID validation (production)

4. **Error Handling**
   - `DevErrorsController` for error tracking
   - `Errlog` model for error logging

---

## 📈 Background Jobs & Scheduling

### Active Job Queue
1. **`NotificationJob`** - Send notifications
2. **`SendNotificationJob`** - Async notification delivery
3. **`SendMandocuhandleNotificationJob`** - Document handling alerts
4. **`CheckAppointsurveyStatusJob`** - Monitor appointment surveys
5. **`UpdateCheckoutJob`** - Update employee check-out times

---

## 🔍 Database Connections & Performance

### Caching Strategy
- **Production**: User info cached in session (10-minute window)
- **Notice caching**: 10-minute cache with automatic refresh
- **UID validation**: Prevents session hijacking

### Associations
- Complex many-to-many relationships via join tables
- Dependent destroy for data integrity
- Optional associations for flexible data modeling

---

## 📋 Set-Up & Configuration Requirements

### Required
- Ruby on Rails 6+
- MySQL/MariaDB database
- Firebase Cloud Messaging (FCM) setup for notifications
- Ruby 2.7+ or 3.0+

### Dependencies
- `bcrypt` gem for password hashing
- `simple_captcha` gem for form protection
- Rails default gems (ActiveRecord, ActionController, ActionMailer, ActiveJob)

### Configuration Files (Not in workspace)
- `config/database.yml` - Database connection
- `config/routes.rb` - Route definitions
- `config/environments/` - Environment-specific settings
- `Gemfile` - Dependency management

---

## 👥 User Roles & Permissions

The system supports multiple user types:
- **System Administrators** - Full system access
- **HR Personnel** - HR module access
- **Managers** - Team and approval access
- **Employees** - Personal data access
- **Department Heads** - Department management
- **Supervisors** - Work assignment and tracking

---

## 📝 Naming Conventions Observed

### Models
- Singular, CamelCase: `User`, `Contract`, `Mandoc`
- Table models: `Tbuserstatus` (reference tables)
- Abbreviations common: `Holtype` (Holiday Type), `Mandoc` (Memorandum Document)

### Controllers
- Plural, snake_case with `_controller` suffix: `users_controller.rb`

### Fields
- snake_case: `first_name`, `last_name`, `academic_rank`
- Foreign keys: `{model}_id`: `user_id`, `contract_id`

---

## 🎓 Key Modules & Classes

### ApplicationRecord
- Base record class for all models
- Handles ActiveRecord common functionality

### ApplicationController
- Base controller
- Handles authentication, authorization, notices caching
- Session management with caching
- Locale and default data initialization

### SimpleCaptcha::ControllerHelpers
- CAPTCHA generation and validation
- Form security

---

## 📞 Support & Integration Points

### Email Integration
- User mailer
- Holiday mailer
- Attendance mailer
- System mailer

### Notification Integration
- Firebase Cloud Messaging
- Email notifications
- In-app notifications

### File Management
- Media files and attachments
- Document file storage
- Contract documents

---

## 🔐 Data Privacy & Compliance

- User data export functionality (`ExportUserDataController`)
- Document archiving and retention policies
- Regulatory compliance module (`RegulationController`)
- Audit logging (via `Errlog` and `Mhistory` models)

---

## 📊 Reporting Capabilities

1. **Dashboard**: `DashboardsController` - System overview
2. **Payroll Reports**: Via `PayslipsController`
3. **Attendance Reports**: Via `AttendsController`
4. **Survey Reports**: Via `SurveyController`
5. **Evaluation Reports**: `EvaluationSummaryController`
6. **Leave Reports**: Via `LeaveRequestController`

---

## 🚨 Error Handling

- `DevErrorsController` - Development error tracking
- `Errlog` model - Error logging and monitoring
- Rails exception handling via ApplicationController

---

## 🎯 Future Enhancement Areas

1. API versioning and documentation
2. Microservices architecture
3. Mobile application support
4. Advanced analytics dashboard
5. Machine learning for leave prediction
6. Integration with third-party HR systems
7. Enhanced document OCR and scanning
8. Blockchain for document verification

---

## 📄 License & Version

- **System**: CAPP ERP v1.0 (Estimated based on structure)
- **Built with**: Ruby on Rails
- **Database**: Relational (MySQL/MariaDB)

---

## 👨‍💻 Development Notes

### Code Organization
- Clean separation of concerns (MVC pattern)
- Service layer for business logic
- Job layer for async operations
- Helper layer for view logic

### Associations Pattern
- User (central) connects to most modules
- Polymorphic associations for document handling
- Through relationships for many-to-many scenarios

### Performance Optimization
- Session caching
- Notice caching with time window
- Efficient query scoping

---

## 📞 Contact & Support

For issues, features requests, or support:
- Review the controllers for current functionality
- Check models for database structure
- Consult services for business logic implementation
- Review background jobs for automation workflows

---

**Last Updated**: March 2026  
**Project Type**: Human Resource Management ERP System  
**Framework**: Ruby on Rails  
**Status**: Active Development & Maintenance
