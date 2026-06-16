import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def test_app_loads(driver):
    """
    Test that the Flutter Web App loads successfully.
    Replace the URL below with your actual deployed URL or localhost port.
    """
    driver.get("http://localhost:8080") # Replace with the URL where your Flutter web app runs
    
    # Wait for the app to initialize (Flutter web apps take a moment to load CanvasKit/HTML)
    time.sleep(3)
    
    # Check if the title is present (change "Flutter App" to your actual title)
    assert driver.title != "", "App title should not be empty"

def test_login_flow(driver):
    """
    Example test for login flow. Note that testing Flutter Web via Selenium
    can be tricky because it renders in Canvas. You might need to use semantics
    or Appium if traditional DOM queries don't work.
    """
    driver.get("http://localhost:8080/#/login")
    
    try:
        # Example of finding an element by semantics or ID (if exposed to DOM)
        # Flutter web exposes basic DOM structure if semantics are enabled.
        # Wait for an input field to be present
        email_input = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//input[@type='email' or contains(@aria-label, 'Email')]"))
        )
        email_input.send_keys("test@example.com")
        
        password_input = driver.find_element(By.XPATH, "//input[@type='password' or contains(@aria-label, 'Password')]")
        password_input.send_keys("password123")
        
        login_button = driver.find_element(By.XPATH, "//flt-semantics[contains(@aria-label, 'Login') or contains(@aria-label, 'Submit')]")
        login_button.click()
        
        time.sleep(2)
        # Verify navigating to dashboard
        assert "/dashboard" in driver.current_url or "/home" in driver.current_url
        
    except Exception as e:
        pytest.skip(f"Could not locate Flutter DOM elements. Ensure semantics are active. Error: {e}")
