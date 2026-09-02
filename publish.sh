#!/bin/bash
project_dir=$(pwd)

echo "Install lambda python dependencies"
echo $'#########################################\n'
cd lambdas
for dir in */; do
    cd $dir
    if [[ -f "requirements.txt" && ! -s "requirements.txt" ]]  then
        if [ ! -d ".venv" ]; then
            python -m venv .venv
        fi
        source .venv/bin/activate
        pip install --target ./package -r requirements.txt
        deactivate
    fi
    # source .venv/bin/activate
    # pip install --target ./package -r requirements.txt
    # deactivate
    cd ..
done
cd $project_dir


echo "Bundle lambda code"
echo $'#########################################\n'
rm *.zip
cd lambdas
for dir in */; do
    cd "$dir"
    if [ -d "package" ]; then
        cd package
        zip -qr "$project_dir/${dir///}.zip" .
        cd ..
    fi
    zip "$project_dir/${dir///}.zip" *.py
    cd ..
done
cd "$project_dir"   


echo "Publish Terraform"
echo $'#########################################\n'
cd ./terraform
terraform init
terraform apply
cd $project_dir