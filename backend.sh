#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne     0 ]
    then 
        echo "Error:: You must have sudo access to excute this script"
        exit 1 #other than 0
    fi
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT 

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling existing default Nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling Nodejs 20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "installing nodejs"

useradd expense &>>$LOG_FILE_NAME
VALIDATE $? "creating expense user"

if [ $? -ne 0 ]
then 
    echo "useradd expense folder is not created" &>>$LOG_FILE_NAME
    VALIDATE $? "useradd expense already exist"
else
    echo -e "useradd expense already created ... $Y SKIPPING $N"
fi

mkdir /app &>>$LOG_FILE_NAME
VALIDATE $? "creating a app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "downloading backend"

cd /app

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzip backend"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "installing dependencies"

cp /home/ec2-user/expense-shell/backend.servece /etc/systemd/system/backend.service

#prepare MySQL schema

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "installing mysql client"

mysql -h mysql.10cloud.tech -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "setting up the transactions schema and tables"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "daemon reload"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend"

systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? "Starting the backend"

if [ $? -ne 0 ]
then 
    echo "useradd expense" &>>$LOG_FILE_NAME
    VALIDATE $? "useradd expense"
else
    echo -e "useradd expense already created ... $Y SKIPPING $N"
fi
