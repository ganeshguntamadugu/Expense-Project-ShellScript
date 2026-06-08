#!/bin/bash

Logfile_Setup(){
    Log_folder=/var/log/expense-project
    Script_name=$(echo $0 | cut -d "." -f1)
    Log_file=$Log_folder/$Script_name-$(date +"%B,%d,%Y-%T").log
    mkdir -p $Log_folder
}

 #Color 
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


ROOT_ACCESS(){
    USERID=$(id -u)

    if [ $USERID -ne 0 ]
    then 
        echo "Get the root access"
        exit 1  
    fi
}

VALIDATE(){    
    if [ $1 -ne 0 ]
    then 
        echo -e "$2 is$R NOT$N installed, going to install" | tee -a $Log_file

        dnf module disable $2 -y &>>$Log_file
        echo -e "$Y Disabled$N $2" | tee -a $Log_file

        dnf module enable $2:20 -y &>>$Log_file
        echo -e "$Y Enabled$N $2 version 20" | tee -a $Log_file

        dnf install $2 -y &>>$Log_file
        echo -e "$2 version 20 installed $G Successful$N" | tee -a $Log_file
        
    else
        echo -e "$2 is$Y Already$N installed, nothing to do" | tee -a $Log_file
    fi
}

#The main script runs from here

ROOT_ACCESS

Logfile_Setup

echo -e "Script$Y Started$N executing at $(date)" | tee -a $Log_file

echo "" | tee -a $Log_file
dnf list installed nodejs &>>$Log_file
VALIDATE $? nodejs

node -v | tee -a $Log_file

mkdir -p /app

useradd expense
echo "Created a user 'Expence'" | tee -a $Log_file

curl -o /tmp/backend.tar.gz https://raw.githubusercontent.com/daws-90s/expense-documentation/refs/heads/main/artifacts/expense-backend-v3.tar.gz
echo "Downloaded the Application" | tee -a $Log_file

cd /app
tar -xzf /tmp/backend.tar.gz 

cd /app
npm install &>>$Log_file
echo "Installed dependencies" | tee -a $Log_file

cp /home/ec2-user/Expense-Project-ShellScript/backend-config /etc/systemd/system/backend.service
echo "Copied backend configuration" | tee -a $Log_file

dnf list installed mysql &>>$Log_file
if [ $? -ne 0 ]
then
    dnf install mysql -y
    echo -e "MySQL installation $G Successfull$N" | tee -a $Log_file
else
    echo -e "MySQL is $Y Already$N installed" | tee -a $Log_file
fi


mysql -h mysql.gangs.shop -u root -pExpenseApp@1 < /app/schema/backend.sql
if [ $? -ne 0 ]
then
    echo -e "Schema integration $R Failed$N, Please check the error" | tee -a $Log_file
    exit 1
else
    echo -e "Schema integration $G Successfull$N" | tee -a $Log_file
fi


echo ""
systemctl daemon-reload
echo -e "Daemon reload $G Successfull$N" | tee -a $Log_file

echo ""
systemctl enable backend
echo -e "Enabled backend $G Successfull$N" | tee -a $Log_file

echo ""
systemctl restart backend
echo -e "Reastarted backend $G Successfull$N" | tee -a $Log_file