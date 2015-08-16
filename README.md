
# R+CI

Check your R package with multiple versions of R, including R-devel, on Travis or Semaphore.

## CIs

The currently supported CIs are:
* [Travis CI](http://travis-ci.org)
* [Semaphore](http://semaphoreapp.com)

## Available R versions

Currently supported R versions:
* R-devel, built hourly.
* R-release, refers to the current stable release
* R-oldrel, refers to last release from the previous minor version
* R 3.2.2
* R 3.2.1
* R 3.2.0
* R 3.1.3
* R 3.1.2
* R 3.1.1
* R 3.1.0
* R 3.0.3

We recommend that you test your package with `R-devel`, `R-release` and `R-oldrel`.
CRAN maintainers run their tests on these versions as well.

## Status for R-devel builds

[![Travis](https://travis-ci.org/metacran/r-builder.png?branch=travis-devel)](https://travis-ci.org/metacran/r-builder)
[![Semaphore](https://semaphoreapp.com/api/v1/projects/414ed80e-64af-46fc-8d50-2c6371e4adca/281321/badge.png)](https://semaphoreapp.com/gaborcsardi/r-builder)

# How to use r-builder with your package

## Travis CI

1. Sign up to [Travis](https://travis-ci.org), if you haven't already.
2. Enable Travis for your project.
3. Copy the `sample.travis.yml` file in the root of your repository as `.travis.yml`.
4. Edit this file according to your needs. In particular, if your R package
   depends on R packages that are not on CRAN, but on github, you need to tell Travis
   to install them. Change the `.travis.yml` file like this:
   
    ```yaml
    install:
      - ./pkg-build.sh install_github repo1/pkg1 repo2/pkg2 ... etc
      - ./pkg-build.sh install_deps
    ```

5. To make R and `devtools::install_github` ignore this file, put this in your
   `.Rbuildignore` file (you may need to create this file):

    ```
    ^.travis\..yml$
    ```

6. Push your repo to start building and checking.
7. (Optional) Add a badge as described in http://docs.travis-ci.com/user/status-images/
   to your README.md.

See also the [extensive Travis documentation](http://docs.travis-ci.com/).

## Semaphore CI

[Semaphore](http://semaphoreapp.com) does not use a file from the repo for
configuration. Instead, you need to set up everything in the web interface.
So the steps you need are

1. Sign up to [Semaphore](http://semaphoreapp.com).
2. Enable Semaphore for your project, and your branch.
3. Use the Ubuntu 14.04 LTS v1410.1 platform.
4. Set the `RVERSION` environment variable to the R version you want
   to build/test against. E.g. `3.1.2` builds with R 3.1.2 and `devel` uses
   R-devel.
5. You need to use the following build commands:

    ```sh
    curl -OL https://raw.githubusercontent.com/gaborcsardi/r-builder/master/pkg-build.sh
    chmod 755 pkg-build.sh
    ./pkg-build.sh bootstrap
    ./pkg-build.sh install_deps
    ./pkg-build.sh run_tests
    ```

   The first two lines can be run in the `Setup` phase, and the rest on
   `Thread#1`, although this might not be strictly necessary.
   
6. Modify these lines if you need to install R packages that are not on
    CRAN. E.g. before `install_deps` you can add

    ```sh
	./pkg-build install_github repo1/pkg1 repo2/pkg2 ... etc
	```

7. Push you repo to start building, or you can also start a build on the
    Semaphore web interface.
8. (Optional) Add a badge as described in the “Badge” section in “Settings”
   for your project.

See also the [Semaphore docs](https://semaphoreapp.com/docs/) for more details.

## Plans

Please see the [issue tracker](https://github.com/metacran/r-builder/issues).
