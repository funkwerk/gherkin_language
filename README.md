# Check Language of Gherkin Files

[![Build Status](https://travis-ci.org/funkwerk/gherkin_language.svg)](https://travis-ci.org/funkwerk/gherkin_language)
[![Latest Tag](https://img.shields.io/github/tag/funkwerk/gherkin_language.svg)](https://github.com/funkwerk/gherkin_language)
[![Docker Build](https://img.shields.io/docker/automated/gherkin/language.svg)](https://hub.docker.com/r/gherkin/language/)
[![Docker pulls](https://img.shields.io/docker/pulls/gherkin/language.svg)](https://hub.docker.com/r/gherkin/language/)

This tool analyzes the language of gherkin files and report language errors.
Currently just English is supported.

## Usage

run `gherkin_language` on a list of files

    gherkin_language FEATURE_FILES

`gherkin_language` caches valid sentences. If all sentences are valid, it just needs some time to hash them.

To disable usage of cache, start it with `--no-cache`.

To just extract the sentences, start it with `--sentences`. This could be helpful for using these sentences in another tool. It should not be used for formatting issues. For formatting `gherkin_format --template ...` could be used.

To tag all words used, start it with `--tag`. This allows to build up a glossary based on the feature files provided.

To ignore specific rules, mention them with an `--ignore RULE`. This allows to bypass the checks.

To check for confused words, based on ngrams, add `--ngram`. Please note, that it requires much disk space and time.

By default it will accept unknown words. For warnings about unknown words add `--unknown-words`.

Get a readability report using `--readability`. It indicates, which files are not good readable.

### Usage with Docker

Assuming there is a `test.feature` within the current folder, then the following command will check the feature file.

```
docker run -t -v $(pwd):/user -w /user gherkin/language test.feature
```

For usage of ngrams (be aware, that it will need roughly 10 GB) just use. This will show where very uncommon word combinations are used.

```
docker run -t -v $(pwd):/user -w /user gherkin/language-ngram test.feature
```

## Glossary

It happens that there are words which are unknown to the dictionary.
Once this happens think about if could use another word, that is more common. If there is no such word, add it to the directory-located glossary.
