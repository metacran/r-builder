
# Binary R builds for CI testing (work in progress!)

This project provides binary R distributions to be used with various CI
service. Currently supported are
* [Travis CI](http://travis-ci.org)
* [Semaphore](http://semaphoreapp.com)

More will be probably added later.

## Available R versions

The most current list of R builds is available from the
[list of releases](https://github.com/metacran/r-builder/releases).

## How to use r-builder with your CI

I am planning to contribute r-builder suport to
[r-travis](https://github.com/craigcitro/r-travis), which will
mean that you will be able to use r-travis with various R versions.
(This is conditional on the acceptance of my contribution, obviously.)

In the meanwhile, you can use the build script from the
r-builder repository. This is less sophisticated than r-travis,
but supports multiple CIs as well.

The build script is under development, more soon.

## Plans

Please see the [issue tracker](https://github.com/metacran/r-builder/issues).
