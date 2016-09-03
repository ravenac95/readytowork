#!/bin/bash
EXPECTED_PYTHON_LOCATION='/usr/local/bin/python'
EXPECTED_BREW_LOCATION='/usr/local/bin/brew'

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
DARK_GRAY='\033[1;30m'
NC='\033[0m'

THUMBS_UP='\xf0\x9f\x91\x8d '
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd $CURRENT_DIR/../ && pwd )"

VIRTUALENV_NAME=.venv
VIRTUALENV_DIR=${PROJECT_DIR}/${VIRTUALENV_NAME}
ANSIBLE_PLAYBOOK_BIN=${VIRTUALENV_DIR}/bin/ansible-playbook
PYTHON_BIN=${VIRTUALENV_DIR}/bin/python
PIP_BIN=${VIRTUALENV_DIR}/bin/pip
CURRENT_INDENT=''
CURRENT_INDENT_VALUE=0

read -r -d '' WELCOME_MESSAGE << EOM
${GREEN}Welcome to the machine initialization script!

This script is meant to initialize your Mac OS laptop to be ready to use for
developing software.

It installs some common tools. Namely:
${NC}${PURPLE}
* homebrew
* Google Chrome
* Firefox (It's sometimes good to have both FF and Chrome)
* Slack
* Iterm2
* Python (Installed with homebrew)
    * virtualenv
    * pip
    * ansible
* Docker for Mac
${NC}${GREEN}
This script is 100%% idempotent so it can be run as often as you'd like.
${NC}${DARK_GRAY}
Note:

This will install ansible but only in a python virtualenv. This makes it so
it doesn't interfere with the global ansible. ${NC}

---------------------------------------------------------------------------
EOM

exit_with_error() {
    printf "\n\n${RED}FATAL: $1${NC}\n"
    printf "\n"
    exit 1
}

fix_path() {
    printf "    ${RED}Your PATH environment variable is incorrectly configured${NC}\n\n"
    if [ ! -f $HOME/.bash_profile ]; then
        printf "    ${RED}You do not have a ~/.bash_profile so this script will set one up for you${NC}\n"
        echo 'export PATH=/usr/local/bin:$PATH' >> $HOME/.bash_profile 
    else
        printf "    ${RED}You have a ~/.bash_profile. This script can fix it automatically${NC}\n"
        read -p "    Would you like to continue? [y/N] " -n 1 -r
        printf "\n\n"
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        echo 'export PATH=/usr/local/bin:$PATH' >> $HOME/.bash_profile 
    fi
}

initialize_docker() {
    read -r -d '' DOCKER_INITIALIZTION_MESSAGE << EOM
    ${RED}
    Docker isn't running. If this is the first time you're running this
    script then you will be asked to give your password to Docker.

    Docker will start in five seconds
    ${NC}
EOM
    printf "$DOCKER_INITIALIZTION_MESSAGE"
    sleep 5
    open /Applications/Docker.app
}

check_is_good() {
    printf "${CURRENT_INDENT}${THUMBS_UP}${GREEN} $1${NC}\n"
}

check_is_pending() {
    printf "${CURRENT_INDENT}${YELLOW}- $1${NC}\n"
}

set_indent() {
    if [ $CURRENT_INDENT_VALUE -gt 0 ]; then
        CURRENT_INDENT=$(printf '%0.s ' $(seq 1 $((CURRENT_INDENT_VALUE * 4))))
    else
        CURRENT_INDENT=''
    fi
}

indent() {
    CURRENT_INDENT_VALUE=$((CURRENT_INDENT_VALUE + 1))
    set_indent
}

dedent() {
    CURRENT_INDENT_VALUE=$((CURRENT_INDENT_VALUE - 1))
    set_indent
}

start_stage() {
    indent
    printf "${BLUE}$1${NC}\n"
    echo "---------------------------------------------------------------------------"
    echo
}

end_stage() {
    dedent
    echo
}

run_script_check() {
    # Runs a script. If the check is good it continues. If the check is bad
    # then another command is run to fix. If the check succeed then the
    # `good_message` is shown to the user
    # 
    # Args: script, fix_command, good_message
    eval $1
    if [ $? -eq 1 ]; then
        $2
    else
        check_is_good "$3"
    fi
}

is_installed_check() {
    # Check if a value is the expected value. If not then run a command to fix
    # the issue and respond with a `good_message` once complete. If the issue
    # is fine then respond with the `good_message` to the user
    #
    # Args: expected binary location, command_name, fix_command, application_name
    if [ $1=`which $2` ]; then
        check_is_good "$4 found"
    else
        printf "${CURRENT_INDENT}${YELLOW}- $4 not found. Installing...${NC}\n\n"
        $3
        check_is_good "$4 installed"
    fi
}

install_homebrew() {
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit_with_error "Failed to install brew"
}

install_python_with_brew() {
    brew install python --framework || exit_with_error "Failed to install python with brew"
}

###
# Stages
###
check_basic_setup_stage() {
    start_stage "Checking your basic setup"

    run_script_check "python scripts/check_path_setup.py" fix_path "Your PATH looks good"

    end_stage
}

prereq_install_stage() {
    start_stage "Installing some prerequisite tools"

    is_installed_check $EXPECTED_BREW_LOCATION "brew" install_homebrew "Homebrew"

    is_installed_check $EXPECTED_PYTHON_LOCATION "python" install_python_with_brew "Python (installed with homebrew)"

    # Ensure latest virtualenv and pip
    pip install -U virtualenv pip > /dev/null 2>&1 || exit_with_error "Failed to update virtualenv and pip"

    check_is_good "virtualenv updated"
    check_is_good "pip updated"

    # Create the virtualenv if it isn't available
    if [ ! -f $PYTHON_BIN ]; then
        check_is_pending "virtualenv not found. Creating..."

        echo
        virtualenv ${VIRTUALENV_NAME} --prompt '(readytowork) ' || exit_with_error "Failed to create virtualenv"
        echo

        check_is_good "virtualenv created for local ansible install"
    fi

    $PROJECT_DIR/.venv/bin/pip install -r requirements.txt > /dev/null 2>&1 || exit_with_error "Failed to install requirements.txt for virtualenv"
    check_is_good "ansible installed"

    end_stage
}

ansible_stage() {
    start_stage "Running ansible"

    $ANSIBLE_PLAYBOOK_BIN -i "localhost," setup-box.yml || exit_with_error "Failed to install with ansible"

    end_stage
}

post_ansible_stage() {
    start_stage "Doing some post ansible checks"

    run_script_check "$PYTHON_BIN scripts/check_for_docker.py" initialize_docker "Docker is good to go!"

    end_stage
}


main() {
    printf "$WELCOME_MESSAGE\n\n\n"

    check_basic_setup_stage

    prereq_install_stage

    ansible_stage    

    post_ansible_stage
}

main
