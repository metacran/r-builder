#! /bin/bash

## This is largely modeled after r-travis, in a CI agnostic fashion
## This also facilites later inclusion into r-travis

set -e
# Comment out this line for quieter output:
set -x

RBUILDER=https://github.com/gaborcsardi/r-builder
CRAN=${CRAN:-"http://cran.rstudio.com"}
BIOC=${BIOC:-"http://bioconductor.org/biocLite.R"}
BIOC_USE_DEVEL=${BIOC_USE_DEVEL:-"TRUE"}
OS=$(uname -s)
BINDIR=$HOME/R-bin

PANDOC_VERSION='1.12.4.2'
PANDOC_DIR="${HOME}/opt"
PANDOC_URL="https://s3.amazonaws.com/rstudio-buildtools/pandoc-${PANDOC_VERSION}.zip"

## Detect CI
if [ "$DRONE" == "true" ]; then
    export CI="drone"
elif [ "$SEMAPHORE" == "true" ]; then
    export CI="semaphore"
elif [ "$TRAVIS" == "true" ]; then
    export CI="travis"
else
    >&2 echo "Unknown CI"
    exit 1
fi

if [ -z "$RVERSION" ]; then
   >&2 echo "RVERSION environment variable is not set, will use R-devel"
   RVERSION=devel
fi

# MacTeX installs in a new $PATH entry, and there's no way to force
# the *parent* shell to source it from here. So we just manually add
# all the entries to a location we already know to be on $PATH.
#
# TODO(craigcitro): Remove this once we can add `/usr/texbin` to the
# root path.
PATH="${BINDIR}/R-${RVERSION}/bin:${PATH}:/usr/texbin"

R_BUILD_ARGS=${R_BUILD_ARGS-"--no-build-vignettes --no-manual"}
R_CHECK_ARGS=${R_CHECK_ARGS-"--no-build-vignettes --no-manual --as-cran"}

R_USE_BIOC_CMDS="source('${BIOC}');"\
" tryCatch(useDevel(${BIOC_USE_DEVEL}),"\
" error=function(e) {if (!grepl('already in use', e$message)) {e}});"\
" options(repos=biocinstallRepos());"

Bootstrap() {
    if [[ "Darwin" == "${OS}" ]]; then
        BootstrapMac
    elif [[ "Linux" == "${OS}" ]]; then
        BootstrapLinux
    else
        >&2 echo "Unknown OS: ${OS}"
        exit 1
    fi

    if ! (test -e .Rbuildignore && grep -q 'travis-tool' .Rbuildignore); then
        echo '^pkg-build\.sh$' >>.Rbuildignore
    fi
}

InstallPandoc() {
    local os_path="$1"
    mkdir -p "${PANDOC_DIR}"
    curl -o /tmp/pandoc-${PANDOC_VERSION}.zip ${PANDOC_URL}
    unzip -j /tmp/pandoc-${PANDOC_VERSION}.zip "pandoc-${PANDOC_VERSION}/${os_path}/pandoc" -d "${PANDOC_DIR}"
    chmod +x "${PANDOC_DIR}/pandoc"
    sudo ln -s "${PANDOC_DIR}/pandoc" /usr/local/bin
}

BootstrapLinux() {
    # Get R from r-builder
    (
	mkdir -p ${BINDIR}
	chown $(id -un):$(id -gn) ${BINDIR}
	cd ${BINDIR}
	if ! curl --fail -s -OL ${RBUILDER}/archive/${CI}-${RVERSION}.zip; then
	    >&2 echo "This R version is not available for this CI"
	    exit 1
	fi
	unzip -q ${CI}-${RVERSION}.zip
	mv r-builder-${CI}-${RVERSION}/R-${RVERSION} .
    )

    # Install an R development environment. qpdf is also needed for
    # --as-cran checks:
    #   https://stat.ethz.ch/pipermail/r-help//2012-September/335676.html
    Retry sudo apt-get -y update -qq
    Retry sudo apt-get -y install --no-install-recommends qpdf gfortran

    # Process options
    BootstrapLinuxOptions
}

BootstrapLinuxOptions() {
    if [[ -n "$BOOTSTRAP_LATEX" ]]; then
        # We add a backports PPA for more recent TeX packages.
        sudo add-apt-repository -y "ppa:texlive-backports/ppa"

        Retry sudo apt-get -y install --no-install-recommends \
            texlive-base texlive-latex-base texlive-generic-recommended \
            texlive-fonts-recommended texlive-fonts-extra \
            texlive-extra-utils texlive-latex-recommended texlive-latex-extra \
            texinfo lmodern
    fi
    if [[ -n "$BOOTSTRAP_PANDOC" ]]; then
        InstallPandoc 'linux/debian/x86_64'
    fi
}

BootstrapMac() {
    >&2 echo "OSX is not currently supported"
    exit 1

    # Install from latest CRAN binary build for OS X
    wget ${CRAN}/bin/macosx/R-latest.pkg  -O /tmp/R-latest.pkg

    >&2 echo "Installing OS X binary package for R"
    sudo installer -pkg "/tmp/R-latest.pkg" -target /
    rm "/tmp/R-latest.pkg"

    # Process options
    BootstrapMacOptions
}

BootstrapMacOptions() {
    if [[ -n "$BOOTSTRAP_LATEX" ]]; then
        # TODO: Install MacTeX.pkg once there's enough disk space
        MACTEX=mactex-basic.pkg
        wget http://ctan.math.utah.edu/ctan/tex-archive/systems/mac/mactex/$MACTEX -O "/tmp/$MACTEX"

        >&2 echo "Installing OS X binary package for MacTeX"
        sudo installer -pkg "/tmp/$MACTEX" -target /
        rm "/tmp/$MACTEX"
        # We need a few more packages than the basic package provides; this
        # post saved me so much pain:
        #   https://stat.ethz.ch/pipermail/r-sig-mac/2010-May/007399.html
        sudo tlmgr update --self
        sudo tlmgr install inconsolata upquote courier courier-scaled helvetic
    fi
    if [[ -n "$BOOTSTRAP_PANDOC" ]]; then
        InstallPandoc 'mac'
    fi
}

EnsureDevtools() {
    if ! Rscript -e 'if (!("devtools" %in% rownames(installed.packages()))) q(status=1)' ; then
        # Install devtools and testthat.
        RInstall devtools testthat
    fi
}

AptGetInstall() {
    if [[ "Linux" != "${OS}" ]]; then
        >&2 echo "Wrong OS: ${OS}"
        exit 1
    fi

    if [[ "" == "$*" ]]; then
        >&2 echo "No arguments to aptget_install"
        exit 1
    fi

    >&2 echo "Installing apt package(s) $@"
    Retry sudo apt-get -y install "$@"
}

DpkgCurlInstall() {
    if [[ "Linux" != "${OS}" ]]; then
        >&2 echo "Wrong OS: ${OS}"
        exit 1
    fi

    if [[ "" == "$*" ]]; then
        >&2 echo "No arguments to dpkgcurl_install"
        exit 1
    fi

    >&2 echo "Installing remote package(s) $@"
    for rf in "$@"; do
        curl -OL ${rf}
        f=$(basename ${rf})
        sudo dpkg -i ${f}
        rm -v ${f}
    done
}

RInstall() {
    if [[ "" == "$*" ]]; then
        >&2 echo "No arguments to r_install"
        exit 1
    fi

    >&2 echo "Installing R package(s): $@"
    Rscript -e 'install.packages(commandArgs(TRUE), repos="'"${CRAN}"'")' "$@"
}

BiocInstall() {
    if [[ "" == "$*" ]]; then
        >&2 echo "No arguments to bioc_install"
        exit 1
    fi

    >&2 echo "Installing R Bioconductor package(s): $@"
    Rscript -e "${R_USE_BIOC_CMDS}"' biocLite(commandArgs(TRUE))' "$@"
}

InstallGithub() {
    EnsureDevtools

    >&2 echo "Installing GitHub packages: $@"
    # Install the package.
    Rscript -e 'library(devtools); library(methods); options(repos=c(CRAN="'"${CRAN}"'")); install_github(commandArgs(TRUE), build_vignettes = FALSE)' "$@"
}

InstallDeps() {
    EnsureDevtools
    Rscript -e 'library(devtools); library(methods); options(repos=c(CRAN="'"${CRAN}"'")); install_deps(dependencies = TRUE)'
}

InstallBiocDeps() {
    EnsureDevtools
    Rscript -e "${R_USE_BIOC_CMDS}"' library(devtools); install_deps(dependencies = TRUE)'
}

DumpSysinfo() {
    >&2 echo "Dumping system information."
    R -e '.libPaths(); options(width = 90) ; devtools::session_info(); installed.packages()'
}

DumpByPattern() {
    if [[ -z "$1" ]]; then
        >&2 echo "dump_by_pattern requires exactly one argument, got: $@"
        exit 1
    fi
    pattern=$1
    shift
    package=$(find . -maxdepth 1 -name "*.Rcheck" -type d)
    if [[ ${#package[@]} -ne 1 ]]; then
        >&2 echo "Could not find package Rcheck directory, skipping dump."
        exit 0
    fi
    for name in $(find "${package}" -type f -name "${pattern}"); do
        echo ">>> Filename: ${name} <<<"
        cat ${name}
    done
}

DumpLogsByExtension() {
    if [[ -z "$1" ]]; then
        >&2 echo "dump_logs_by_extension requires exactly one argument, got: $@"
        exit 1
    fi
    DumpByPattern "*.$1"
}

DumpLogs() {
    echo "Dumping test execution logs."
    DumpLogsByExtension "out"
    DumpLogsByExtension "log"
    DumpLogsByExtension "fail"
}

RunScript() {
    Rscript "$@"
}

RunMake() {
    make "$@"
}

RunBuild() {
    >&2 echo "Building with: R CMD build ${R_BUILD_ARGS}"
    R CMD build ${R_BUILD_ARGS} .
}

RunCheck() {
    # We want to grab the version we just built.
    FILE=$(ls -1t *.tar.gz | head -n 1)

    >&2 echo "Testing with: R CMD check \"${FILE}\" ${R_CHECK_ARGS}"
    _R_CHECK_CRAN_INCOMING_=${_R_CHECK_CRAN_INCOMING_:-FALSE}
    if [[ "$_R_CHECK_CRAN_INCOMING_" == "FALSE" ]]; then
        >&2 echo "(CRAN incoming checks are off)"
    fi
    _R_CHECK_CRAN_INCOMING_=${_R_CHECK_CRAN_INCOMING_} R CMD check "${FILE}" ${R_CHECK_ARGS}

    # Check reverse dependencies
    if [[ -n "$R_CHECK_REVDEP" ]]; then
        >&2 echo "Checking reverse dependencies"
        Rscript -e 'library(devtools); checkOutput <- unlist(revdep_check(as.package(".")$package));if (!is.null(checkOutput)) {print(data.frame(pkg = names(checkOutput), error = checkOutput));for(i in seq_along(checkOutput)){;cat("\n", names(checkOutput)[i], " Check Output:\n  ", paste(readLines(regmatches(checkOutput[i], regexec("/.*\\.out", checkOutput[i]))[[1]]), collapse = "\n  ", sep = ""), "\n", sep = "")};q(status = 1, save = "no")}'
    fi

    # Create binary package (currently Windows only)
    if [[ "${OS:0:5}" == "MINGW" ]]; then
        >&2 echo "Creating binary package"
        R CMD INSTALL --build "${FILE}"
    fi

    if [[ -n "${WARNINGS_ARE_ERRORS}" ]]; then
        if DumpLogsByExtension "00check.log" | grep -q WARNING; then
            >&2 echo "Found warnings, treated as errors."
            >&2 echo "Clear or unset the WARNINGS_ARE_ERRORS environment variable to ignore warnings."
            exit 1
        fi
    fi
}

RunTests() {
    RunBuild
    RunCheck
}

RPath() {
    echo "${BINDIR}/R-${RVERSION}/bin"
}

Retry() {
    if "$@"; then
        return 0
    fi
    for wait_time in 5 20 30 60; do
        >&2 echo "Command failed, retrying in ${wait_time} ..."
        sleep ${wait_time}
        if "$@"; then
            return 0
        fi
    done
    >&2 echo "Failed all retries!"
    return 1
}

COMMAND=$1
>&2 echo "Running command: ${COMMAND}"
shift
case $COMMAND in
    ##
    ## Bootstrap a new core system
    "bootstrap")
        Bootstrap
        ;;
    ##
    ## Ensure devtools is loaded (implicitly called)
    "install_devtools"|"devtools_install")
        EnsureDevtools
        ;;
    ##
    ## Install a binary deb package via apt-get
    "install_aptget"|"aptget_install")
        AptGetInstall "$@"
        ;;
    ##
    ## Install a binary deb package via a curl call and local dpkg -i
    "install_dpkgcurl"|"dpkgcurl_install")
        DpkgCurlInstall "$@"
        ;;
    ##
    ## Install an R dependency from CRAN
    "install_r"|"r_install")
        RInstall "$@"
        ;;
    ##
    ## Install an R dependency from Bioconductor
    "install_bioc"|"bioc_install")
        BiocInstall "$@"
        ;;
    ##
    ## Install a package from github sources (needs devtools)
    "install_github"|"github_package")
        InstallGithub "$@"
        ;;
    ##
    ## Install package dependencies from CRAN (needs devtools)
    "install_deps")
        InstallDeps
        ;;
    ##
    ## Install package dependencies from Bioconductor and CRAN (needs devtools)
    "install_bioc_deps")
        InstallBiocDeps
        ;;
    ##
    ## Build the package, R CMD build
    "run_build")
        RunBuild
        ;;
    ##
    ## Run the actual tests, ie R CMD check
    "run_check")
        RunCheck
        ;;
    ##
    ## First build, then run check
    "run_tests")
        RunTests
        ;;
    ##
    ## Dump information about installed packages
    "dump_sysinfo")
        DumpSysinfo
        ;;
    ##
    ## Dump build or check logs
    "dump_logs")
        DumpLogs
        ;;
    ##
    ## Dump selected build or check logs
    "dump_logs_by_extension")
        DumpLogsByExtension "$@"
        ;;
    ##
    ## Dump selected files by filename pattern
    "dump_by_pattern")
        DumpByPattern "$@"
        ;;

    ##
    ## Run an R script
    "run_script")
	RunScript "$@"
	;;

    ##
    ## Run make
    "make")
	RunMake "$@"
	;;

    ##
    ## Print the R bin path
    "r_path")
	RPath "$@"
	;;
esac
