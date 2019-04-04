## merge upstream
git remote -v
git remote add upstream XXX
git fetch upstream
git checkout master
git merge upstream/master
git push origin master

git reset --hard upstream/master

git submodule update --init --recursive

