cd D:/mesbahapi
git add -A
git commit -m "update files"
git push
ssh pachim@45.138.135.82
cd /home/pachim/messbah403.ir
git pull
pkill -f gunicorn
exit