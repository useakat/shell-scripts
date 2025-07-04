PEM=RNAseqKey
USER=ubuntu
IP=107.22.184.215
FILE_PATH=$1
DEST_PATH=$2

scp -i ${PEM}.pem ${FILE_PATH} ${USER}@${IP}:/home/${USER}/${DEST_PATH}
