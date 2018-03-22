static_queue="/home/deepak/StaticData/static_queue"
StaticData="/home/deepak/StaticData"


cd $StaticData/$2

if [ "$1" = "HMOF" ]
then
sftp -F /home/deepak/test_user/exampleUser_id_rsa cdsftphmof@cds.client.content.hmhco.com <<EOF
cd /content/my.hrw.com/pushlist/RE_pushlist
put *.txt
EOF
cd $StaticData

rm -rf autodeploy.lock
perl StaticContent_linux_hrw_dos2unix_hmof_sftp.pl

fi

if [ "$1" = "TCK" ]
then
sftp -F /home/deepak/test_user/exampleUser_id_rsa cdsftptc@cds.client.content.hmhco.com  <<EOF
cd /content/www-k6.thinkcentral.com/Pushlist/RE_pushlist
put *.txt
EOF
cd $StaticData

rm -rf autodeploy.lock
perl StaticContent_linux_hrw_dos2unix_tck_sftp.pl


fi

pwd
