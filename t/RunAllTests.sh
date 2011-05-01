#!/bin/sh

set -e

export HARNESS_PERL_SWITCHES="-MDevel::Cover=+ignore,.t$"
cd ~/fx/t
cover -delete
prove -r --timer .
cover
chmod 775 cover_db
