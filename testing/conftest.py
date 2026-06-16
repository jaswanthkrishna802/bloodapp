import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service

@pytest.fixture(scope="session")
def driver():
    """
    Setup Chrome WebDriver for Selenium testing.
    """
    chrome_options = Options()
    # chrome_options.add_argument("--headless") # Uncomment to run invisibly
    chrome_options.add_argument("--window-size=1920,1080")
    
    # Initialize the driver (ensure chromedriver is in PATH or specify Service path)
    driver = webdriver.Chrome(options=chrome_options)
    
    # Implicit wait for elements to appear
    driver.implicitly_wait(10)
    
    yield driver
    
    # Teardown after all tests in the session
    driver.quit()
