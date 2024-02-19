#!/bin/bash
# Maintainer: John, Sodexis

# Pay attention to the tabs. Use sublime editor. @EOF preserves the tabs.

USR=sodexis
BASE_HOME=/opt/odoo
WORKSPACE_NAME=vscode.code-workspace

#Create the Multi-root workspace. 
cat > ${BASE_HOME}/${WORKSPACE_NAME} <<@EOF
{
    "folders": [
@EOF

cd ${BASE_HOME}/
for n in {10..15}; do
  for D in $(ls -d */ | cut -f1 -d'/' | grep $n); do
  BASE_D_NAME=$(echo $D | cut -d'-' -f1)
  CODE_VER=$(docker exec $D env 2>/dev/null | grep BASE_CODE_BRANCH | awk -F[=.] '{print $2}')

  if [[ ! -d ${BASE_HOME}/${D}/.vscode ]]; then mkdir -p ${BASE_HOME}/${D}/.vscode; fi

cat >> ${BASE_HOME}/${WORKSPACE_NAME} <<@EOF
        {
            "path": "${D}"
        },
@EOF

  if [[ -z $CODE_VER ]]; then continue; fi

cat > ${BASE_HOME}/${D}/.vscode/launch.json <<@EOF
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
                "--workers=0"
            ]
        }
    ]
}
@EOF

cat > ${BASE_HOME}/${D}/.vscode/settings.json <<@EOF
{
    "python.pythonPath": "venv/bin/python"
}
@EOF

  done
done

#Truncate the last comma coz that the end of multi-root workspace
sed -i '$s/,$//' ${BASE_HOME}/${WORKSPACE_NAME}

cat >> ${BASE_HOME}/${WORKSPACE_NAME} <<@EOF
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