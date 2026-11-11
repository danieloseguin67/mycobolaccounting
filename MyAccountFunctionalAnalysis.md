# MyAccounting — Functional Guide

**Document version:** 2.0  
**Application version:** 1.0.0  
**Date:** April 18, 2026  
**Author:** Daniel Seguin  

---

> **Who is this guide for?**  
> This guide is written for people who run their own business or work as independent professionals — IT consultants, real estate agents, service technicians, or anyone who bills clients for their time and services. You don't need any accounting background to use this guide. Where accounting terms are unavoidable, they are explained in plain language.

---

## Table of Contents

1. [What Does MyAccounting Do?](#1-what-does-myaccounting-do)
2. [How the Application Works](#2-how-the-application-works)
3. [Application Structure](#3-application-structure)
4. [Signing In and User Access](#4-signing-in-and-user-access)
5. [Your Home Screen (Dashboard)](#5-your-home-screen-dashboard)
6. [Setting Up Your Business](#6-setting-up-your-business)
7. [Invoicing — Billing Your Clients](#7-invoicing--billing-your-clients)
8. [Recording Payments Received](#8-recording-payments-received)
9. [Journal Entry](#9-journal-entry)
10. [Financial Categories (Chart of Accounts)](#10-financial-categories-chart-of-accounts)
11. [Business Health Reports](#11-business-health-reports)
12. [Timesheet — Tracking Your Work Hours](#12-timesheet--tracking-your-work-hours)
13. [Loading Your Existing Data](#13-loading-your-existing-data)
14. [How Your Data is Stored](#14-how-your-data-is-stored)
15. [Rules the System Enforces](#15-rules-the-system-enforces)
16. [Emails, PDFs, and Exports](#16-emails-pdfs-and-exports)
17. [Installing the Application](#17-installing-the-application)
18. [Security and Data Protection](#18-security-and-data-protection)

---

## 1. What Does MyAccounting Do?

MyAccounting is a Windows desktop application that helps small Canadian service businesses manage the money side of their work. Think of it as a simple office tool that replaces spreadsheets and paper records for billing and financial tracking.

**In plain terms, it lets you:**

- Send professional invoices to your clients and email the PDF directly from the app
- Record payments when a client pays you
- Track how much each client owes you at any moment
- Log your daily work hours and send approved timesheets to clients
- Run reports to see how much money your business made and where it was spent
- Manage your list of clients, services, and projects in one place

**What it does NOT do:**

- Pay your suppliers or track bills you owe (accounts payable)
- Process employee payroll
- Track physical stock quantities (it is designed for service businesses)
- Work as a cloud or web application — it runs only on your Windows computer

---

## 2. How the Application Works

| What | Details |
|---|---|
| Runs on | Windows 10 or later (standalone program — no browser needed) |
| Stores data in | Microsoft SQL Server, installed locally on your computer |
| Built with | Python — but you don't need to know Python to use it |

MyAccounting is a standard Windows desktop application. You double-click to open it, sign in, and use it like any other program. All your data is saved automatically to a local database on your computer — no internet connection is required for day-to-day use (except for sending emails).

---

## 3. Application Structure

The application is divided into separate sections, each handling one area of your business. You switch between them using the navigation menu on the left side of the screen.

| Section | What It Handles |
|---|---|
| Dashboard | Your daily overview — unpaid invoices, recent activity, to-do list |
| Configuration | All your setup: company info, clients, services, email, users |
| Invoicing | Creating and sending invoices to clients |
| Cash Receipts | Recording payments you receive from clients |
| Journal | Manual corrections to your financial records |
| Chart of Accounts | Your master list of financial categories |
| Reports | Profit & Loss, Balance Sheet, and other financial summaries |
| Timesheets | Tracking daily work hours for billing |

---

## 4. Signing In and User Access

### 4.1 How Sign-In Works

When you open MyAccounting, a sign-in screen appears before anything else. You enter your username and password. If your account is inactive or the password is wrong, the application will not open.

Once signed in, the application remembers who you are for the entire session. It uses your identity to filter your own to-do items, timesheets, and other personal data.

### 4.2 Password Security

Your password is never stored in plain text. MyAccounting uses industry-standard encryption (the same method used by banks) to protect your credentials. Each password is individually scrambled with a unique random code, so even if someone accessed the database directly, they could not read your password.

### 4.3 User Roles

| Role | What They Can Do |
|---|---|
| **Admin** | Full access to everything, including user management and all settings |
| **User / Accountant** | Access limited to specific sections, as configured by the admin |

### 4.4 Controlling Who Can Access What

An admin can grant each user either **full access** (read and write) or **view-only access** per section. For example, you might give a bookkeeper full access to Cash Receipts but only view-only access to Configuration.

Sections that can be individually controlled: Financial Categories, Journal, Reports, Configuration, Invoicing, Cash Receipts, Timesheets.

---

## 5. Your Home Screen (Dashboard)

The Dashboard is the first screen you see after signing in. It gives you a quick snapshot of your business at a glance.

### 5.1 What's on the Dashboard

| Panel | What It Shows |
|---|---|
| **What Clients Owe You** | A list of clients with outstanding unpaid invoices and the amount due |
| **Pending Adjustments** | How many financial adjustments are saved as drafts and not yet finalized |
| **Monthly Revenue Chart** | A bar chart showing how much money you earned each month |
| **My To-Do List** | Your personal task list — notes, reminders, and follow-ups |

### 5.2 Your To-Do List

The to-do list is personal to each user — no one else sees your tasks. You can:

- Add tasks with a title, notes, due date, and priority (Low, Normal, High)
- Mark tasks as done
- Delete tasks you no longer need

---

## 6. Setting Up Your Business

The **Configuration** section is where you enter all your business details before you start using the other sections. Think of it as your control panel. It is organized into 13 tabs.

### 6.1 What Each Tab Does

| # | Tab | What You Set Up |
|---|---|---|
| 1 | **Company Info** | Your business name, address, phone, website, and logo for invoices and reports |
| 2 | **Fiscal Year & Settings** | Your financial year dates, the tax rate you charge (e.g., 13% HST), invoice numbering, and which financial categories map to your bank account, income, and taxes |
| 3 | **Clients** | Your complete client list — addresses, contact details, payment terms, and preferred language |
| 4 | **Services / Items** | The services or products you bill for, with default prices |
| 5 | **Projects** | Project names you can attach to invoices and timesheets |
| 6 | **Consultants / Staff** | The people in your business who create invoices and timesheets |
| 7 | **Tax Codes** | The tax rates you apply (e.g., HST 13%, GST 5%) |
| 8 | **Countries** | Countries for client addresses |
| 9 | **Provinces / States** | Provinces and states for client addresses |
| 10 | **Payment Terms** | Options like "Net 30" (client pays within 30 days), "Due on receipt", etc. |
| 11 | **Email Settings** | Your outgoing email server so the app can send invoices and timesheets by email |
| 12 | **Users** | Add team members, set passwords, and control what each person can access (admin only) |
| 13 | **Timesheet Settings** | Default work shift times and whether client approval is required on timesheets |

### 6.2 Welcoming New Users

When you create a new user account, the system automatically sends that person a welcome email with their username, a temporary password, and instructions for signing in.

---

## 7. Invoicing — Billing Your Clients

### 7.1 What You Can Do

The Invoicing section is where you create and manage all your client bills.

- See all your invoices in a list, sorted by date, client, or status
- Create a new invoice, edit a draft, or cancel one you no longer need
- Add the services you provided, with quantities and prices
- Add text notes or comments directly on the invoice (e.g., "Payment due by end of month")
- Tax (HST) is calculated automatically based on the rate you set in Configuration
- Generate a professional-looking PDF invoice with one click
- Email the PDF directly to your client from within the application
- Attach supporting documents (contracts, photos, reports) to any invoice

### 7.2 Invoice Numbering

Invoices are numbered automatically starting from a number you set (e.g., INV-1001, INV-1002, etc.). You never need to manually track invoice numbers.

### 7.3 Invoice Lifecycle

An invoice moves through these stages:

| Status | Meaning |
|---|---|
| **Draft** | Work in progress — not yet sent to the client |
| **Approved** | Ready to send or already sent |
| **Void** | Cancelled — kept for records but no longer counted as money owed |

### 7.4 What the PDF Invoice Looks Like

When you print or email the invoice, the PDF includes:
- Your company name, address, and logo at the top
- The client's name and address
- A table of services provided with quantities, unit prices, and amounts
- Subtotal, tax amount (HST), and total due
- Any notes or comments you added

### 7.5 Emailing Invoices

When you click "Email Invoice", the application sends an email to the client's billing address. The email subject and message body are templates you can customize — for example: *"Please find attached Invoice INV-1024 for $1,200.00 from ABC Consulting. Thank you for your business."*

---

## 8. Recording Payments Received

### 8.1 What This Section Does

When a client pays you — by cheque, bank transfer, or any other method — you record that payment in this section. This keeps your client balances accurate and updates your financial records.

- See all recorded payments in a list
- Record a new payment: who paid, how much, on what date, and which invoice it applies to
- Add a memo (e.g., "Cheque #4521" or "e-Transfer")
- Preview the financial entries before they are finalized
- **Finalize (Post)** the payment to lock it in and update your records

### 8.2 Receipt Numbering

Like invoices, payment receipts are numbered automatically (e.g., CR-1001, CR-1002).

### 8.3 What Happens When You Finalize a Payment

When you click **Post**, the application:
1. Records the money as received in your bank account category
2. Removes the matching amount from what the client owes you
3. These two entries balance each other out — this is the standard way financial records are kept

> **Important:** Once a payment is finalized, it cannot be changed or deleted. Always preview the details before posting.

---

## 9. Journal Entry

### 9.1 What This Section Is For

The Journal Entry section is a general-purpose tool for recording financial transactions that don't go through the Invoicing or Cash Receipts sections. You'll use it in two main situations:

**Recording operating expenses** — Any money your business spends that isn't captured elsewhere. Common examples for IT consultants, real estate agents, and service technicians:
- Software subscriptions (Microsoft 365, cloud tools, CRM)
- Vehicle mileage or fuel expenses
- Office rent, phone, or internet bills
- Marketing and advertising costs
- Equipment purchases or repairs
- Professional fees (accountant, lawyer)

**Making corrections and adjustments** — When something needs to be reclassified or fixed:
- Moving an expense from one category to another
- Recording a bank fee or interest charge
- Correcting an error from a previous entry
- Recording depreciation at year end (typically done by your accountant)

You don't need accounting expertise for day-to-day expense entries. Your accountant will typically handle year-end adjustments.

### 9.2 How It Works

Each adjustment entry has:
- A date and description
- Two or more lines specifying which financial categories are affected and by how much
- The total "increases" must equal the total "decreases" before the entry can be finalized — this is a built-in safeguard that ensures your records stay accurate

### 9.3 Rules

- An adjustment must balance (what goes in must equal what comes out) before it can be posted
- At minimum, you need two lines per entry
- Draft entries can be edited or deleted; finalized (posted) entries are permanent

---

## 10. Financial Categories (Chart of Accounts)

### 10.1 What This Is

Your Chart of Accounts is simply your master list of financial "buckets" — categories that every dollar in your business gets assigned to. Think of it like the folders in a filing cabinet, where every transaction gets filed in the right place.

Examples from a service business:
- **Bank Account** — Money in your chequing account
- **Accounts Receivable** — Money clients owe you
- **Service Revenue** — Money you earn from your work
- **Phone & Internet** — A business expense category
- **HST Payable** — The tax you collected on behalf of the government

### 10.2 What You Can Do Here

- See all your financial categories with their current balances
- Add a new category, rename one, or remove one (as long as it has no transactions)
- Click on any category to see every transaction ever recorded in it — a complete history
- Export the full list to Excel, PDF, or CSV for your accountant

### 10.3 How Balances Are Calculated

Each category shows its current balance, which is calculated as:

- **Starting balance** (from when you set up the system) **plus** all money that increased it **minus** all money that decreased it

This is always calculated live from your actual transaction records, so it's always up to date.

---

## 11. Business Health Reports

### 11.1 The Three Key Reports

MyAccounting produces three standard financial reports that every business owner should be familiar with:

| Report | What It Answers | Covers |
|---|---|---|
| **Profit & Loss** (Income Statement) | "Did I make money this period?" | Your income and expenses for a date range you choose |
| **Balance Sheet** | "What does my business own and owe right now?" | Your assets, liabilities, and net worth at a specific date |
| **Trial Balance** | "Are all my records in balance?" | Every financial category with its total — used mainly by your accountant to verify accuracy |

**Profit & Loss** is the report most business owners look at regularly. It shows your total revenue, all your expense categories, and what you're left with (net profit or net loss).

**Balance Sheet** shows a snapshot of your financial position: what you own (cash, receivables), what you owe (taxes payable, any loans), and what's left over.

### 11.2 Choosing a Date Range

By default, reports cover your full fiscal year. You can change the start and end dates to look at any period — for example, just this month, or the last quarter.

### 11.3 Saving and Sharing Reports

Each report can be:
- **Printed to PDF** — a formatted, professional document you can send to your accountant or banker
- **Exported to Excel** — for further analysis or your own record-keeping
- **Viewed on screen** — scrollable, interactive view within the application

---

## 12. Timesheet — Tracking Your Work Hours

### 12.1 What This Section Is For

If you bill clients based on hours worked — as most IT consultants, service technicians, or contractors do — the Timesheet section is where you log that work. It is designed to:

- Record exactly what you did each day, broken down by task
- Calculate total hours automatically
- Produce a professional timesheet PDF you can email to your client for their records or approval
- Import timesheets from a TPG-format file if your staffing agency or client uses that format

### 12.2 How a Timesheet Works

Each timesheet covers **one month** for **one consultant**. You:

1. Create a new timesheet for the month, linked to a client and project
2. For each working day, enter your start and end times (morning, afternoon, and any overtime)
3. Add work items for each day — a short description of what you did and optionally a task reference number (e.g., an Azure DevOps work item number)
4. Hours are calculated automatically from your start/end times
5. When complete, submit the timesheet for approval

### 12.3 Timesheet Approval Process

```
Draft  ──[Submit]──►  Submitted  ──[Approve]──►  Approved
                                 ──[Reject] ──►  Rejected

Rejected  ──[Reset to Draft]──►  Draft
Approved  ──[Cannot be changed]
```

- **Draft**: You are still working on it — can be edited freely
- **Submitted**: Sent for review — waiting on approval
- **Approved**: Locked permanently — your official billing record
- **Rejected**: Sent back to you for corrections — you reset it to Draft, fix it, and resubmit

### 12.4 Emailing the Timesheet to Your Client

With one click, the application generates a PDF of your timesheet and emails it to the client's contact person. If approval is required, the email includes an approval request message.

### 12.5 Importing Timesheets (TPG Format)

If you receive a timesheet file from a staffing agency (TPG format), you can import it directly rather than entering everything manually. The application supports:
- CSV files
- PDF files (including scanned documents — the app reads them with optical character recognition)
- Excel files

After importing, you see a preview of what was read. You confirm or cancel before anything is saved.

---

## 13. Loading Your Existing Data

If you are migrating from Sage 50 (Simply Accounting) or have data in text files, there is a one-time import tool that can load your existing records into MyAccounting.

### 13.1 What Can Be Imported

| Data | File Format |
|---|---|
| Your client list | Text file (pipe-separated) |
| Your service/product list | Text file (pipe-separated) |
| Your projects | Text file (pipe-separated) |
| Historical financial transactions | Sage 50 CSV export |
| Opening balances by category | CSV file |

### 13.2 Important Notes

- This import runs **once only**, when you first set up the application on a fresh database
- It brings in your historical transaction data from Sage 50 and sets starting balances for all your financial categories
- Running it a second time would create duplicate records — don't run it again after setup

---

## 14. How Your Data is Stored

### 14.1 Data Categories

Your business data is organized into logical groups and stored in a local Microsoft SQL Server database:

| What | Examples |
|---|---|
| **Financial records** | All transactions, account balances, summaries |
| **Invoices** | Invoice headers, line items, file attachments |
| **Payments received** | Cash receipt records |
| **Adjustments** | Journal entry headers and lines |
| **Timesheets** | Monthly timesheets, daily entries, work items |
| **Reference data** | Clients, services, projects, staff, tax codes, payment terms |
| **System settings** | Your company info, email settings, all preferences |

### 14.2 How Everything Connects

Your data is interconnected so the system keeps everything consistent. For example:
- An invoice is linked to a specific client, project, and staff member
- A payment receipt is linked to a client and the invoice it pays
- A timesheet is linked to a staff member and a client

This means if you look up a client, you can trace all their invoices, payments, and timesheets from one record.

### 14.3 Your System Settings

All your preferences are stored in a settings table. The most important ones are:

| Setting | What It Controls |
|---|---|
| Company name | Appears on all invoices and reports |
| Fiscal year dates | Default date range for reports |
| Tax rate | HST percentage added to invoices automatically |
| Currency | Display currency (default: CAD) |
| Invoice prefix & starting number | e.g., INV-1001, INV-1002 ... |
| Bank account category | Which financial category is your bank account |
| Email server settings | Used to send invoices and timesheets by email |

### 14.4 Automatic Numbering

Invoice numbers, payment receipt numbers, and journal entry numbers are all assigned automatically and always increment by 1. You never have to track or assign these manually.

---

## 15. Rules the System Enforces

These are the safeguards built into the application to prevent mistakes.

### 15.1 General Rules

- All dollar amounts are stored with exactly 2 decimal places
- Dates use the MM/DD/YYYY format throughout the application
- Empty amount fields are treated as $0.00

### 15.2 Invoicing

- An invoice must have at least one service line before it can be saved
- Tax (HST) is always calculated automatically: Subtotal × Tax Rate = Tax Amount; Total = Subtotal + Tax
- Voided invoices are excluded from the "money owed to you" totals

### 15.3 Recording Payments

- A payment must include the client, date, amount (greater than zero), and the bank account before it can be finalized
- Once finalized, a payment **cannot** be changed or deleted — it is a permanent financial record
- Finalizing is immediate and updates your financial records right away

### 15.4 Manual Adjustments

- The total of all increases must equal the total of all decreases before an entry can be finalized — this keeps your books in balance
- At least two lines are required per entry
- Only draft entries can be changed; finalized entries are permanent

### 15.5 Timesheets

- Each consultant can only have one timesheet per calendar month — no duplicates allowed
- Only Draft and Rejected timesheets can be edited
- Approved timesheets cannot be changed in any way

### 15.6 Financial Categories

- Category codes must be unique — no two categories can have the same number
- A category that has transactions recorded against it cannot be deleted

---

## 16. Emails, PDFs, and Exports

### 16.1 Sending Emails

The application can send emails directly from within the program. You configure your outgoing email server once in Configuration → Email Settings, and then the following actions send emails automatically:

| Action | What Gets Sent |
|---|---|
| Click "Email Invoice" | PDF of the invoice attached to an email to the client |
| Click "Send Timesheet to Client" | PDF of the timesheet attached to an email to the client contact |
| Click "Support" in the toolbar | A support request email to the application support address |
| Create a new user | A welcome email with login details to the new user |

### 16.2 Printable PDFs

Every important document in the application can be exported as a PDF:

| Document | Layout | What It Contains |
|---|---|---|
| Invoice | Portrait | Your logo, client details, service lines, tax, total |
| Timesheet | Landscape | Consultant details, daily time grid, work descriptions, total hours |
| Profit & Loss | Portrait | Revenue, expenses, net income — by date range |
| Balance Sheet | Portrait | Assets, liabilities, and equity at a point in time |
| Trial Balance | Portrait | Complete list of all financial categories with balances |
| Financial Categories List | Portrait | All your account categories with opening and current balances |

### 16.3 Excel Exports

If you prefer to work with data in Excel, the following can be exported to `.xlsx`:
- Financial category list (Chart of Accounts)
- All three financial reports (Profit & Loss, Balance Sheet, Trial Balance)
- Timesheet details

Excel files are formatted with styled headers, currency formatting, and appropriate column widths — ready to send to your accountant.

### 16.4 CSV Exports

Comma-separated files (CSV) can be opened in Excel or imported into other tools:
- Financial category list
- Journal entries
- A standard summary export for your accountant (`exportdir/accountant.csv`)

---

## 17. Installing the Application

Installation is handled by a guided wizard (`deploy.exe`) that sets up everything automatically — including the database engine, database, Chart of Accounts, company profile, and shortcuts.

For full installation instructions, see the dedicated guide:

**[MyAccountingInstallation.md](MyAccountingInstallation.md)**

---

## 18. Security and Data Protection

Your financial data is stored locally on your computer and protected in the following ways:

| Protection | How It Works |
|---|---|
| **Passwords are never stored in plain text** | Your password is scrambled using the same encryption standard used by financial institutions. Even a database administrator cannot read it. |
| **Brute-force password cracking is extremely slow** | The encryption process deliberately requires significant computation, making automated password-guessing attacks impractical. |
| **Protection against data injection attacks** | All queries to the database use safe parameterized statements — the application is protected against common data manipulation attacks. |
| **Your session is private** | Once you sign in, your identity is kept in memory only for your current session. Closing the application clears it. |
| **Per-user access control** | Each user can only access the sections the admin has granted them. Everything else is hidden and disabled. |
| **Email credentials are stored locally** | Your email server password is saved in the local database, not in any source file or cloud service. |
| **No network exposure** | The application does not open any network ports. It only makes outbound connections (to send emails). There is nothing for an outside attacker to connect to. |
| **Change history** | Every financial adjustment records who created it and when. Cash receipts and invoices also record creation timestamps. |

---

## 19. Screen-by-Screen Reference

This section describes every input screen and dialog box in the application, organized by section. It shows exactly which fields appear on each screen, what they accept, and what happens when you save.

---

### 19.1 Sign-In Screen

**When it appears:** Automatically when you open the application.

| Field | What to Enter |
|---|---|
| Username | Your assigned username |
| Password | Your password (hidden as you type) |

**Buttons:** Sign In, Cancel  
**Rules:** Both fields are required. If your username is not found or the password is wrong, access is denied.

---

### 19.2 General Application Screens

#### About Screen

**How to open:** Help → About menu item.

Displays the application name, version number, release date, and author. Read-only — no input required.

**Buttons:** Close

---

#### Support Request

**How to open:** Help → Support Request menu item.

Use this to send a help request directly from the application.

| Field | What to Enter |
|---|---|
| Your Name | Your full name |
| Contact Info | Your email address or phone number |
| Type of Problem | Choose: Bug / Error, Question, Feature Request, Performance Issue, Other |
| Description | Explain what happened or what you need |

**Buttons:** Submit, Cancel  
**Rules:** Name and Description are required. Your email settings must be configured for the message to send.

---

#### To-Do Item

**How to open:** Dashboard → Add To-Do button, or double-click an existing task.

| Field | What to Enter |
|---|---|
| Title | Short name for the task (required) |
| Notes | Optional details or reminders |
| Due Date | Date in MM/DD/YYYY format (click the calendar icon to pick a date) |
| Priority | Low, Normal (default), or High |
| Status | Open (default), In Progress, or Done |

**Buttons:** Save, Cancel

---

### 19.3 Configuration Screens

#### Company Info

**How to open:** Configuration → Company Info tab.

| Field | What to Enter |
|---|---|
| Company Name | Your business name as it appears on invoices |
| Address Lines 1 & 2 | Street address |
| City, Province, Postal Code, Country | Mailing address |
| Phone, Fax, Email, Website | Contact details shown on invoices |
| Logo Path | Click Browse to select your logo image (PNG or JPG) |

**Buttons:** Save Company Info

---

#### Fiscal Year & Settings

**How to open:** Configuration → Fiscal Year & Settings tab.

| Field | What to Enter |
|---|---|
| Fiscal Year Start / End | The first and last day of your financial year (YYYY-MM-DD) |
| Tax Rate (%) | The HST or GST rate you charge (e.g., 13 for 13%) |
| Currency | Your currency code (e.g., CAD) |
| Invoice Prefix | The text before invoice numbers (e.g., INV-) |
| Next Invoice # | The next invoice number to assign |
| Next Journal # | The next journal entry number to assign |
| Accounts Receivable Account | Select from your financial category list — this is where unpaid invoices are tracked |
| Revenue Account | Select the category where your income is recorded |
| Tax Account | Select the category where collected taxes are held |
| Cash / Bank Account | Select the category that represents your bank account |

**Buttons:** Save Settings

---

#### Email Settings

**How to open:** Configuration → Email Settings tab.

| Field | What to Enter |
|---|---|
| SMTP Host | Your email server address (e.g., smtp.gmail.com) |
| SMTP Port | Usually 587 for Gmail/Office 365 |
| SMTP User | The email address emails are sent from |
| SMTP Password | Your email account password (hidden as you type) |
| Use TLS | Enter 1 to use secure connection (recommended), 0 to disable |
| Support Email | The email address where support requests are sent |
| Invoice Email Subject | The subject line template for invoice emails — you can use {invoice_number}, {customer}, {total}, {company}, {date} as placeholders |
| Invoice Email Body | The body template for invoice emails — same placeholders available |

**Buttons:** Save Email Settings

---

#### Timesheet Settings

**How to open:** Configuration → Timesheet tab.

| Field | What to Enter |
|---|---|
| Default Shift | Choose a default workday: "8 to 4" (8:00 AM–4:00 PM) or "9 to 5" (9:00 AM–5:00 PM) — both are 7.5 hours |
| Require client approval | Check this box if you want the timesheet email to include an approval request to the client |

**Buttons:** Save Timesheet Settings

---

#### Client Record

**How to open:** Configuration → Clients → Add Client or Edit Client button.

The client form has three tabs:

**Tab 1 — General (Contact Information)**

| Field | Notes |
|---|---|
| Company Name | Required — the client's business name |
| Contact | Primary contact person's name |
| Address 1 & 2 | Street address |
| City, Country, Province, Postal Code | Location details (province list filters automatically by country) |
| Phone, Cell, Fax | Phone numbers in (###) ###-#### format |
| Email | Client's email address |
| Website | Client's website (click the globe icon to open in browser) |
| Currency | Filled automatically when you select a country |
| Type | A label for the type of client (optional) |
| Client Manager — Name, Phone, Email | The client-side contact who approves timesheets and receives copies |

**Tab 2 — Shipping Address**

| Field | Notes |
|---|---|
| Same as billing address | Check this box to copy the billing address automatically |
| Country, Province, Address, City, Postal | Alternate delivery address if different from billing |

**Tab 3 — Settings**

| Field | Notes |
|---|---|
| Assigned Consultant | Which staff member manages this client |
| Revenue Category | Which financial category income from this client is recorded under |
| Tax Code | The tax rate applied to invoices for this client (e.g., HST 13%) |
| Credit Limit | Maximum outstanding balance before a warning (optional) |
| Payment Terms | How long the client has to pay (e.g., Net 30 = 30 days) |
| Language | English or French (affects invoice language if supported) |
| Invoice Delivery | How you send invoices: email, mail, fax, or none |
| Notes | Any internal notes about this client |

**Buttons:** Save, Cancel  
**Rules:** Company name is required.

---

#### Service / Item Record

**How to open:** Configuration → Services → Add Item or Edit Item.

| Field | Notes |
|---|---|
| Item Code | A short code for the service (required, e.g., CONSULT, TRAVEL) |
| Description | Full description as it appears on invoices |
| Type | Service or Product |
| Unit | What you bill in (e.g., hrs, day, each) |
| Price | Default price per unit |
| Cost | Your cost for this item (for your own records) |
| Revenue Category | Which financial category this item's income goes into |

**Buttons:** Save, Cancel

---

#### Project Record

**How to open:** Configuration → Projects → Add Project or Edit Project.

| Field | Notes |
|---|---|
| Project Code | A short unique identifier (required) |
| Start Date | When the project began (MM/DD/YYYY) |

**Buttons:** Save, Cancel

---

#### Consultant / Staff Record

**How to open:** Configuration → Consultants → Add or Edit.

| Field | Notes |
|---|---|
| Name | Full name (required) |
| Signature Image | Optional: path to a signature image file for printed invoices and timesheets |

**Buttons:** Save, Cancel

---

#### Tax Code

**How to open:** Configuration → Tax Codes → Add or Edit.

A tax code can have multiple components (e.g., a combined GST + PST code):

| Field | Notes |
|---|---|
| Code | A short identifier like HST or GST (required; cannot be changed after creation) |
| Name | Full description |
| Tax Components | A list of individual tax rates — click Add Component to define each one |

**For each tax component:**

| Field | Notes |
|---|---|
| Name | e.g., HST, GST, PST |
| Rate (%) | The percentage rate (e.g., 13) |
| Tax Category | Which financial category this tax is collected into |

---

#### Country

**How to open:** Configuration → Countries → Add or Edit.

| Field | Notes |
|---|---|
| Code | 2–3 letter country code (e.g., CA, US) — cannot be changed after creation |
| Name | Country name (required) |
| Currency | 3-letter currency code (e.g., CAD, USD) |

---

#### Province / State

**How to open:** Configuration → Provinces → Add or Edit.

| Field | Notes |
|---|---|
| Country | Select which country this province/state belongs to |
| Code | Short code (e.g., ON, QC, NY) — cannot be changed after creation |
| Name | Full name (required) |

---

#### Payment Terms

**How to open:** Configuration → Payment Terms → Add or Edit.

| Field | Notes |
|---|---|
| Name | A descriptive label (required), e.g., "Net 30", "Due on Receipt" |

---

#### User Account

**How to open:** Configuration → Users (admin only) → Add User or Edit User.

| Field | Notes |
|---|---|
| Username | The login name (required) |
| Full Name | The person's display name (required) |
| Email | Used for welcome emails |
| Role | Admin (full access) or Accountant (access controlled per section) |
| Password | Required when creating a new user; not shown when editing |
| Confirm Password | Must match the password field exactly (new users only) |

**Buttons:** Save, Cancel

---

#### Change Password

**How to open:** Configuration → Users → select a user → Change Password button (admin only).

| Field | Notes |
|---|---|
| New Password | The new password (required) |
| Confirm | Must match the new password exactly |

**Buttons:** Save, Cancel

---

### 19.4 Invoicing Screens

#### Invoice Editor

**How to open:** Invoicing → New Invoice, or double-click an existing invoice.

**Invoice header:**

| Field | Notes |
|---|---|
| Invoice # | Assigned automatically (e.g., INV-1024) |
| Date | Invoice date in MM/DD/YYYY — click the calendar icon to pick |
| Status | Draft, Sent, Paid, Cancelled, or Posted |
| Client | Select from your client list |
| Project | Select from your project list (optional) |
| Consultant | The staff member associated with this invoice |

**Line items** — add the services you are billing for:

Use **Add Line Item** to add a service from your list, or **Add Comment** to insert a text note on the invoice (e.g., "Payment due within 30 days").

Each service line shows: Item, Description, Quantity, Unit Price, and Amount (calculated automatically).

**Totals** are calculated automatically: Subtotal, Tax (HST), and Total.

**Buttons:** Save, Cancel, Print PDF, Email, Attachments  
**Rules:** A client must be selected; at least one service line is required.

---

#### Add / Edit Service Line

**How to open:** Add Line Item or Edit on a line in the Invoice Editor.

| Field | Notes |
|---|---|
| Service | Pick from your services list (start typing to filter) |
| Description | Auto-filled; you can change it |
| Quantity | How many units |
| Unit Price | Auto-filled from your services list; you can change it |
| Amount | Calculated automatically (Quantity × Unit Price) |

---

#### Add Comment Line

**How to open:** Add Comment button in the Invoice Editor.

| Field | Notes |
|---|---|
| Comment | Any text note to appear on the invoice |

---

#### Invoice Attachments

**How to open:** Attachments button in the Invoice Editor.

Attach files (contracts, photos, purchase orders) to the invoice for your own records. Click **Add Attachment** to browse for a file; select and click **Delete Attachment** to remove one.

---

#### Print / Select Printer

If you have multiple printers, a dialog appears for you to choose which one to use when printing the PDF.

---

### 19.5 Recording Payments

#### Payment Receipt

**How to open:** Cash Receipts → New Receipt, or double-click an existing receipt.

| Field | Notes |
|---|---|
| Receipt # | Assigned automatically (e.g., CR-1001) |
| Date | Date the payment was received (MM/DD/YYYY) |
| Client | Select who paid |
| Apply to Invoice | Optionally link this payment to a specific open invoice |
| Amount | How much was received |
| Bank Account | Select the financial category for your bank account |
| Memo | Optional note (e.g., "Cheque #4521" or "e-Transfer") |

**Buttons:** Save, Cancel, Post  
**Rules:** Client, Amount, and Bank Account are required. Clicking **Post** finalizes the record — this cannot be undone.

---

### 19.6 Manual Adjustment (Journal)

#### Journal Entry Editor

**How to open:** Journal → New Journal Entry, or double-click an existing entry.

**Header:**

| Field | Notes |
|---|---|
| Entry # | Assigned automatically |
| Date | Date of the adjustment (MM/DD/YYYY) |
| Description | What this adjustment is for |
| Reference | Optional reference number (e.g., a vendor invoice number) |

**Lines** — add the financial categories being adjusted. Each line has:

| Field | Notes |
|---|---|
| Account | Select the financial category |
| Description | What this line represents |
| Debit (+) | Amount being added to this category |
| Credit (−) | Amount being removed from this category |

The running total at the bottom shows whether your entry is balanced. The entry cannot be saved until debits equal credits.

---

#### Add / Edit Journal Line

**How to open:** Add Line or Edit Line button in the Journal Entry Editor.

| Field | Notes |
|---|---|
| Account | Select the financial category (start typing to filter) |
| Description | Brief note for this line |
| Debit | Amount to increase (leave at 0 if using credit) |
| Credit | Amount to decrease (leave at 0 if using debit) |

**Rules:** A category must be selected; exactly one of Debit or Credit must be non-zero.

---

### 19.7 Financial Categories (Chart of Accounts)

#### Add / Edit Category

**How to open:** Chart of Accounts → Add Account, or Edit Account on a selected row.

| Field | Notes |
|---|---|
| Account Number | A unique code (e.g., 1060 for bank, 4000 for revenue) — cannot be changed after creation |
| Account Name | Descriptive name (required) |
| Opening Balance | Starting balance when you first set up the system |
| Balance Type | Dr = normally holds positive values (assets, expenses); Cr = normally holds positive values (liabilities, income) |

---

#### Transaction History Viewer

**How to open:** Double-click a category row in the Chart of Accounts.

Shows all transactions posted to that category — date, description, source, amounts. Read-only.

---

#### Export Format Picker

**How to open:** Chart of Accounts → Export button.

Choose: **CSV**, **Excel**, or **PDF** — the export starts immediately.

---

### 19.8 Timesheet Screens

#### Daily Time Entry

**How to open:** Click on a date cell in the timesheet grid.

| Field | Notes |
|---|---|
| AM Start / AM End | Morning shift start and end times (HH:MM) |
| PM Start / PM End | Afternoon shift start and end times (HH:MM) |
| Other Start / Other End | Overtime or additional time period (HH:MM) |
| Total Hours | Calculated automatically from the six time fields |

---

#### Work Item

**How to open:** Add Work Item button in the timesheet, or double-click an existing work item.

| Field | Notes |
|---|---|
| Description | What work was done that day (required) |
| Task Reference # | Optional — enter a ticket number, DevOps item number, etc. |
| Hours | How many hours this specific task took |

---

#### Import Preview

**How to open:** Import from TPG File button after a file is selected and parsed.

Shows a preview table of the rows the application read from the file. Review the dates, times, and hours before confirming.

**Buttons:** Confirm Import (saves the data), Cancel

---

#### Client Picker (for Email)

**How to open:** Email Timesheet button when the client has not yet been linked.

Displays a searchable list of your clients. Type to filter; select one and click **Select**.

---

### 19.9 All Screens at a Glance

| Section | Screen | Purpose |
|---|---|---|
| Sign-In | Sign-In Screen | Open the application |
| App | About Screen | Application version information |
| App | Support Request | Send a help request by email |
| App | To-Do Item | Add or edit a personal task on the dashboard |
| Config | Client Record | Add or edit a client (3 tabs, 30+ fields) |
| Config | Service / Item | Add or edit a billable service |
| Config | Project | Add or edit a project |
| Config | Consultant / Staff | Add or edit a consultant |
| Config | Tax Code | Add or edit a tax rate with components |
| Config | Country | Add or edit a country |
| Config | Province / State | Add or edit a province or state |
| Config | Payment Terms | Add or edit a payment term |
| Config | User Account | Add or edit a user account |
| Config | Change Password | Reset a user's password |
| Invoicing | Invoice Editor | Create or edit an invoice |
| Invoicing | Add Service Line | Add a billable service to an invoice |
| Invoicing | Add Comment Line | Add a text note to an invoice |
| Invoicing | Invoice Attachments | Attach files to an invoice |
| Invoicing | Select Printer | Choose a printer for PDF output |
| Cash Receipts | Payment Receipt | Record a payment from a client |
| Journal | Journal Entry Editor | Create or edit a manual financial adjustment |
| Journal | Add / Edit Journal Line | Add a line to a journal entry |
| Chart of Accounts | Add / Edit Category | Add or edit a financial category |
| Chart of Accounts | Transaction History | View all transactions for a category |
| Chart of Accounts | Export Format Picker | Choose CSV, Excel, or PDF export |
| Timesheets | Daily Time Entry | Enter start and end times for a workday |
| Timesheets | Work Item | Add or edit a task description for a day |
| Timesheets | Import Preview | Confirm rows before importing a TPG file |
| Timesheets | Client Picker | Select a client when emailing a timesheet |

---

*End of Guide*
