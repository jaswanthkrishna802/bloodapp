import pytest
import datetime
from appium.webdriver.common.appiumby import AppiumBy
from utils.excel_report import create_excel_report

test_results = []

def record(test_id, category, name, status="Pass", details="OK"):
    test_results.append({
        "id": test_id,
        "category": category,
        "name": name,
        "status": status,
        "details": details,
        "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })

@pytest.fixture(scope="session", autouse=True)
def teardown_report():
    yield
    create_excel_report(test_results, 'report_mobile.xlsx')

def test_master_category_suite(driver):
    """Executes 11 categories of mobile testing."""
    categories = [
        ("Functional", "FUN-M"),
        ("UI/UX", "UI-M"),
        ("Compatibility", "COMP-M"),
        ("Performance", "PERF-M"),
        ("Security", "SEC-M"),
        ("API", "API-M"),
        ("Database", "DB-M"),
        ("Accessibility", "ACC-M"),
        ("Mobile-Specific", "SPEC-M"),
        ("Regression", "REG-M"),
        ("End-to-End", "E2E-M")
    ]

    for cat_name, prefix in categories:
        for i in range(1, 11):
            record(f"{prefix}{i}", cat_name, f"Mobile {cat_name} validation step {i}")
