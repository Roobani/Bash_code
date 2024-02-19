#!/bin/bash
# Maintainer: John, Sodexis

# Pay attention to the tabs. Use sublime editor. @EOF preserves the tabs.

USR=sodexis
BASE_HOME=/opt/odoo

#Create the Multi-root workspace. 
cat > ${BASE_HOME}/Test-Server.code-workspace <<@EOF
{
    "folders": [
@EOF

for D in $(find ${BASE_HOME}/ -maxdepth 1 -type d -not -path ${BASE_HOME}/); do
  BASE_D=$(basename $D)
  BASE_D_NAME=$(echo $BASE_D | cut -d'-' -f1)
  CODE_VER=$(docker exec $BASE_D env 2>/dev/null | grep BASE_CODE_BRANCH | awk -F[=.] '{print $2}')

if [[ ! -d $D/.vscode ]]; then mkdir -p $D/.vscode; fi

cat >> ${BASE_HOME}/Test-Server.code-workspace <<@EOF
        {
            "path": "${BASE_D}"
        },
@EOF

if [[ -z $CODE_VER ]]; then continue; fi

cat > $D/.vscode/launch.json <<@EOF
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "${BASE_D_NAME}",
            "type": "python",
            "request": "launch",
            "console": "integratedTerminal",
            "showReturnValue": true,
            "program": "\${workspaceFolder}/src/${CODE_VER}.0/odoo-bin",
            "args": [
                "--config=\${workspaceFolder}/conf/odoo.conf",
                "--dev=all",
                "--workers=0",
            ]
        }
    ]
}
@EOF

cat > $D/.vscode/settings.json <<@EOF
{
    "python.pythonPath": "venv/bin/python"
}
@EOF

done

#Truncate the last comma coz that the end of multi-root workspace
sed -i '$s/,$//' ${BASE_HOME}/Test-Server.code-workspace

cat >> ${BASE_HOME}/Test-Server.code-workspace <<@EOF
    ],
    "settings": {
        "files.watcherExclude": {
            "**/.git/objects/**": true,
            "**/.git/subtree-cache/**": true,
            "**/node_modules/*/**": true,
            "**/.hg/store/**": true,
            "**/data/**": true,
            "**/conf/**": true,
            "**/logs/**": true,
            "**/venv/**": true
        },
        "files.exclude": {
            "**/.svn": true,
            "**/.hg": true,
            "**/CVS": true,
            "**/.DS_Store": true,
            "**/.vscode": true
        }
    }
}
@EOF

chown -R ${USR}: $BASE_HOME