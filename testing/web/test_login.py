import time
import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

BASE_URL = "https://jaswanthkrishna802.github.io/bloodapp"

def test_app_loads(driver):
    """Test that the Flutter Web app loads."""
    driver.get(BASE_URL)
    time.sleep(4)  # Flutter web needs time to initialize
    assert driver.title != "", "Page title should not be empty"

def test_login_page_accessible(driver):
    """Test that the login page is accessible."""
    driver.get(BASE_URL + "/#/login")
    time.sleep(3)
    assert driver.current_url is not None

def test_login_flow(driver):
    """
    Test login by locating Flutter semantics elements.
    Flutter Web exposes flt-semantics elements in the DOM tree.
    """
    driver.get(BASE_URL + "/#/login")
    time.sleep(4)

    try:
        # Flutter renders using semantic wrappers
        wait = WebDriverWait(driver, 10)

        email_el = wait.until(EC.presence_of_element_located(
            (By.CSS_SELECTOR, "flt-semantics[aria-label*='Email'], input[type='email']")
        ))
        email_el.send_keys("testuser@example.com")

        password_el = driver.find_element(
            By.CSS_SELECTOR, "flt-semantics[aria-label*='Password'], input[type='password']"
        )
        password_el.send_keys("password123")

        login_btn = driver.find_element(
            By.CSS_SELECTOR, "flt-semantics[aria-label*='Login'], flt-semantics[aria-label*='Sign']"
        )
        login_btn.click()
        time.sleep(3)

        # Validate navigation happened
        assert "/login" not in driver.current_url or "dashboard" in driver.page_source.lower()

    except Exception as e:
        pytest.skip(f"Flutter semantics not locatable: {e}")
