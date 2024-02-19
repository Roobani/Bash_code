#!/usr/bin/env python

from datetime import date
import subprocess, xmlrpclib, sys, os, psycopg2, pexpect

# Database info
db_user = 'openerp'
db_passwd = 'openerp1234now'
db_host = 'localhost'
db_port = 5432
db_name = 'postgres'
oerp_conf = '/etc/openerp-server.conf'
oerp_bin = "/opt/openerp/server/openerp-server"

today = date.today()
log_date = today.strftime('%Y%m%d')
log_name = "branch-update-{}.log".format(log_date)
base_dir = os.getcwd()

with open(log_name, 'a+') as log_file:
  for branch in ["server", "web", "addons"]:
    # Get revision number
    rev_cmd = ["bzr", "revno", branch]
    try:
      rev_no = subprocess.check_output(rev_cmd, stderr=subprocess.STDOUT).strip()
    except subprocess.CalledProcessError as e:
      print "Error invoking bzr revno: {}".format(e.strerror)
    status = "Pulling latest {} revision (currently {}).".format(branch, rev_no)
    print status
    log_file.write(status + "\n")

    # Update branch
    update_cmd = ["bzr", "pull"]
    try:
      os.chdir(branch)
      status = subprocess.check_output(update_cmd, stderr=subprocess.STDOUT).strip()
    except subprocess.CalledProcessError as e:
      print "Error invoking bzr update: {}".format(e.strerror)
    os.chdir(base_dir)
    print status
    log_file.write(status + "\n")

  # Get list of databases
  db = psycopg2.connect(user=       db_user, 
                        password=   db_passwd,
                        host=       db_host,
                        port=       db_port,
                        database=   db_name)
  cr = db.cursor()
  cr.execute("select datname from pg_database where datdba=(select usesysid from pg_user where usename='{}') order by datname".format(db_user))
  dblist = [str(name) for (name,) in cr.fetchall()]

  for database in dblist:
    # Wait for server to upgrade database, then kill it
    print "Upgrading database {}...".format(database)
    dbupdate_cmd = "{} -c {} --database={} --update=all".format(oerp_bin, oerp_conf, database) 
    output = pexpect.spawn(dbupdate_cmd)
    try:
      output.expect('.*OpenERP server is running, waiting for connections...', timeout=600)
    except pexpect.ExceptionPexpect as e:
      print "Timeout reached while upgrading {}. Try manually upgrading the database with the command '{}'.".format(database, dbupdate_cmd)
    output.kill(0)

    status = "Upgraded database {}.".format(database)
    print status
    log_file.write(status + "\n")