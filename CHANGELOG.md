## Release 1.4.0 - 2019-03-03

* chore: refactor, update code style
* feat: add `domain` and `account_prefix` arguments to WuParty

## Release 1.3.0 - 2019-03-03

* chore: Use newer version of HTTParty which doesn't need the multipart patch

## Release 1.2.7 - 2017-07-17

* fix: relax requirements for mime-types gem
* fix: fix readme example of filter usage.

## Release 1.2.6 - 2013-10-16

* fix: pin to 1.x version of mime-types

## Release 1.2.5 - 2013-06-24

* feat: add support for the pageStart parameter so users can query multiple pages of wufoo data

## Release 1.2.4 - 2013-04-08

* feat: add option to include system fields to entries and count

## Release 1.2.3 - 2013-03-17

* feat: added the ability to count form entries

## Release 1.2.2 - 2013-01-14

* fix: catch JSON parse error

## Release 1.2.1 - 2012-10-15

* feat: add reader on id to be able to use it from list of forms

## Release 1.2.0 - 2012-10-15

* fix: filter check for Ruby 1.9
* feat: add sorting/limiting functionality

## Release 1.1.2 - 2012-06-06

* chore: add test for webhook
* chore: remove args parameters from `add_webhook` method, and added one argument for each opt param instead
* feat: add `handshakeKey` to `add_webhook` params

## Release 1.1.1 - 2012-05-03

* fix: report method fix

## Release 1.1.0 - 2012-04-22

* feat: add metadata flag to webhook calls
* feat: add Login API support
* feat: add webhook put and delete methods and DRY-up the HTTP verbs
* chore: rename project to WuParty at request of Wufoo company

## Release 1.0.1 - 2010-08-30

* fix: bug in multipart post when no body

## Release 1.0.0 - 2010-08-27

First stable release
