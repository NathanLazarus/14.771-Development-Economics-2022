scp -r Recitation_1_Code/* nlazarus@eofe8.mit.edu:~/
ssh nlazarus@eofe8.mit.edu
mkdir -p /home/nlazarus/R/libs
echo "R_LIBS_USER=\"/home/nlazarus/R/libs\"" > .Rprofile
sbatch SlurmSubmit.sh
