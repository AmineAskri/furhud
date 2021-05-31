
client=$1
cp -r <The directory where you have your jenkins files> /home/ubuntu/$client
cd /home/ubuntu/$client && kubectl create namespace $client-test-jenkins
cd /home/ubuntu/$client && sed -i 's|name: jenkins-pv|name: '$client'-test-jenkins-pv|g' /home/ubuntu/$client/jenkins-volume.yaml
cd /home/ubuntu/$client && sed -i 's|namespace: jenkins|namespace: '$client'-test-jenkins|g' /home/ubuntu/$client/jenkins-volume.yaml
cd /home/ubuntu/$client && sed -i 's|namespace: jenkins|namespace: '$client'-test-jenkins|g' /home/ubuntu/$client/jenkins-sa.yaml
cd /home/ubuntu/$client && sed -i 's|name: jenkins|name: '$client'-test-jenkins|g' /home/ubuntu/$client/jenkins-sa.yaml
cd /home/ubuntu/$client && sed -i 's|system:serviceaccounts: jenkins|system:serviceaccounts: '$client'-test-jenkins|g' /home/ubuntu/$client/jenkins-sa.yaml
cd /home/ubuntu/$client &&  kubectl apply -f jenkins-volume.yaml
cd /home/ubuntu/$client &&  kubectl apply -f jenkins-sa.yaml
cd /home/ubuntu/$client
port=$RANDOM
quit=0

while [ "$quit" -ne 1 ]; do
  netstat -a | grep $port >> /dev/null
  if [ $? -gt 0 ]; then
    quit=1
  else
    port=`expr $port + 1`
  fi
done
port=`expr $port + 0`
 echo "$port"
sed -i "s|port: 8080|port: $port|g" /home/ubuntu/$client/jenkins-service.yaml
cd /home/ubuntu/$client && kubectl create -f jenkins-deployment.yaml -n $client-test-jenkins
cd /home/ubuntu/$client && kubectl create -f jenkins-service.yaml -n $client-test-jenkins
cp  /home/ubuntu/default.nginx    /home/ubuntu/$client
cd /home/ubuntu/$client && sudo sed -i 's|server_name jenkins.furhud.org|server_name '$client'-jenkins.furhud.org|g'  /home/ubuntu/$client/default.nginx
cd /home/ubuntu/$client && sudo sed -i 's|proxy_pass http://localhost:8989;|proxy_pass http://localhost:'$port';|g'  /home/ubuntu/$client/default.nginx
cd /home/ubuntu/$client && sudo  cp default.nginx /etc/nginx/sites-available/$client-jenkins.conf
cd /home/ubuntu/$client && sudo ln -s  /etc/nginx/sites-available/$client-jenkins.conf  /etc/nginx/sites-enabled/
cd /home/ubuntu/$client && sudo service nginx restart
sleep 20
echo 'Visit' "$client"'-jenkins.furhud.org '
cd /home/ubuntu/$client && kubectl logs $(kubectl -n $client-test-jenkins get pods | tail -1 | awk '{print $1}' $var) -n $client-test-jenkins | grep 'Please use the following password to proceed to installation:' -A 2 > /home/ubuntu/$client/$client-password
echo 'See' "$client"'-password to get your password'
cd /home/ubuntu/$client && kubectl -n $client-test-jenkins port-forward $(kubectl -n $client-test-jenkins get pods | tail -1 | awk '{print $1}') $port:8080&


      
