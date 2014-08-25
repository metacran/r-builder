#! /bin/bash

set -e
set -x

GetGFortran() {
    curl -O http://cran.rstudio.com/bin/macosx/tools/gfortran-4.2.3.pkg
    sudo installer -pkg gfortran-4.2.3.pkg -target /
}

GetDeps() {
    GetGFortran
    ## TODO: anything else?
}

CreateRD() {
    sudo cat > /usr/local/bin/RD <<EOF
#!/bin/bash

export PATH="/usr/local/lib/R-devel/bin:$PATH"
R "$@"
EOF

    sudo chmod 755 /usr/local/bin/RD
}

GetRecommended() {
    Retry tools/rsync-recommended
}

Configure() {
    mkdir -p $HOME/R/R-devel

    R_PAPERSIZE=letter                              \
    R_BATCHSAVE="--no-save --no-restore"            \
    R_BROWSER=xdg-open                              \
    PAGER=/usr/bin/pager                            \
    PERL=/usr/bin/perl                              \
    R_UNZIPCMD=/usr/bin/unzip                       \
    R_ZIPCMD=/usr/bin/zip                           \
    R_PRINTCMD=/usr/bin/lpr                         \
    LIBnn=lib                                       \
    AWK=/usr/bin/awk                                \
    CC="ccache gcc"                                 \
    CFLAGS="-ggdb -pipe -std=gnu99 -Wall -pedantic" \
    CXX="ccache g++"                                \
    CXXFLAGS="-ggdb -pipe -Wall -pedantic"          \
    FC="ccache gfortran"                            \
    F77="ccache gfortran"                           \
    MAKE="make"                                     \
    ./configure                                     \
    --prefix=$HOME/R/R-devel                        \
    --enable-R-shlib                                \
    --with-blas                                     \
    --with-lapack                                   \
    --with-readline
}

BuildManual() {
    (cd doc/manual && make front-matter html-non-svn)
}

CleanBeforeMake() {
    rm -f non-tarball
}

FixSVN() {
    echo -n 'Revision: ' > SVN-REVISION
    git log --format=%B -n 10   \
	| grep "^git-svn-id"    \
	| head -1               \
	| sed -E 's/^git-svn-id: https:\/\/svn.r-project.org\/R\/[^@]*@([0-9]+).*$/\1/' \
	      >> SVN-REVISION
    echo -n 'Last Changed Date: ' >>  SVN-REVISION
    git log -1 --pretty=format:"%ad" --date=iso | cut -d' ' -f1 >> SVN-REVISION
    cat SVN-REVISION
}

Make() {
    make
}

Test() {
    ## TODO
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

GetDeps
## CreateRD
GetRecommended
Configure
BuildManual
CleanBeforeMake
FixSVN
Make
Test
