#! /bin/bash
#SBATCH -J Mn_remove
#SBATCH -D /scratch/shulinhe/phylogeny
#SBATCH --nodes=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=15000
#SBATCH --time=6:00:00
#SBATCH --mail-type=all
#SBATCH --mail-user=shulinhe@zedat.fu-berlin.de
bowtie2 --very-sensitive-local -x ./termitidea -1 /scratch/shulinhe/SRAdata/trinity_mn_as/Macrotermes_natalensis_1_edi.fastq.gz.P.qtrim.gz -2 /scratch/shulinhe/SRAdata/trinity_mn_as/Macrotermes_natalensis_2_edi.fastq.gz.P.qtrim.gz --al-conc-gz ./SRA_Mn_rRNA --un-conc-gz ./SRA_Mn_trim --quiet
