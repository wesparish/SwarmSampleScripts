#!/bin/bash

#############################################################
## 	              Massimo Re Ferrè - IT20.INFO             ##
#############################################################

# This small sample script creates a swarm cluster w/ Consul against the following end-points: 
# - VMware Fusion
# - Virtualbox
# - vSphere (vCenter) 
# - ESX standalone 

# It requires Docker Toolbox (tested with version 1.10)

# usage: ./swarmcluster_consul.sh <# of Docker hosts> <driver> <vcenter | esx>
# example: ./swarmcluster_consul.sh 5 vmwarevsphere vcenter    <- will deploy a 5 nodes swarm cluster on vSphere (vCenter)
# example: ./swarmcluster_consul.sh 3 vmwarevsphere esx        <- will deploy a 3 nodes swarm cluster on vSphere (ESX standalone)
# example: ./swarmcluster_consul.sh 2 vmwarefusion             <- will deploy a 2 nodes swarm cluster on the local VMware Fusion
# example: ./swarmcluster_consul.sh 1 virtualbox               <- will deploy a 1 node swarm cluster on the local Virtualbox

# if using the vmwarevsphere flag remember to set the proper variables in the setVars function below


NUMBEROFNODES=$1
DRIVER=$2
ENDPOINT=$3

check() {
  if [ ${NUMBEROFNODES} -le 0 ]; then
  	echo "You need at least one node" 
  	exit 1
  fi 
}

unsetVars() {
  echo 'unsetVars() disabled'
}

welcome() {
	echo 'if using the vmwarevsphere flag remember to set the proper variables in the script' 
}

setVars() {
  echo 'setVars() disabled'
}

deployKeystore() {
    echo docker-machine create -d ${DRIVER} mh-keystore
	docker-machine create -d ${DRIVER} mh-keystore
	docker $(docker-machine config mh-keystore) run -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap
}

deployMaster() {
	docker-machine create -d ${DRIVER} --swarm --swarm-master \
			--swarm-discovery="consul://$(docker-machine ip mh-keystore):8500" \
			--engine-opt="cluster-store=consul://$(docker-machine ip mh-keystore):8500" \
			--engine-opt="cluster-advertise=eth0:2376" \
			swarm-node1-master
}

deploySlaves() {
    i=2
    while [[ ${i} -le ${NUMBEROFNODES} ]]
	do
    	docker-machine create -d ${DRIVER} --swarm \
				--swarm-discovery="consul://$(docker-machine ip mh-keystore):8500" \
				--engine-opt="cluster-store=consul://$(docker-machine ip mh-keystore):8500" \
				--engine-opt="cluster-advertise=eth0:2376" \
				swarm-node${i}
		((i=i+1))
	done
}

greetings() {		
	echo "Ensure you set the proper environmental variables..."
	docker-machine env --swarm swarm-node1-master
}

main() {
  check
#  unsetVars
  welcome
#  setVars
  deployKeystore	 
  deployMaster
  deploySlaves
  greetings
}

main





