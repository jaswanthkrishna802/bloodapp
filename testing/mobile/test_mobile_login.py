import pytest
from appium.webdriver.common.appiumby import AppiumBy

def test_app_launches(driver):
    """Test that the app launches successfully."""
    assert driver.is_app_installed("com.example.blood_app"), "App should be installed"

def test_login_flow(driver):
    """Test login flow on mobile using Appium and Flutter accessibility IDs."""
    driver.implicitly_wait(10)

    # Flutter widgets are located by their Semantics label (set using Semantics widget)
    email_field = driver.find_element(by=AppiumBy.ACCESSIBILITY_ID, value="Email Field")
    email_field.send_keys("testuser@example.com")

    password_field = driver.find_element(by=AppiumBy.ACCESSIBILITY_ID, value="Password Field")
    password_field.send_keys("password123")

    login_button = driver.find_element(by=AppiumBy.ACCESSIBILITY_ID, value="Login Button")
    login_button.click()

    # Wait and verify dashboard screen appears
    import time
    time.sleep(3)
    dashboard = driver.find_element(by=AppiumBy.ACCESSIBILITY_ID, value="Dashboard")
    assert dashboard.is_displayed(), "Dashboard should be visible after login"
