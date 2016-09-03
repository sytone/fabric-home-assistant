########################################
# Fabfile to:
#    - deploy supporting HA components
#    - deploy HA
########################################

# Import Fabric's API module
from fabric.api import *
import fabric.contrib.files
import time
import os
from string import Template



env.hosts = ['localhost']
env.user   = "pi"
env.password = "raspberry"
env.warn_only = True
pi_hardware = os.uname()[4]

#######################
## Core server setup ##
#######################

def install_start():
    """ Notify of install start """
    print("""
    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,,,,,,,,,,, ,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,,,,,,,,,,   ,,,,,,,,,,,,,,,,,,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,,,,,,,,,     ,,,,,,,,,,,,,,,,,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,,,,,,,,       ,,,,,,,,,,,,,,,,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,,,,,,,         ,,,,,,,,,,,,,,,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,,,,,,           ,,,,,,,,,,,,,,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,,,,,             ,,,,,,,,,,,,,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,,,,               ,,,,,,,,,,,,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,,,       ,,,,,     ,,,,,,,,,,,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,,       ,,,,,,,     ,,,,,,,,,,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,       ,,,,,,,,,     ,,,     ,,,,,,,,,,
    ,,,,,,,,,,,,,,,,        ,,,   ,,,      ,,     ,,,,,,,,,,
    ,,,,,,,,,,,,,,,         ,,,   ,,,       ,     ,,,,,,,,,,
    ,,,,,,,,,,,,,,          ,,,   ,,,             ,,,,,,,,,,
    ,,,,,,,,,,,,,            ,,,,,,,              ,,,,,,,,,,
    ,,,,,,,,,,,,              ,,,,,               ,,,,,,,,,,
    ,,,,,,,,,,,                ,,,                ,,,,,,,,,,
    ,,,,,,,,,,                 ,,,                 ,,,,,,,,,
    ,,,,,,,,,        ,,,       ,,,       ,,,        ,,,,,,,,
    ,,,,,,,,       ,,,,,,,     ,,,     ,,,,,,,       ,,,,,,,
    ,,,,,,,       ,,,,,,,,,    ,,,    ,,,,,,,,,       ,,,,,,
    ,,,,,,        ,,,   ,,,    ,,,    ,,,   ,,,        ,,,,,
    ,,,,,         ,,,   ,,,    ,,,    ,,,   ,,,         ,,,,
    ,,,,,,,,,,,   ,,,   ,,,    ,,,    ,,,   ,,,   ,,,,,,,,,,
    ,,,,,,,,,,,    ,,,,,,,,    ,,,    ,,,,,,,,    ,,,,,,,,,,
    ,,,,,,,,,,,      ,,,,,,    ,,,    ,,,,,,      ,,,,,,,,,,
    ,,,,,,,,,,,        ,,,,,   ,,,   ,,,,,        ,,,,,,,,,,
    ,,,,,,,,,,,          ,,,, ,,,, ,,,,,          ,,,,,,,,,,
    ,,,,,,,,,,,           ,,,, ,,, ,,,,           ,,,,,,,,,,
    ,,,,,,,,,,,            ,,,,,,,,,,,            ,,,,,,,,,,
    ,,,,,,,,,,,             ,,,,,,,,,             ,,,,,,,,,,
    ,,,,,,,,,,,              ,,,,,,,              ,,,,,,,,,,
    ,,,,,,,,,,,               ,,,,,               ,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    ,,,,,,,,,,,                                   ,,,,,,,,,,
    ,,,,,,,,,,,   Welcome to the Home Assistant   ,,,,,,,,,,
    ,,,,,,,,,,,    DietPi All-In-One Installer    ,,,,,,,,,,
    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    """)
    print("* Warning *")
    print("""The primary use of this installer is for a new, unconfigured Home Assistant deployment. 
          Running the installer command straight from the Getting Started guide found on Github, will overwrite any existing configs.
          Additional commands for upgrading should be run seperately. Please see the Github page for useage instructions""")
    time.sleep(10)
    print("Installer is starting...")
    print("Your device will reboot when the installer is complete.")
    time.sleep(5)



def update_upgrade():
    """ Update OS """
    sudo("apt-get update")
    sudo("apt-get upgrade -y")

def setup_users(openzwave='no', mosquitto='no'):
    """ Create service users, etc """
    sudo("useradd --system hass")
    sudo("usermod -d /home/hass hass")
    if mosquitto == 'yes':
        sudo("useradd mosquitto")
    if openzwave == 'yes':
        sudo("usermod -G dialout -a hass")
    
def setup_dirs(mosquitto='no'):
    """ Create all needed directories and change ownership """
    with cd("/srv"):
        sudo("mkdir hass")
        sudo("chown hass hass")
        with cd("hass"):
            sudo("mkdir -p src")
            sudo("chown hass:hass src")
    with cd("/home"):
        sudo("mkdir -p hass")
        sudo("mkdir -p /home/hass/.homeassistant")
        sudo("chown hass:hass hass")
    with cd ("/tmp"):
        sudo("mkdir -p hassinstall")
        sudo("chmod 777 .")
    if mosquitto == 'yes':
        with cd ("/var/run/"):
            sudo("touch mosquitto.pid")
            sudo("chown mosquitto:mosquitto mosquitto.pid")
        with cd ("/var/lib/"):
            sudo("mkdir mosquitto")
            sudo("chown mosquitto:mosquitto mosquitto")

def install_syscore():
    """ Download and install Host Dependencies. """
    sudo("aptitude install -y python3")
    sudo("aptitude install -y python3-pip")
    sudo("aptitude install -y git")
    sudo("aptitude install -y libssl-dev")
    sudo("aptitude install -y cmake")
    sudo("aptitude install -y libc-ares-dev")
    sudo("aptitude install -y uuid-dev")
    sudo("aptitude install -y daemon")
    sudo("aptitude install -y curl")
    sudo("aptitude install -y libgnutls28-dev")
    sudo("aptitude install -y libgnutlsxx28")
    sudo("aptitude install -y libgnutls-dev")
    sudo("aptitude install -y nmap")
    sudo("aptitude install -y net-tools")
    sudo("aptitude install -y sudo")
    sudo("aptitude install -y libglib2.0-dev")
    sudo("aptitude install -y cython3")
    sudo("aptitude install -y libudev-dev")
    sudo("aptitude install -y python3-sphinx")
    sudo("aptitude install -y python3-setuptools")

def install_pycore():
    """ Download and install VirtualEnv """
    sudo("pip3 install virtualenv")

def create_venv():
    """ Create home-assistant VirtualEnv """
    with cd("/srv/hass"):
            sudo("virtualenv -p python3 hass_venv", user="hass")

def setup_mosquitto(mosusername='pi',mospassword='raspberry'):
    """ Build and Install Mosquitto """
    with cd("/tmp"):
        sudo("curl -O https://libwebsockets.org/git/libwebsockets/snapshot/libwebsockets-1.4-chrome43-firefox-36.tar.gz")
        sudo("tar xvf libwebsockets*")
        with cd("libwebsockets*"):
            sudo("mkdir build")
            with cd("build"):
                sudo("cmake ..")
                sudo("make install")
                sudo("ldconfig")
                with cd("/srv/hass/src"):
                    sudo("wget http://mosquitto.org/files/source/mosquitto-1.4.9.tar.gz")
                    sudo("tar zxvf mosquitto-1.4.9.tar.gz")
                    with cd("mosquitto-1.4.9"):
                        sudo("sed -i 's/WITH_WEBSOCKETS:=no.*/WITH_WEBSOCKETS:=yes/' /srv/hass/src/mosquitto-1.4.9/config.mk")
                        sudo("make")
                        sudo("make install")
                        with cd("/etc/mosquitto"):
                            fabric.contrib.files.upload_template('mosquitto.conf.template', '/etc/mosquitto/mosquitto.conf', use_sudo=True)                            
                            sudo("touch pwfile")
                            sudo("chown mosquitto: pwfile")
                            sudo("chmod 0600 pwfile")
                            sudo("sudo mosquitto_passwd -b pwfile %s %s" % (mosusername,mospassword))
    # Setup the service and start it. 
    fabric.contrib.files.upload_template('mosquitto.service.template', '/etc/systemd/system/mosquitto.service', use_sudo=True)                            
    sudo("systemctl enable mosquitto.service")
    sudo("systemctl daemon-reload")
                            
def setup_homeassistant(virtual='no'):
    """ Install Home-Assistant """
    if virtual == 'no':
        sudo("pip3 install homeassistant", user="hass")
    else:
        sudo("source /srv/hass/hass_venv/bin/activate && pip3 install homeassistant", user="hass")
        with cd("/home/hass/"):
            sudo("chown -R hass:hass /home/hass/")

def setup_openzwave(virtual='no'):
    """ Install python-openzwave """
    if virtual == 'no':
        sudo("pip3 install --upgrade cython", user="hass")
        with cd("/srv/hass/src"):
            sudo("git clone https://github.com/OpenZWave/python-openzwave.git", user="hass")
            with cd("python-openzwave"):
                sudo("git checkout python3", user="hass")
                sudo("make build", user="hass")
                sudo("make install", user="hass")
    else:
        sudo("source /srv/hass/hass_venv/bin/activate && pip3 install --upgrade cython", user="hass")
        with cd("/srv/hass/src"):
            sudo("git clone --branch v0.3.1 https://github.com/OpenZWave/python-openzwave.git", user="hass")
            with cd("python-openzwave"):
                sudo("git checkout python3", user="hass")
                sudo("source /srv/hass/hass_venv/bin/activate && make build", user="hass")
                sudo("source /srv/hass/hass_venv/bin/activate && make install", user="hass")

def setup_libmicrohttpd():
    """ Build and install libmicrohttpd """
    with cd("/srv/hass/src"):
        sudo("mkdir libmicrohttpd")
        sudo("chown hass:hass libmicrohttpd")
        sudo("wget ftp://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-0.9.19.tar.gz", user="hass")
        sudo("tar zxvf libmicrohttpd-0.9.19.tar.gz")
        with cd("libmicrohttpd-0.9.19"):
            sudo("./configure")
            sudo("make")
            sudo("make install")

def setup_openzwave_controlpanel():
    """ Build and Install open-zwave-control-panel """
    with cd("/srv/hass/src"):
        sudo("git clone https://github.com/OpenZWave/open-zwave-control-panel.git", user="hass")
        with cd("open-zwave-control-panel"):
            fabric.contrib.files.upload_template('Makefile.template', 'Makefile', use_sudo=True)
            sudo("make")
            if pi_hardware == "armv7l":
                sudo("ln -sd /srv/hass/hass_venv/lib/python3.4/site-packages/libopenzwave-0.3.1-py3.4-linux-armv7l.egg/config")
            else:
                sudo("ln -sd /srv/hass/hass_venv/lib/python3.4/site-packages/libopenzwave-0.3.1-py3.4-linux-armv**6**l.egg/config")
        sudo("chown -R hass:hass /srv/hass/src/open-zwave-control-panel")

def update_homeassistant_config(mosusername='pi',mospassword='raspberry'):
    """ Enable applications to start at boot via systemd """
    hacfg="""
mqtt:
  broker: 127.0.0.1
  port: 1883
  client_id: home-assistant-1
  username: $mosusername
  password: $mospassword
"""
    s = Template(hacfg)
    fabric.contrib.files.append("/home/hass/.homeassistant/configuration.yaml", s.substitute(mosusername=mosusername, mospassword=mospassword), use_sudo=True)

def upgrade_homeassistant():
    """ Activate Venv, and upgrade Home Assistant to latest version """
    sudo("source /srv/hass/hass_venv/bin/activate && pip3 install homeassistant --upgrade", user="hass")


def create_homeassistant_service(virtual='no'):
    if virtual == 'yes':
        fabric.contrib.files.upload_template('home-assistant.service.template', '/etc/systemd/system/home-assistant.service', {'hasspath': '/srv/hass/hass_venv/bin/hass'}, use_sudo=True)
        with settings(sudo_user='hass'):
            sudo("/srv/hass/hass_venv/bin/hass --script ensure_config --config /home/hass/.homeassistant")
    else:
        fabric.contrib.files.upload_template('home-assistant.service.template', '/etc/systemd/system/home-assistant.service', {'hasspath': '/usr/local/bin/hass'}, use_sudo=True)
        with settings(sudo_user='hass'):
            sudo("/usr/local/bin/hass --script ensure_config --config /home/hass/.homeassistant")
    sudo("systemctl enable home-assistant.service")
    sudo("systemctl daemon-reload")


#############
## Deploy! ##
#############

def deploy(virtual='no', openzwave='no', mosquitto='no',username='pi',password='raspberry',mosusername='pi',mospassword='raspberry'):

    env.user = username
    env.password = password

    ## Install Start ##
    install_start()

    ## Initial Update and Upgrade ##
    update_upgrade()

    ## Setup service accounts ##
    setup_users(openzwave, mosquitto)

    ## Setup directories ##
    setup_dirs(mosquitto)

    ## Install dependencies ##
    install_syscore()
    
    if virtual == 'yes':
        ## Install VirtualEnv ##
        install_pycore()
        ## Create VirtualEnv ##
        create_venv()

    if mosquitto == 'yes':
        ## Build and Install Mosquitto ##
        setup_mosquitto(mosusername,mospassword)

    ## Activate, install Home-Assistant ##
    update_homeassistant_config(mosusername,mospassword)
    create_homeassistant_service(virtual)
    
    if openzwave == 'yes':
        ## Activate venv, build and install python-openzwave ##
        setup_openzwave(virtual)
    
        ## Build and install libmicrohttpd ##
        setup_libmicrohttpd()
    
        ## Build and install open-zwave-control-panel ##
        setup_openzwave_controlpanel()

    ## Reboot the system ##
    reboot()


