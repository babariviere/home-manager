#!/usr/bin/env bash

function setupVars() {
    local profilesPath="/nix/var/nix/profiles/per-user/$USER"
    local gcPath="/nix/var/nix/gcroots/per-user/$USER"

    local greatestGenNum
    
    greatestGenNum=$( \
        find "$profilesPath" -name 'home-manager-*-link' \
            | sed 's/^.*-\([0-9]*\)-link$/\1/' \
            | sort -rn \
            | head -1)
    
    if [[ -n $greatestGenNum ]] ; then
        oldGenNum=$greatestGenNum
        newGenNum=$((oldGenNum + 1))
    else
        newGenNum=1
    fi

    genProfilePath="$profilesPath/home-manager"
    newGenPath="@GENERATION_DIR@";
    newGenProfilePath="$profilesPath/home-manager-$newGenNum-link"
    newGenGcPath="$gcPath/current-home"

    local greatestGenNum
    greatestGenNum=$( \
        nix-env --list-generations --profile "$genProfilePath" \
            | tail -1 \
            | sed -E 's/ *([[:digit:]]+) .*/\1/')

    if [[ -n $greatestGenNum ]] ; then
        oldGenNum=$greatestGenNum
        newGenNum=$((oldGenNum + 1))
    else
        newGenNum=1
    fi

    if [[ -e $profilesPath/home-manager ]] ; then
        oldGenPath="$(readlink -e "$profilesPath/home-manager")"
    fi

    $VERBOSE_ECHO "Sanity checking oldGenNum and oldGenPath"
    if [[ -v oldGenNum && ! -v oldGenPath
            || ! -v oldGenNum && -v oldGenPath ]]; then
        errorEcho "Invalid profile number and current profile values! These"
        errorEcho "must be either both empty or both set but are now set to"
        errorEcho "    '${oldGenNum:-}' and '${oldGenPath:-}'"
        errorEcho "If you don't mind losing previous profile generations then"
        errorEcho "the easiest solution is probably to run"
        errorEcho "   rm $profilesPath/home-manager*"
        errorEcho "   rm $gcPath/current-home"
        errorEcho "and trying home-manager switch again. Good luck!"
        exit 1
    fi
}

if [[ -v VERBOSE ]]; then
    export VERBOSE_ECHO=echo
    export VERBOSE_ARG="--verbose"
else
    export VERBOSE_ECHO=true
    export VERBOSE_ARG=""
fi

echo "Starting home manager activation"

# Verify that we can connect to the Nix store and/or daemon. This will
# also create the necessary directories in profiles and gcroots.
$VERBOSE_ECHO "Sanity checking Nix"
nix-build --expr '{}' --no-out-link

setupVars

if [[ -v DRY_RUN ]] ; then
    echo "This is a dry run"
    export DRY_RUN_CMD=echo
else
    $VERBOSE_ECHO "This is a live run"
    export DRY_RUN_CMD=""
fi

if [[ -v VERBOSE ]]; then
    echo -n "Using Nix version: "
    nix-env --version
fi

$VERBOSE_ECHO "Activation variables:"
if [[ -v oldGenNum ]] ; then
    $VERBOSE_ECHO "  oldGenNum=$oldGenNum"
    $VERBOSE_ECHO "  oldGenPath=$oldGenPath"
else
    $VERBOSE_ECHO "  oldGenNum undefined (first run?)"
    $VERBOSE_ECHO "  oldGenPath undefined (first run?)"
fi
$VERBOSE_ECHO "  newGenPath=$newGenPath"
$VERBOSE_ECHO "  newGenProfilePath=$newGenProfilePath"
$VERBOSE_ECHO "  newGenNum=$newGenNum"
$VERBOSE_ECHO "  newGenGcPath=$newGenGcPath"
$VERBOSE_ECHO "  genProfilePath=$genProfilePath"
