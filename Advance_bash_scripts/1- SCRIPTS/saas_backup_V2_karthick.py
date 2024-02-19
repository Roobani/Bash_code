# This script is set to be executed via linux crontab every 1 hour. The delete_after_x_sec is set to 55 minutes. If the dump takes more than 55 min,
# then the script will send an email, clean the lockfile and clean the partially downloaded dump file.

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
import sys
import traceback
# import getpass
DBNAME = 'kioskgroup'
USERNAME = "brice@kioskgroup.com"
PASSWORD = "v8us2hcn2x"
DOWNLOAD_DIR = "/mnt/pve/NFS/kiosk-saas"
CHROMEDRIVER_PATH = "/opt/support_files/scripts/chromedriver"
FILES_TO_KEEP = 3
EMAIL_TO= "john@sodexis.com"
lock_file = '/var/lock/saas-backup.lock'
logger = logging.getLogger(__name__)
delete_after_x_sec = 3300



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
        try:
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
                if path.isfile(lock_file):
                    os.remove(lock_file)
                logging.error("connection failed to {0} because of {1}".format(db_name, e))

            errors=['Internal Server Error','Forbidden','Not Found']
            if driver.page_source and any([error in driver.page_source for error in errors]):
                cmds ='echo "Backup failed due to server error. Check logs." | mail -s "ERROR: Kiosk Group SaaS backup"'.format(EMAIL_TO)
                try:
                    proc = subprocess.Popen(cmds, shell=True, stdout=subprocess.PIPE)
                    proc.communicate()
                    logging.error("Server Error Occured")
                    if path.isfile(lock_file):
                        os.remove(lock_file)
                except subprocess.CalledProcessError:
                    logging.error("Mail Failed to send")
                driver.close()
            else:
                self.wait_until_dump_download(file_name, delete_after_x_sec)
                self.move_dump_to_backup_directory(file_name,db_name)
                self.delete_old_files()
                driver.close()

        except Exception as e:
            cmds ='echo "Error in initial stage" | mail -s "ERROR: Kiosk Group SaaS backup" {}'.format(EMAIL_TO)
            proc = subprocess.Popen(cmds, shell=True, stdout=subprocess.PIPE)
            proc.communicate()
            driver.close()
            if path.isfile(lock_file):
                os.remove(lock_file)
            sys.exit()


    def wait_until_dump_download(self, file_name, sleep_time):
        logging.info("waiting for file {} to downloaded".format(file_name))
        sleeps = 0
        while not path.isfile(file_name):
            if sleeps < sleep_time:
                sleep(60)
                sleeps += 60
            else:
                cmds = 'echo "Backup is taking more than an hour" | mail -s "WARNING: Kiosk Group SaaS backup" {}'.format(EMAIL_TO)
                try:
                    proc = subprocess.Popen(cmds, shell=True, stdout=subprocess.PIPE)
                    proc.communicate()
                    logging.error("take much time to download")
                    if path.isfile(lock_file):
                        os.remove(lock_file)
                    sys.exit()
                except subprocess.CalledProcessError:
                    logging.error("Mail Failed to send")
        sleep(10)

    def move_dump_to_backup_directory(self,source_path,db_name):
        dest_path = DOWNLOAD_DIR +"/{0}.dump.zip".format(db_name+time.strftime("%Y_%m_%d_%H_%M_%S"))
        try:
            shutil.move(source_path,dest_path)
            logging.info("{} File downloaded".format(dest_path))
        except exceptions.IOError:
            logging.error("failed to renaming dump {}".format(exceptions))

    def delete_old_files(self):
        files = glob.glob(DOWNLOAD_DIR+"/*.zip")
        files.sort(key=os.path.getmtime, reverse=True)
        [os.remove(file) for file in files[FILES_TO_KEEP:]]
        if path.isfile(lock_file):
            os.remove(lock_file)

if not path.isfile(lock_file):
    logging.basicConfig(
        level=logging.INFO,
        filename=lock_file,
        format='%(asctime)s:%(levelname)s:%(message)s'
    )
    old_pending_download = False
    for root, dirs, files in os.walk(DOWNLOAD_DIR):
        for file in files:
            if 'crdownload' in file:
                old_pending_download = os.path.join(DOWNLOAD_DIR, file)
    if old_pending_download:
        os.remove(old_pending_download)
    DownlodDump().download_dump()
else:
    cmds = 'echo "Backup is taking more than an hour" | mail -s "WARNING: Kiosk Group SaaS backup" {}'.format(EMAIL_TO)
    try:
        proc = subprocess.Popen(cmds, shell=True, stdout=subprocess.PIPE)
        proc.communicate()
        logging.error("Previous dump is yet to be downloaded")
    except subprocess.CalledProcessError:
        logging.error("Previous dump is yet to be downloaded, Mail Failed to send")
