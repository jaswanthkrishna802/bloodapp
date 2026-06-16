import pytest
from appium import webdriver
from appium.options.android import UiAutomator2Options

@pytest.fixture(scope="session")
def driver():
    options = UiAutomator2Options()
    options.platform_name = "Android"
    options.automation_name = "UiAutomator2"
    options.device_name = "Android Emulator"
    # Update this path with your built APK
    options.app = "build/app/outputs/flutter-apk/app-release.apk"
    options.app_package = "com.example.blood_app"
    options.app_activity = ".MainActivity"

    driver = webdriver.Remote("http://localhost:4723", options=options)
    driver.implicitly_wait(15)
    yield driver
    driver.quit()
