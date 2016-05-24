#!/usr/bin/env bash

# courtesy of @pivotaljohn

function usage_and_quit() {
   echo "Reset author for specified ref through to HEAD to the current duet pair."
   echo ""
   echo "Usage:"
   echo " $0 (base ref)"
   exit 1
}

function confirm_or_quit() {
  read -p "Are you sure (y/N)? " -n 1 -r; echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborting."
      exit 1
  fi
}

if [ "$1" == "" ]; then
  usage_and_quit
fi

echo "About to reset author to ..."
git duet

echo -e "\nfor these commits..."
echo "----"
git log --graph --decorate --pretty=oneline --abbrev-commit $1..HEAD
echo "----"

echo "WARNING: This command rewrites history.  If you have already pushed to a shared repo (e.g. GitHub)"
echo "         You will have to force push to affect the changes you make (a move that is widely frowned upon)."

confirm_or_quit

git filter-branch --env-filter "$( git duet )" $1..HEAD

echo -e "\n\ngit filter-branch added a ref for you as a backup pointing to the old set of commits."
echo "once you are convinced the right thing happened you can clean-up that ref with:"
echo
echo "$ git update-ref -d (full ref-name here)"

