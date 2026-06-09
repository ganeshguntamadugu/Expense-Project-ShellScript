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

        echo "" | tee -a $Log_file
        dnf module disable $2 -y &>>$Log_file
        echo -e "$2 is$Y Disabled$N" | tee -a $Log_file

        echo "" | tee -a $Log_file
        dnf module enable $2:20 -y &>>$Log_file
        echo -e "$2 version 20 is$Y Enabled$N" | tee -a $Log_file

        echo "" | tee -a $Log_file
        dnf install $2 -y &>>$Log_file
        if [ $? -ne 0 ]
        then
            echo -e "$2 is$R not$N installed, check the error" | tee -a $Log_file
            exit 1
        else
            echo -e "$2 version 20 is installed$G Successful$N" | tee -a $Log_file
        fi
    else
        echo -e "$2 is$Y Already$N installed, nothing to do" | tee -a $Log_file
    fi
}

VALIDATE2(){
    if [ $? -ne 0 ]
    then
        echo -e "$2 is$R Failed$N, Please check the error" | tee -a $Log_file
        exit 1
    else
        echo -e "$2 is$G Successfull$N" | tee -a $Log_file
    fi
}

#The main script runs from here

ROOT_ACCESS

Logfile_Setup

echo -e "Script$Y Started$N executing at $(date)" | tee -a $Log_file

echo "" | tee -a $Log_file
dnf list installed nodejs &>>$Log_file
VALIDATE $? nodejs

echo "" | tee -a $Log_file
node -v | tee -a $Log_file

mkdir -p /app

echo "" | tee -a $Log_file
id expense &>>$Log_file
    if [ $? -ne 0 ]
    then
        useradd expense
        if [ $? -ne 0 ]
            echo -e "Creating user Expense is$R Failed$N, Please check the error" | tee -a $Log_file
            exit 1
        else
            echo -e "Creating user Expense is$G Successfull$N" | tee -a $Log_file
        fi
    fi

echo "" | tee -a $Log_file
curl -o /tmp/backend.tar.gz https://raw.githubusercontent.com/daws-90s/expense-documentation/refs/heads/main/artifacts/expense-backend-v3.tar.gz &>>$Log_file
VALIDATE2 $? 'Application Downloaded'


cd /app
tar -xzf /tmp/backend.tar.gz 

echo "" | tee -a $Log_file
cd /app
npm install &>>$Log_file
VALIDATE2 $? 'Dependencies Installation'


echo "" | tee -a $Log_file
cp /home/ec2-user/Expense-Project-ShellScript/backend-config /etc/systemd/system/backend.service
VALIDATE2 $? 'Backend configurations copied'


echo "" | tee -a $Log_file
dnf list installed mysql &>>$Log_file
if [ $? -ne 0 ]
then
    dnf install mysql -y &>>$Log_file
    echo -e "MySQL installation$G Successfull$N" | tee -a $Log_file
else
    echo -e "MySQL is$Y Already$N installed" | tee -a $Log_file
fi


echo "" | tee -a $Log_file
mysql -h mysql.gangs.shop -u root -pExpenseApp@1 < /app/schema/backend.sql &>>$Log_file
VALIDATE2 $? 'Schema integration'

echo "" | tee -a $Log_file
systemctl daemon-reload
VALIDATE2 $? 'Daemon reload'

echo "" | tee -a $Log_file
systemctl enable backend &>>$Log_file
VALIDATE2 $? 'Enabling backend'

echo "" | tee -a $Log_file
systemctl restart backend
VALIDATE2 $? 'Restart backend'

echo "" | tee -a $Log_file
echo -e "Script$G Completed$N executing at $(date)" | tee -a $Log_file 