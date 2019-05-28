#!/bin/bash

# JFYI
#.kitchen.yml uses ruby syntax.
# For Bionic

set -e
[ -n "$DEBUG" ] && set -x

log_info() {
    echo "[INFO] $*"
}

log_err() {
    echo "[ERROR] $*" >&2
}

_atexit() {
    RETVAL=$?
    trap true INT TERM EXIT

    if [ $RETVAL -ne 0 ]; then
        log_err "Execution failed"
    else
        log_info "Execution successful"
    fi
    return $RETVAL
}

show_actions() {
    echo
    echo "You can view container/image:"
    echo "docker image list -a"
    echo "docker container list -a"
    echo 
    echo "You can run various kitchen tests cases:"
    echo "bundle exec kitchen list"
    echo "bundle exec make kitchen"
    echo "bundle exec kitchen converge control-single-ocata-xenial-20177" # Run concrete Instance
    echo
    echo "Connect to conteiner"
    echo "docker exec -it c3bbaca72bed /bin/bash"
    echo
    echo "Run Salt state inside container"
    echo "salt-call --local --file-root /tmp/kitchen/srv/salt --pillar-root /tmp/kitchen/srv/pillar state.apply nginx"
    echo
}

make_adjustment(){
    sudo usermod -aG docker $USER
    newgrp docker
}

install_packages() {
    sudo apt update
    sudo apt install -y make python python-pip python-virtualenv ruby-bundler build-essential ruby-all-dev docker.io
    pip install PyYAML
}

self_kitchen_tests(){
    bundle exec make test
    bundle exec make clean
    clear
    bundle exec kitchen list && touch ./virtualenv/kitchen-setup-complete-flag
    show_actions
}

setup_kitchen(){

    clear

    [ -f ./.kitchen.yml ] || (log_err "kitchen.yml not found"; exit 1)
    if [ -f ./virtualenv/kitchen-setup-complete-flag ]; then
	log_info "Setup has been complete"
	show_actions
	return 0
    fi

    cat << EOF > ./Gemfile
source 'https://rubygems.org'
gem 'rake'
gem 'test-kitchen'
gem 'kitchen-docker'
gem 'kitchen-inspec'
gem 'inspec'
gem 'kitchen-salt', :git => 'https://github.com/salt-formulas/kitchen-salt.git'
EOF

    mkdir -p ./virtualenv
    bundle install --path ./virtualenv/
    
    cp .kitchen.yml .kitchen.openstack.yml
    self_kitchen_tests
    make_adjustment
}

## Main
trap _atexit INT TERM EXIT

case $1 in
    selftest)
        self_kitchen_tests
        ;;
    help)
        show_actions
        ;;
    *)
        install_packages
        setup_kitchen
        ;;
esac

