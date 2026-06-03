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
        dnf install $2 -y &>>$Log_file
        if [ $? -ne 0 ]
        then
            echo -e "$2 is $R not$N installed, check the error" | tee -a $Log_file
            exit 1
        else
            echo -e "$2 installation is$G Successful$N" | tee -a $Log_file
        fi
    else
        echo -e "$2 is$Y Already$N installed, nothing to do" | tee -a $Log_file
    fi
}

ROOT_ACCESS

Logfile_Setup

echo -e "Script$Y Started$N executing at $(date)" | tee -a $Log_file

echo "" | tee -a $Log_file
dnf list installed mysql-server &>>$Log_file
VALIDATE $? mysql-server 

echo "" | tee -a $Log_file
systemctl enable mysqld &>>$Log_file
echo -e "Systemctl$Y Enable$N mysqld$G Successfull$N" | tee -a $Log_file

echo "" | tee -a $Log_file
systemctl restart mysqld &>>$Log_file
echo -e "Systemctl$Y Restarted$N mysqld$G Successfull$N" | tee -a $Log_file

echo "" | tee -a $Log_file
mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$Log_file
echo -e "MySQL Password setup is$G Successfull$N" | tee -a $Log_file

echo "" | tee -a $Log_file
dnf list installed mysql &>>$Log_file
VALIDATE $? mysql

echo "" | tee -a $Log_file
echo -e "Script$G Completed$N executing at $(date)" | tee -a $Log_file 