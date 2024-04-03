if test ! $(which psql)
then
  echo "› Linking libpq"
  brew link --force libpq
else
  echo "› libpq already linked"
fi
