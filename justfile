_default:
    @just --list

start: checkout \
    (_start 'aspirecloud') \
    (_start 'aspiresync') \
    (_start 'cve-labeller') \
    (_start 'fair-policy-engine') \
    (_start 'fair-plugin') \
    (_start 'fair-beacon')

# this would be ideal, but we're not there yet
# start repo:
#    cd projects/{{repo}} && just start

_start repo:
    meta/bin/bootstrap-fair-project {{repo}}

checkout: \
    (_checkout 'aspirecloud') \
    (_checkout 'aspirepress/aspiresync') \
    (_checkout 'cve-labeller') \
    (_checkout 'fair-policy-engine') \
    (_checkout 'fair-plugin') \
    (_checkout 'fair-beacon')

_checkout repo:
    meta/bin/checkout-fair-project {{repo}}

# So you can type `just start here` :)
# Later I might make this print status information or something....
[private]
@here:
    true
