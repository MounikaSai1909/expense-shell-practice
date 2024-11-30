USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

echo "Please enter DB password:"
read -s mysql_root_password

VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "enabling nodejs:20"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "installing nodejs"

id expense  &>>$LOGFILE
if [ $? -ne 0 ]
then
    useradd expense &>>$LOGFILE
    VALIDATE $? "creating expense user"
else
    echo -e "expense user already created....$Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
VALIDATE $? "downloading backend code"

cd /app
rm -rf /app/*
unzip /tmp/backend.zip
VALIDATE $? "extracting backend code"

npm install
VALIDATE $? "install nodejs dependencies"

cp /home/ec2-user/expense-shell-practice /etc/systemd/system/backend.service
VALIDATE $? "copied backend services"

systemctl daemon-reload
VALIDATE $? " daemon-reload"

systemctl start backend
VALIDATE $? "starting backend services"

systemctl enable backend
VALIDATE $? "enabling backend services"

dnf install mysql -y
VALIDATE $? "installing mysql client"

mysql -h 172.31.84.46 -uroot -p${mysql_root_password} < /app/schema/backend.sql
VALIDATE $? "schema loading"

systemctl restart backend
VALIDATE $? "restart backend"




