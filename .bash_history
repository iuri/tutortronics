cd /web/projop
rsync -avzR -e ssh root@192.168.1.170:/web/projop/ /home/projop/
ls
pwd 
cp -r /home/projop/web/projop/* ./
ls
ls
cd /home/projop/
ls
mkdir database-backup
mv /web/projop/projop-2019-03-01.* database-backup/
rsync -avz -e ssh root@192.168.1.170:/home/projop/database-backup/projop-2019-03-11.dmp ./database-backup/
rsync -avz -e ssh root@192.168.1.170:/home/projop/database-backup/projop.pgsql.2019-03-11.dmp ./database-backup/
psql -f database-backup/projop.pgsql.2019-03-11.dmp 
exit
/usr/local/ns/bin/nsd -u projop -g nsadmin -t /usr/local/ns/config-projop.tcl
exit
/usr/local/ns/bin/nsd -u projop -g nsadmin -t /usr/local/ns/config-projop.tcl
ls
exit
/usr/local/ns/bin/nsd -u projop -g nsadmin -t /usr/local/ns/config-projop.tcl
exit
/usr/local/ns/bin/nsd -u projop -g nsadmin -t /usr/local/ns/config-projop.tcl
ps -ef
netstat -lna | grep tcp
exit
ps -ef
/usr/local/ns/bin/nsd -u projop -g nsadmin -t /usr/local/ns/config-projop.tcl
ps -ef
ps -ef
ps -ef
netstat -lna | grep tcp
/usr/local/ns/bin/nsd -u projop -g nsadmin -t /usr/local/ns/config-projop.tcl
tail -f log/error.log -n 1000
ls -la etc/
ls -la 
exit
exit
mail -s "send email from new projop" iuri.sampaio@gmail.com
exit
tail -f log/error.log
tail -f log/error.log
cd /usr/local/bin/
ln -s /usr/bin/dot
exit
tail -f log/error.log
exit
ls -la
ls
scp root@192.168.1.170:/web/projop/.git ./
scp -R root@192.168.1.170:/web/projop/.git ./
mkdir -p temp
cd temp
scp -R root@192.168.1.170:/web/projop/.git ./
exit
ls
git status
ls
ls -la
ssh root@192.168.1.170
ls
ls -la
exit
scp -R root@192.168.1.170:/web/projop/.git ./
scp -R root@192.168.1.170:/web/projop/git.tgz ./
scp root@192.168.1.170:/web/projop/git.tgz ./
ls
tar -xzvf git.tgz 
ls -la
rm -rf git.tgz 
exit
git status
exit
ls -la /home/projop/
ls -la /home/projop/database-backup/
cd
crontab -e
ps -ef
ls
ls temp
rm -rf temp
cd /home/projop/
ls
wget http://sourceforge.net/projects/project-open/files/project-open/Support%20Files/web_projop-aux-files.5.0.0.0.0.tgz
wget http://sourceforge.net/projects/project-open/files/project-open/V5.0/update/project-open-Update-5.0.2.4.0.tgz
ls
mkdir -p source-backup
cd source-backup/
tar -xzvf ../project-open-Update-5.0.2.4.0.tgz 
ls
tar -xzvf ../web_projop-aux-files.5.0.0.0.0.tgz 
ls
ls
cd ..
ls
mv project-open-Update-5.0.2.4.0.tgz source-backup/
mv web_projop-aux-files.5.0.0.0.0.tgz source-backup/
ls
mv web/ source-backup/
ls
cd 
mkdir -p bin
rsync -avz -e ssh root@192.168.1.195:/var/www/litli/bin/export-dbs ./
rsync -avz -e ssh root@192.168.1.195:/var/www/litli/bin/export-dbs ./bin/
ls
ls web/projop/
ls -la web/projop/
rm -rf web/
ls
git add bin
git status
git add tcl
git add etc
git commit -a -m 'add source directories'
ls
ls
git clone https://github.com/iuri/tutortronics.git
ls
mv tutortronics/.git/ ./
ls
git status
exit
ls
ls bin/
git status
git status
rm -rf tutortronics/
git status
git commit -a -m 'added source directories and export-dbs script'
git config --global user.email iuri@iurix.com
git config --global user.name "Iuri Sampaio"
git status
git status
git commit -a -m 'added source directories & export-dbs script'
git push
ls
git status
git push
crontab
ls -la /home/projop/database-backup/
crontab -e 
exit
crontab -e 
date
ls -la /home/projop/database-backup/
emacs bin/export-dbs 
crontab -e 
./bin/export-dbs 
rm -rf /home/projop/database-backup/projop.pgsql.20190312.gz 
date
ls -la /home/projop/database-backup/
ls -la /home/projop/database-backup/
ls -la /home/projop/database-backup/
ls -la /home/projop/database-backup/
ls -la /home/projop/database-backup/
exit
./bin/export-dbs 
pg_dump projop > /home/projop/database-backup/projop-20190313.dmp
tar -czvf /home/projop/database-backup/projop.pgsql.20190313.tgz /home/projop/database-backup/projop-20190313.dmp 
exit
ls
rsync -avz -e "ssh -p 2256" /web/projop/ projop@iurix.com:/web/projop/
ls /home/da
ls /home/projop/database-backup/
rsync -avz -e "ssh -p 2256" /home/projop/database-backup/projop.pgsql.20190314.gz projop@iurix.com:/web/projop/
exit
ls
git status
git commit -a -m 'edited exportdb script'
git pull
exit
emacs bin/export-dbs 
exit
