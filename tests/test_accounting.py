"""Exercise the real COBOL executable through its terminal, using isolated data."""
import argparse
import csv
from decimal import Decimal
import os
from pathlib import Path
import subprocess
import tempfile
import threading
import unittest

ROOT = Path(__file__).resolve().parents[1]
OPTIONS = None


def settings(rate="13"):
    return ["2", "1", "Test Business", "CAD", "2026-01-01", "2026-12-31", rate, "Y"]


def client(name='Acme, "North"'):
    return ["2", "2", name, "billing@example.test", "1 Main Street", "Y"]


def service():
    return ["2", "4", "Consulting", "CONSULT", "100", "Y"]


def invoice(qty="10", price="100", date="2026-11-10", save="Y"):
    return ["3", "1", "1", date, "0", "0", "Thank you", "1", "1", qty, price, save]


def approve(number="1"):
    return ["3", "4", number, "Y"]


def receipt(amount="400", post=None):
    result = ["4", "1", "1", "2026-11-11", amount, "Bank transfer", "Y"]
    if post:
        result += ["4", "4", post, "Y"]
    return result


def journal(debit="250", credit="250", save="Y"):
    result = ["5", "1", "2026-11-12", "Software expense", "REF-1", "2",
              "5000", debit, "0", "1000", "0", credit]
    if Decimal(debit) == Decimal(credit):
        result += [save]
    return result


class AccountingTests(unittest.TestCase):
    def setUp(self):
        temp_root = ROOT / "tests" / ".tmp"
        temp_root.mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=temp_root)
        self.folder = Path(self.temp.name)
        self.export = self.folder / "accountant.csv"

    def tearDown(self):
        self.temp.cleanup()

    def command(self, sql=False):
        relative = self.folder.relative_to(ROOT).as_posix()
        if OPTIONS.docker_image:
            return ["docker", "run", "--rm", "-i", "--entrypoint",
                    "/workspace/build/myaccounting", "--mount",
                    f"type=bind,source={ROOT},target=/workspace", "--workdir", "/workspace",
                    "-e", f"MYACCOUNT_FILE=/workspace/{relative}/accounts.dat",
                    "-e", f"MYACCOUNT_EXPORT=/workspace/{relative}/accountant.csv",
                    "-e", f"MYACCOUNT_SQL_DIR={'/workspace/' + relative + '/sql' if sql else ''}",
                    OPTIONS.docker_image]
        return [str(Path(OPTIONS.exe).resolve())]

    def environment(self, sql=False):
        return dict(os.environ, MYACCOUNT_FILE=str(self.folder / "accounts.dat"),
                    MYACCOUNT_EXPORT=str(self.export),
                    MYACCOUNT_SQL_DIR=str(self.folder / 'sql') if sql else '')

    def run_app(self, entries, *, exit_code=0, end=True, sql=False):
        data = "\n".join(entries + (["0"] if end else [])) + "\n"
        result = subprocess.run(self.command(sql), input=data, text=True,
                                capture_output=True, env=self.environment(sql),
                                cwd=ROOT, timeout=30)
        self.assertEqual(result.returncode, exit_code, result.stdout + result.stderr)
        self.assertNotIn("libcob:", result.stderr, result.stderr)
        return result.stdout

    def bootstrap(self):
        return settings() + client() + service()

    def csv_rows(self):
        with self.export.open(newline="") as stream:
            return list(csv.DictReader(stream))

    def test_invoice_receipt_journal_reports_and_restart(self):
        output = self.run_app(self.bootstrap() + invoice() + approve()
                              + receipt(post="1") + journal()
                              + ["5", "4", "1", "Y", "1", "7", "1",
                                 "2026-01-01", "2026-12-31", "7", "2", "2026-12-31",
                                 "7", "3", "2026-12-31", "9"])
        for expected in ["Tax: 130.00", "Total: 1130.00", "Total receivables: 730.00",
                         "Revenue: 1000.00", "Expenses: 250.00", "Net profit: 750.00",
                         "Assets: 880.00", "Liabilities: 130.00",
                         "Balance sheet difference: 0.00", "Trial balance difference: 0.00"]:
            self.assertIn(expected, output)
        rows = self.csv_rows()
        self.assertEqual(len(rows), 7)
        self.assertEqual(sum(Decimal(row["debit"]) for row in rows), Decimal("1780"))
        self.assertEqual(sum(Decimal(row["credit"]) for row in rows), Decimal("1780"))
        self.assertEqual(rows[0]["description"], 'Acme, "North"')
        self.assertIn("Total receivables: 730.00", self.run_app(["1"]))

    def test_drafts_and_void_invoices_do_not_post(self):
        output = self.run_app(self.bootstrap() + invoice() + ["1", "9"])
        self.assertIn("Total receivables: 0.00", output)
        self.assertEqual(self.csv_rows(), [])
        output = self.run_app(approve() + ["3", "5", "1", "Y", "1", "9"])
        self.assertIn("Invoice void", output)
        self.assertIn("Total receivables: 0.00", output)
        self.assertEqual(self.csv_rows(), [])

    def test_posted_documents_locked_and_paid_invoice_cannot_void(self):
        output = self.run_app(self.bootstrap() + invoice() + approve()
                              + receipt(post="1") + journal() + ["5", "4", "1", "Y",
                                 "4", "4", "1", "5", "4", "1", "3", "5", "1",
                                 "3", "6", "1", "5", "5", "1"])
        for message in ["Only draft receipts", "Only draft journals", "cannot void",
                        "Only drafts can be replaced"]:
            self.assertIn(message, output)

    def test_stale_draft_receipt_cannot_overpay(self):
        self.run_app(self.bootstrap() + invoice() + approve()
                     + receipt("800") + receipt("800") + ["4", "4", "1", "Y"])
        output = self.run_app(["4", "4", "2", "1", "9"])
        self.assertIn("Payment exceeds current outstanding balance", output)
        self.assertIn("Total receivables: 330.00", output)
        self.assertEqual(len(self.csv_rows()), 5)

    def test_unbalanced_journal_and_control_account_rejected(self):
        output = self.run_app(settings() + journal("100", "99")
                              + ["5", "1", "2026-11-12", "Bad AR adjustment", "", "2",
                                 "1100", "9"])
        self.assertIn("Journal must balance; not saved", output)
        self.assertIn("Use invoices/receipts for account 1100", output)
        self.assertEqual(self.csv_rows(), [])

    def test_rounding_and_invalid_numeric_input(self):
        commands = self.bootstrap() + invoice("0.5", "0.01")
        # Negative, exponent, extra decimals, and overflow are all reprompted.
        commands[-3:-3] = ["-1", "1e2", "1.001", "9999999999999"]
        output = self.run_app(commands + approve() + ["9"])
        self.assertEqual(output.count("Invalid number or out of range"), 4)
        self.assertIn("Subtotal: 0.01", output)
        self.assertEqual(sum(Decimal(r["debit"]) for r in self.csv_rows()), Decimal("0.01"))

    def test_invalid_dates_and_fiscal_range_reprompt(self):
        commands = self.bootstrap() + invoice()
        position = commands.index("2026-11-10")
        commands[position:position] = ["2026-02-30", "2025-12-31", "11/10/2026"]
        output = self.run_app(commands)
        self.assertIn("real calendar date", output)
        self.assertIn("inside the configured fiscal year", output)
        self.assertIn("Draft invoice saved", output)

    def test_cancelled_work_and_eof_do_not_save(self):
        self.run_app(self.bootstrap() + invoice(save="N"))
        output = self.run_app(["3", "3", "1"])
        self.assertIn("Document not found", output)
        output = self.run_app(["3", "1", "1"], end=False)
        self.assertIn("unfinished work discarded", output)
        self.assertIn("Document not found", self.run_app(["3", "3", "1"]))

    def test_duplicate_accounts_services_and_date_filtered_reports(self):
        output = self.run_app(self.bootstrap() + ["6", "2", "1000",
                              "2", "4", "Duplicate service", "CONSULT"]
                              + invoice() + approve() + ["7", "1", "2026-01-01",
                                 "2026-10-31", "7", "3", "2026-10-31"])
        self.assertIn("Account code already exists", output)
        self.assertIn("Service code already exists", output)
        self.assertIn("Revenue: 0.00", output)
        self.assertIn("Trial balance difference: 0.00", output)

    def test_timesheet_hours_unique_month_and_lifecycle(self):
        base = settings() + client() + ["2", "8", "Daniel", "Y"]
        new_sheet = ["8", "1", "1", "1", "0", "2026-11-10", "Y"]
        duplicate = ["8", "1", "1", "1", "0", "2026-11-23"]
        day = ["8", "4", "1", "2026-11-10", "TASK-42 Development",
               "09:00", "12:00", "12:30", "17:00", "00:00", "00:00", "Y"]
        output = self.run_app(base + new_sheet + duplicate + day
                              + ["8", "5", "1", "Y", "8", "7", "1", "Y",
                                 "8", "4", "1", "8", "8", "1", "Y",
                                 "8", "5", "1", "Y", "8", "6", "1", "Y",
                                 "8", "4", "1", "8", "3", "1"])
        self.assertIn("already has a sheet for this month", output)
        self.assertIn("Total hours: 7.50", output)
        self.assertIn("status updated: R", output)
        self.assertIn("status updated: A", output)
        self.assertIn("Submitted/approved sheets are locked", output)
        self.assertIn("State: A", self.run_app(["8", "3", "1"]))

    def test_replacing_drafts_preserves_number_and_cancel_keeps_original(self):
        self.run_app(self.bootstrap() + invoice())
        replacement = invoice("2", "100")
        # Replace instead of creating, supplying the draft number first.
        replacement[1:2] = ["6", "1"]
        output = self.run_app(replacement + ["3", "3", "1"])
        self.assertIn("Total: 226.00", output)
        cancel = invoice("3", "100", save="N")
        cancel[1:2] = ["6", "1"]
        self.run_app(cancel)
        output = self.run_app(["3", "3", "1"])
        self.assertIn("Total: 226.00", output)
        self.assertNotIn("Total: 339.00", output)
        self.run_app(journal("50", "50"))
        replacement = journal("25", "25")
        replacement[1:2] = ["5", "1"]
        output = self.run_app(replacement + ["5", "3", "1"])
        self.assertIn("JOURNAL JE-1", output)
        self.assertIn("Total debits: 25.00", output)

    def test_custom_account_history_and_invoice_overflow(self):
        commands = self.bootstrap() + ["6", "2", "5100", "Professional fees", "X", "Y"]
        expense = journal("75", "75")
        expense[expense.index("5000")] = "5100"
        output = self.run_app(commands + expense + ["5", "4", "1", "Y",
                              "6", "3", "5100", "7", "1", "2026-01-01", "2026-12-31"])
        self.assertIn("HISTORY 5100 Professional fees", output)
        self.assertIn("JE-00000001 Software expense 75.00", output)
        self.assertIn("Expenses: 75.00", output)
        # A valid input pair can still produce an unrepresentable line total.
        overflow = invoice("99999.99", "99999999.99")[:-1]
        output = self.run_app(overflow + ["3", "3", "1"])
        self.assertIn("Line amount too large", output)
        self.assertIn("Document not found", output)

    def test_exclusive_session_lock(self):
        self.run_app(settings())
        first = subprocess.Popen(self.command(), stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE, text=True, env=self.environment(), cwd=ROOT)
        watchdog = threading.Timer(20, first.kill)
        watchdog.start()
        try:
            first.stdin.write("6\n1\n")
            first.stdin.flush()
            # This line proves the first session has opened and read the file.
            for line in first.stdout:
                if "Trial balance difference:" in line:
                    break
            else:
                self.fail("First session did not open the ledger")
            output = self.run_app([], exit_code=1)
            self.assertIn("Cannot open data file", output)
            first.communicate("0\n", timeout=10)
            self.assertEqual(first.returncode, 0)
        finally:
            watchdog.cancel()
            if first.poll() is None:
                first.kill()
                first.communicate()

    def sql_fixture(self):
        directory = self.folder / 'sql'
        directory.mkdir()
        views = {
            'company.txt': 'My Demo Consulting Services',
            'overview.txt': 'Division: My Demo Consulting Services (company_id=2)',
            'invoices.txt': '4 | INV-20245031 | 8362.00 | Posted | CAD',
            'invoice-4.txt': 'INVOICE INV-20245031\nSoftware Development | 7400.00\nTax: 962.00\nNo receipts.',
            'customers.txt': 'Atlantic Digital Solutions Inc.',
            'receipts.txt': 'No records for this division.',
        }
        for name, value in views.items():
            (directory / name).write_text(value + '\n', encoding='utf-8')
        return directory

    def test_sql_browser_lists_details_and_ignores_local_lock(self):
        self.sql_fixture()
        # A local ledger session must not block the independent SQL reader.
        lock = self.folder / 'accounts.dat.lock'
        lock.mkdir()
        output = self.run_app(['3', '3', '4', '3', '1', '0', '2', '1', '4'], sql=True)
        for expected in ['SQL Server browser', 'INV-20245031',
                         'Software Development | 7400.00', 'Tax: 962.00',
                         'No record found for this division.', 'Atlantic Digital',
                         'No records for this division.']:
            self.assertIn(expected, output)
        self.assertNotIn('New invoice', output)
        self.assertFalse((self.folder / 'accounts.dat').exists())
        self.assertTrue(lock.is_dir())

    def test_sql_browser_rejects_paths_and_exits_on_eof(self):
        self.sql_fixture()
        output = self.run_app(['3', '3', '../1', '2147483648', '4'], sql=True, end=False)
        self.assertEqual(output.count('Invalid number or out of range'), 2)
        self.assertIn('INVOICE INV-20245031', output)
        self.assertIn('Goodbye.', output)
        self.assertFalse((self.folder / 'accounts.dat').exists())

    def test_sql_browser_missing_snapshot_fails_without_local_fallback(self):
        self.run_app([], sql=True, exit_code=1)
        self.assertFalse((self.folder / 'accounts.dat').exists())
        self.assertFalse((self.folder / 'accounts.dat.lock').exists())


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--docker-image")
    parser.add_argument("--exe", default=str(ROOT / "build" / "myaccounting"))
    OPTIONS, rest = parser.parse_known_args()
    unittest.main(argv=[__file__] + rest, verbosity=2)
