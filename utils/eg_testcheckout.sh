#!/bin/sh
echo -n "Is it live or test checkout [live/test]: ";
read checkout;

if [ $checkout = "test" ] || [ $checkout = "live" ]
then
  printf "\nVertebrate branch version is: $www_branch\n";
  printf "Eg branch version is: $eg_branch\n";

  prev_version=`expr $www_branch - 1`;

  for division in metazoa bacteria plants fungi protists;
  do 
    printf "\n\e[1;32m====> Creating $checkout checkout www_$www_branch for $division\e[0m\n";
    cd /nfs/public/release/ensweb/$checkout/$division;
    mkdir www_$www_branch;
    cd www_$www_branch;
    git ensembl --clone web eg-$division;
    git ensembl --checkout --branch release/$www_branch web;
    git ensembl --checkout --branch release/eg/$eg_branch eg-$division;
    git ensembl --clone ensembl-hive --checkout --branch version/2.2;
    git ensembl --clone ensembl-vep --checkout --branch release/$www_branch;

    printf "\n\e[1;32m====> Pulling static content...\e[0m\n";
    perl /nfs/public/release/ensweb/$checkout/$division/eg-web-common/utils/drupal_import_home.pl -d $division -r $eg_branch;

    if [ $division != "bacteria" ]
    then
      perl /nfs/public/release/ensweb/$checkout/$division/eg-web-common/utils/drupal_import_species.pl -d $division
    fi

    printf "\n\e[1;32m====> Building inline C code... \e[0m\n";
    perl /nfs/public/release/ensweb/$checkout/$division/eg-web-common/utils/build_inline_c.pl;
    /nfs/public/release/ensweb/$checkout/$division/ensembl-webcode/ctrl_scripts/build_api_c;

    if [ $division = "bacteria" ]
    then
      printf "\n\e[1;32m====> Generating karyotype images for $division \e[0m\n";
      cp -r /nfs/public/release/ensweb/staging/bacteria/www_$prev_version/eg-web-bacteria/htdocs/img/species eg-web-bacteria/htdocs/img/;
    fi

    printf "\n\e[1;32m====> Copying taxon tree and data from staging location...\e[0m\n";
    sh -c "cp -rv /nfs/public/release/ensweb/staging/$division/server/eg-web-$division/data /nfs/public/release/ensweb/$checkout/$division/www_$www_branch/eg-web-$division/";

    sh -c "cp -rv /nfs/public/release/ensweb/staging/$division/server/eg-web-$division/htdocs/taxon_tree_data.js /nfs/public/release/ensweb/$checkout/$division/www_$www_branch/eg-web-$division/htdocs/";

  done;
  printf "\n\e[1;32m====>  All divisions $checkout done successfully. Dont forget to start the site! \e[0m\n";
else 
  printf "\n\e[1;31m====> !!! wrong checkout, should either be test or live !!!\e[0m\n";
  exit;
fi
