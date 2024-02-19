from selenium import webdriver
import os
from os import path
from time import sleep
import shutil
import time
import glob
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
import logging
import subprocess
import exceptions
# import getpass
DBNAME = 'sodexis-inc'
USERNAME = "sodexis@sodexis.com"
PASSWORD = ""
DOWNLOAD_DIR = ""
CHROMEDRIVER_PATH = ""
FILES_TO_KEEP = 2
EMAIL_TO = "janarthanan@sodexis.com"
logger = logging.getLogger(__name__)




class DownlodDump:
    def download_dump(self):
        password = PASSWORD #getpass.getpass('Please enter the password:')
        db_name = DBNAME #raw_input("Please enter db_name")
        download_dir = DOWNLOAD_DIR
        file_name = path.join(download_dir,"{0}.dump.zip".format(db_name))
        options = webdriver.ChromeOptions()
        options.add_argument("headless") #comment this line to check the background process in chrome
        preferences = {"directory_upgrade": True,
                       "download.default_directory": download_dir,
                       "safebrowsing.enabled": True}
        options.add_experimental_option("prefs", preferences)
        options.add_argument("no-sandbox")
        d = DesiredCapabilities.CHROME
        d['loggingPrefs'] = {'browser': 'ALL'}
        driver = webdriver.Chrome(chrome_options=options,executable_path=CHROMEDRIVER_PATH, desired_capabilities=d)
        driver.command_executor._commands["send_command"] = ("POST", '/session/$sessionId/chromium/send_command')
        params = {'cmd': 'Page.setDownloadBehavior', 'params': {'behavior': 'allow', 'downloadPath': download_dir}}
        driver.execute("send_command", params)
        driver.get('https://{0}.odoo.com/web/login'.format(db_name))
        driver.find_element_by_id("login").send_keys(USERNAME)
        driver.find_element_by_id("password").send_keys(password)
        driver.find_element_by_class_name('btn-primary').click()
        try:
            driver.get("https://{0}.odoo.com/saas_worker/dump".format(db_name))
            sleep(.10)
        except Exception as e:
            logging.error("connection failed to {0} because of {1}".format(db_name, e))
        errors=['Internal Server Error','Forbidden','Not Found']
        if driver.page_source and any([error in driver.page_source for error in errors]):
            cmds ="echo \"ERROR: Kiosk Group SaaS backup\" |mail -s \"Backup Fail Server Error\""+" "+ EMAIL_TO
            try:
                proc = subprocess.Popen(cmds, shell=True, stdout=subprocess.PIPE)
                proc.communicate()
                logging.error("Server Error Occured")
            except subprocess.CalledProcessError:
                logging.error("Mail Failed to send")
            driver.close()
        else:
            self.wait_until_dump_download(file_name)
            self.move_dump_to_backup_directory(file_name,db_name)
            self.delete_old_files()
            driver.close()

    def wait_until_dump_download(self, file_name):
        logging.info("waiting for file {} to downloaded".format(file_name))
        while not path.isfile(file_name):
            sleep(.5)
        sleep(.10)

    def move_dump_to_backup_directory(self,source_path,db_name):
        dest_path = DOWNLOAD_DIR +"/{0}.dump.zip".format(db_name+time.strftime("_%Y_%m_%d_%H:%M:%S"))
        try:
            shutil.move(source_path,dest_path)
            logging.info("{} File downloaded".format(dest_path))
        except exceptions.IOError:
            logging.error("failed to renaming dump {}".format(exceptions))

    def delete_old_files(self):
        files = glob.glob(DOWNLOAD_DIR+"/*.zip")
        files.sort(key=os.path.getmtime, reverse=True)
        [os.remove(file) for file in files[FILES_TO_KEEP:]]
        os.remove('/var/lock/saas-backup.lock')

if not path.isfile('/var/lock/saas-backup.lock'):
    logging.basicConfig(level=logging.INFO,
                        filename='/var/lock/saas-backup.lock',
                        format='%(asctime)s:%(levelname)s:%(message)s')
    DownlodDump().download_dump()
else:
    cmds ="echo \"Previous dump is yet to be downloaded\" |mail -s \"Previous dump is yet to be downloaded\""+" "+ EMAIL_TO
    try:
        proc = subprocess.Popen(cmds, shell=True, stdout=subprocess.PIPE)
        proc.communicate()
        logging.error("Previous dump is yet to be downloaded")
    except subprocess.CalledProcessError:
        logging.error("Previous dump is yet to be downloaded, Mail Failed to send")