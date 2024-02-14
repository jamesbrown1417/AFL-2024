# Import Modules=============================================================
from selenium_driverless import webdriver
from selenium_driverless.types.by import By
from datetime import datetime

# Get current timestamp=======================================================
now = datetime.now()
time_stamp = now.strftime("%Y-%m-%d_%H-%M-%S")

# Get H2H HTML===============================================================
import asyncio

async def main():
    options = webdriver.ChromeOptions()
    # options.add_argument("--headless=True")

    async with webdriver.Chrome(options=options) as driver:
        await driver.get('https://www.bet365.com.au/#/AC/B36/C20925848/D48/E360013/F48/')
        await driver.sleep(0.5)
        
        # wait 10s for elem to exist
        elem = await driver.find_element(By.XPATH, "//div[contains(@class, 'src-MarketGroup')]", timeout=10)
        body_html = await elem.get_attribute('outerHTML')
        
        # Write html to file - overwrite existing file
        with open(f"Data/BET365_HTML/h2h_html.txt", 'w') as f:
            f.write(body_html)

asyncio.run(main())
