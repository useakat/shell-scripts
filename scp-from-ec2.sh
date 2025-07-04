PEM=RNAseqKey
USER=ubuntu
IP=107.22.184.215
FILE_PATH=$1
DEST_PATH=$2

scp -i ${PEM}.pem ${USER}@${IP}:/home/${USER}/${FILE_PATH} ${DEST_PATH}
