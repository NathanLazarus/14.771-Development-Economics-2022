#!/bin/bash
#SBATCH --nodes=1 # request one node
#SBATCH --cpus-per-task=1  # ask for 1 cpu
#SBATCH --mem=3G # Maximum amount of memory this job will be given. This asks for 1 GB of ram.
#SBATCH --array=0-6 #specify how many jobs to queue
#SBATCH --partition=sched_mit_hill

# everything below this line is optional, but are nice to have quality of life things
#SBATCH --output=test_%J.out # tell it to store the output console text to a file called test_<assigned job number>.out
#SBATCH --error=test_%J.err # tell it to store the error messages from the program (if it doesn't write them to normal console output) to a file called test_<assigned job muber>.err
#SBATCH --mail-type=BEGIN,END,FAIL # Get an email when the job starts, ends, or fails
#SBATCH --mail-user=nlazarus@mit.edu

# under this line, we can load modules
module load R/4.1.0
module use /home/software/econ/modulefiles
module load stata/17/mp

#below this line is where we can place our commands
Rscript test.R $SLURM_ARRAY_TASK_ID
stata test.do $SLURM_ARRAY_TASK_ID