### Bash script for moving git repo from one origin to another.

Sometimes there is a need to move one git repository to new origin. It can be done by several commands in fact, like that:
```
git clone --bare <repo>
cd <repo folder>
git remote rm origin
git remote add <new origin>
git push --mirror <new origin>
```
That's exaclty what the script is doing, but with several options for configuration, such as:

1. Disable SSL by `--ssl-off` option. That disables SSL verifying globally during execution of the script by simply `git config --global http.sslVerify false`. If there is an **error or execution is interrupted by user**, or the execution **completes succesfully**, the SSL verification flag **will be set to value before the execution** (if the flag was disabled, it stays disabled, otherwise it will be enabled back).
2. Remove created directory with repo by `--clean` option. That means that after the execution the directory, which has been created for cloned repo, **will be removed**. The directory **will be removed** also in case of **error or interruption by user**, no matter is the option set or not.

The script choses the name of new directory from new repository URL (it's a name of the repository). **If there is already a folder named like that, an error will be occured**, because it's not a nice behaviour to override existing directories due to their possible importance.


**Important:** It has no ability to login to VCS, so you have to have credentials for them already.

Examples of usage:
```
./script.sh https://github.com/c47harsis/codenjoy-chess.git https://github.com/c47harsis/new-repo.git --clean --ssl-off
```