#! /bin/bash
#
# This script checks if all added, copied, modified or renamed files are valid against the PSR2 coding standards
# and if there are no php, javascript or css errors
# dependencies:
#   codesniffer (http://pear.php.net/package/PHP_CodeSniffer)
#   esvalidate (https://github.com/duereg/esvalidate)
#   CSS lint (https://github.com/stubbornella/csslint/wiki/Command-line-interface)
#   SCSS lint (https://github.com/causes/scss-lint)
#
# @version  1.1.0
# @author   Wouter Sioen <wouter.sioen@wijs.be>

# create empty errors array
declare -a errors

# Check if we're on a semi-secret empty tree
if git rev-parse --verify HEAD
then
    against=HEAD
else
    # Initial commit: diff against an empty tree object
    against=90f63925bf91636231179e2c3b4cb3744e47d43e
fi

# fetch all changed php files and validate them
files=$(git diff-index --name-only --diff-filter=ACMR $against | grep '\.php$')
if [ -n "$files" ]; then

    echo 'Checking PHP Files'
    echo '------------------'
    echo

    for file in $files; do

        # first check if they are valid php files
        output=`php -l $file | grep 'Errors parsing'`

        # if it did contain errors, we have output
        if [ -n "$output" ]; then
            echo "$file contains php syntax errors"
            errors=("${errors[@]}" "$output")
        fi

        # checks if the phpcs output contains '| ERROR |'
        output=`vendor/bin/phpcs --standard=PSR2 --extensions=php --encoding=utf8 --report=full $file | grep '| ERROR |'`

        # if it did contain errors, we have output
        if [ -n "$output" ]; then
            echo "$file fails coding standards"
            phpcs --standard=PSR2 --extensions=php --encoding=utf8 --report=full $file
            errors=("${errors[@]}" "$output")
        fi
    done
fi

# fetch all changed php files and validate them
files=$(git diff-index --name-only --diff-filter=ACMR $against | grep '\.php$')
if [ -n "$files" ]; then

    echo 'Checking PHP Files with PHPMD'
    echo '-----------------------------'
    echo

    for file in $files; do

        # first check if they are valid php files
        output=`php -l $file | grep 'Errors parsing'`

        # if it did contain errors, we have output
        if [ -n "$output" ]; then
            echo "$file contains php syntax errors"
            errors=("${errors[@]}" "$output")
        fi

        # checks if the phpcs output contains '| ERROR |'
        output=`vendor/bin/phpmd $file text phpmd-rule.xml`

        # if it did contain errors, we have output
        if [ -n "$output" ]; then
            echo "$file fails php mess detection"
            phpmd $file text phpmd-rule.xml
            errors=("${errors[@]}" "$output")
        fi
    done
fi



# fetch all changed js files and validate them
files=$(git diff-index --name-only --diff-filter=ACMR $against | grep '\.js$')
if [ -n "$files" ]; then

    echo
    echo 'Checking Javascript Files'
    echo '------------------'
    echo

    for file in $files; do
        output=`./node_modules/.bin/eslint $file --format stylish`

        # if our output is not empty, there were errors
        if [ -n "$output" ]; then
            echo "$file contains javascript syntax errors"
            echo "$output"
            errors=("${errors[@]}" "$output")
        fi
    done
fi

# fetch all changed css files and validate them
files=$(git diff-index --name-only --diff-filter=ACMR $against | grep '\.css$')
if [ -n "$files" ]; then

    echo
    echo 'Checking CSS Files'
    echo '------------------'
    echo

    for file in $files; do
        output=`node_modules/csslint/dist/cli.js --format=compact $file | grep 'Error -'`

        # if our output is not empty, there were errors
        if [ -n "$output" ]; then
            echo "$file contains css syntax errors"
            echo $output
            errors=("${errors[@]}" "$output")
        fi
    done
fi

# fetch all changed css files and validate them
files=$(git diff-index --name-only --diff-filter=ACMR $against | grep -E '\.s(c|a)ss$')
if [ -n "$files" ]; then

    echo
    echo 'Checking SCSS Files'
    echo '------------------'
    echo

    for file in $files; do
        output=`node_modules/sass-lint/bin/sass-lint.js $file | grep '\[E\]'`

        # if our output is not empty, there were errors
        if [ -n "$output" ]; then
            echo "$file contains scss syntax errors"
            scss-lint $file | grep '\[E\]'
            errors=("${errors[@]}" "$output")
        fi
    done
fi

#run unit tests
output=`vendor/bin/phpunit --bootstrap=vendor/autoload.php src/Tests | grep 'failures'`
if [ -n "$output" ]; then
     echo "Unit tests failed. $output"
     errors=("${errors[@]}" "$output")
fi

# if we have errors, exit with 1
if [ -n "$errors" ]; then
    exit 1
fi

echo '🍺  No errors found!'
