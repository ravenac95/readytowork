# readytowork - A workstation initialization tool

WORK, **Work**, _work_, wooork, werk

This is an attempt to create a tool, much like boxen, but using ansible. This
is similar to battleschool which seems to be abandoned. This is still a work in
progress.

## Goals

* Require only xcode (and if you're willing to host xcode.dmg's this could be
  completely automated for your organization)
* Idempotent (you should be able to run this multiple times)
* Install the following packages:
    * homebrew
    * python (installed with homebrew)
    * nvm
    * Google Chrome
    * Firefox
    * Slack
* Ensures that your `PATH` is configured correctly.

## Usage

```
curl https://github.com/ravenac95/readytowork
```
