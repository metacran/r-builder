#! /bin/bash

set -e
set -x

export PATH=/usr/local/bin:$PATH
export CRAN=cran.rstudio.com
export OS=linux
export roptions=""
if uname -a | grep -q Darwin; then
    export OS=osx
    roptions=--with-tcl-config=/usr/local/opt/tcl-tk/lib/tclConfig.sh \
	    --with-tk-config=/usr/local/opt/tcl-tk/lib/tkConfig.sh \
	    ${roptions}
fi

GetGFortran() {
    curl -O http://cran.rstudio.com/bin/macosx/tools/gfortran-4.2.3.pkg
    sudo installer -pkg gfortran-4.2.3.pkg -target /
}

GetDeps() {
    if [ $OS == "osx" ]; then
	GetGFortran
    elif [ $OS == "linux" ]; then
	Retry sudo apt-get -y build-dep r-base
	Retry sudo apt-get -y install subversion ccache texlive \
	      texlive-fonts-extra texlive-latex-extra
    fi
}

GetSource() {
    rm -rf R-${version} R-${version}.tar.gz
    major=$(echo $version | sed 's/\..*$//')
    url="http://${CRAN}/src/base/R-${major}/R-${version}.tar.gz"
    curl -O "$url"
    tar xzf "R-${version}.tar.gz"
    cd R-${version}
}

GetDevelSource() {
    # TODO
    true
}

GetRecommended() {
    Retry tools/rsync-recommended
}

Configure() {
    sudo mkdir -p /opt/R/R-${version}

    R_PAPERSIZE=letter                                       \
    R_BATCHSAVE="--no-save --no-restore"                     \
    PERL=/usr/bin/perl                                       \
    R_UNZIPCMD=/usr/bin/unzip                                \
    R_ZIPCMD=/usr/bin/zip                                    \
    R_PRINTCMD=/usr/bin/lpr                                  \
    AWK=/usr/bin/awk                                         \
    CFLAGS="-std=gnu99 -Wall -pedantic"                      \
    CXXFLAGS="-Wall -pedantic"                               \
    ./configure                                              \
    --prefix=/opt/R/R-${version}
    ${roptions}
}

Make() {
    make
}

Install() {
    make install
}

Release() {
    # Do nothing for now
    true
}

Retry() {
    if "$@"; then
        return 0
    fi
    for wait_time in 5 20 30 60; do
        echo "Command failed, retrying in ${wait_time} ..."
        sleep ${wait_time}
        if "$@"; then
            return 0
        fi
    done
    echo "Failed all retries!"
    exit 1
}

BuildVersion() {
    GetDeps
    GetSource
    Configure
    Make
    Install
    Release
}

BuildDevel() {
    GetDevelSource
    GetRecommended
    Configure
    Make
    Install
    Release
}

if [ "$version" == "devel" ]; then
    BuildDevel
elif [ "$version" == "" ]; then
    echo 'version is not set, doing nothing'
    exit 0
else
    BuildVersion
fi
