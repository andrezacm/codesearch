codesearch
==========

Use GitHub Code Search API to search for a query string. Saves user information associated with each repository returned on the code search results list. 

###Usage

`$ ruby script.rb [query_string]`

e.g.

`$ ruby script.rb AndroidManifest.xml`

### Change log

[0.1.2] Major refactoring. Previous command line options are no longer functional.

###Requirements

* Ruby >= 1.9.2
* Gems (`gem install`):
  * httparty
  * launchy
  * awesome_print
