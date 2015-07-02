Check Langauge of Gherkin Files
===============================

[![Build Status](https://travis-ci.org/funkwerk/gherkin_language.svg)](https://travis-ci.org/funkwerk/gherkin_language)

This tool analyzes the language of gherkin files and report language errors.
Currently just English is supported.

Usage
-----

run `gherkin_language` on a list of files

    gherkin_language FEATURE_FILES

`gherkin_language` caches valid sentences. If all sentences are valid, it just needs some time to hash them.

To disable usage of cache, start it with `--no-cache`.

To just extract the sentences, start it with `--sentences`. This could be helpful for using these sentences in another tool. It should not be used for formatting issues. For formatting `gherkin_format --template ...` could be used.

To tag all words used, start it with `--tag`. This allows to build up a glossary based on the feature files provided.


Glossary
--------

It happens that there are words which are unknown to the dictionary.
Once this happens think about if could use another word, that is more common. If there is no such word, add it to the directory-located glossary.
