#!/bin/bash

# JFYI
#.kitchen.yml uses ruby syntax.
# For Bionic

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
    echo "'docker image list -a'"
    echo "'docker container list -a'"
    echo 
    echo "You can run various kitchen tests cases:"
    echo "'bundle exec kitchen list'"
    echo "'bundle exec make kitchen --concurrency=2'"
    echo "'bundle exec kitchen converge --concurrency=2 control-single-ocata-xenial-20177'" # Run concrete 
    echo
    echo "Connect to conteiner"
    echo "docker exec -it c3bbaca72bed /bin/bash"
    echo
    echo "Run Salt state inside container"
    echo "salt-call --local --file-root /tmp/kitchen/srv/salt --pillar-root /tmp/kitchen/srv/pillar state.apply nginx"
}

make_tuning(){
    sudo usermod -aG docker $USER
}

install_packags() {
    sudo apt update
    sudo apt install -y make python python-pip python-virtualenv ruby-bundler build-essential ruby-all-dev docker.io
    pip install PyYAML
    make_tuning
}

sefl_kitchen_test(){
    bundle exec make test
    bundle exec make clean
    bundle exec kitchen list
    touch ./kitchen-setup-complete-flag
    show_actions
}

setup_kitchen(){
    
#    [ ! -f ./.kitchen.yml ] && log_err "kitchen.yml not found" && return 1
    [ -f ./kitchen-setup-complete-flag ] && log_info "Setup has been complete" && return 0

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
    sefl_kitchen_test
}

## Main
trap _atexit INT TERM EXIT

case $1 in
    selftest)
        sefl_kitchen_test
        ;;
    help)
        show_actions
        ;;
    *)
        install_packags
        setup_kitchen
        ;;
esac

