for D in `find . -maxdepth 1 -mindepth 1 -type d`; do
    cd ${D}
    if [ -d .git ]; then
      echo "checking ${D}"
      git pull
    else
      echo "${D} is not a git repo"
    fi;
    cd ..
done
