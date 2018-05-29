#!/bin/bash

##USAGE
#bash bcftools_SingleSample_BW.sh <which reference assembly to use: hg19 or hg38> <directory containing a batch's recalibrated bams> <output directory; will be created if doesn't exist>
#bash bcftools_SingleSample_BW.sh hg19 /u/sciteam/wickland/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/BWA/GATK_HC/ADSP_Batch1.1_10--test /u/sciteam/wickland/ADSP_VarCallResults/ADSP_SingleSampleGenotyping/hg19/BWA/bcftools_defaults/Batch1.1_10--test

###SET PATHS AND ASSIGN VARIABLES
JAVADIR=/opt/java/jdk1.8.0_51/bin
BCFTOOLS_PATH=/projects/sciteam/baib/builds/bcftools-1.5
HTSLIB_PATH=/projects/sciteam/baib/builds/htslib-1.6/bin

if [ $1 == "hg19" ];
	then REF=/projects/sciteam/baib/GATKbundle/July1_2017/LSM_July1_2017/human_g1k_v37_decoy.SimpleChromosomeNaming.fasta
		BED=/projects/sciteam/baib/GATKbundle/July1_2017/LSM_July1_2017/baylorwashu_broad.SimpleChromosomeNaming.bed
elif [ $1 == "hg38" ];
	then REF=/projects/sciteam/baib/GATKbundle/Dec3_2017/Homo_sapiens_assembly38.fasta
		BED=/projects/sciteam/baib/GATKbundle/Dec3_2017/exon_intervals_hg38_liftover_from_37.bed
fi

i=1
for argument in "$@";
        do         	
		if [ "$i" == 2 ];
			#CREATE ARRAY LISTING ALL BAMS IN INPUT PATH
                        then BAMS=(${BAMS[@]} $argument/*delivery/SRR*/*.recalibrated.bam)
                elif [ "$i" == 3 ];
                        then OUT_DIR=$argument
                fi
        i=$((i+1))
        done;

###CREATE DIRECTORIES
if [ ! -d ${OUT_DIR} ]; 
	then mkdir -p ${OUT_DIR}
fi

mkdir -p ${OUT_DIR}/commands/bcftools_SingleSample 
mkdir ${OUT_DIR}/tmp 
mkdir ${OUT_DIR}/VCFs
mkdir ${OUT_DIR}/logs
mkdir ${OUT_DIR}/aprun_joblists

################ bcftools_SingleSample SECTION ################

###CREATE SCRIPTS TO RUN bcftools_SingleSample ON EACH BAM
for bam in ${BAMS[*]}
do
	BASENAME=`basename ${bam} .recalibrated.bam`
	#must use --targetsfile instead of --regionsfile so that all positions are output sorted
	echo "${BCFTOOLS_PATH}/bcftools mpileup --annotate AD,DP --fasta-ref ${REF} --targets-file ${BED} ${bam} | ${BCFTOOLS_PATH}/bcftools call --multiallelic-caller | awk '/#/ || /[0-9]\/[0-9]/' | ${HTSLIB_PATH}/bgzip -c  > ${OUT_DIR}/VCFs/${BASENAME}.vcf.gz

	${HTSLIB_PATH}/tabix -p vcf ${OUT_DIR}/VCFs/${BASENAME}.vcf.gz" > ${OUT_DIR}/commands/bcftools_SingleSample/${BASENAME}.sh
done

###CREATE JOBLIST FOR BLUE WATERS ANISIMOV SCHEDULER 
bcftools_SingleSample_commands=0
for file in ${OUT_DIR}/commands/bcftools_SingleSample/*.sh; do bcftools_SingleSample_commands=$((${bcftools_SingleSample_commands} + 1)); echo ${OUT_DIR}/commands/bcftools_SingleSample/ `basename $file` >> ${OUT_DIR}/aprun_joblists/bcftools_SingleSample_joblist_for_aprun;done;

CMNDS_PER_NODE=10
NODES=$(((${bcftools_SingleSample_commands} + ${CMNDS_PER_NODE})/${CMNDS_PER_NODE})) 
n_for_aprun=$((${bcftools_SingleSample_commands} + 1))

###CREATE APRUN SCRIPT FOR BLUE WATERS ANISIMOV SCHEDULER
echo "#!/bin/bash

#PBS -A baib
#PBS -l nodes=${NODES}:ppn=32:xe
#PBS -l walltime=04:00:00
#PBS -N SingleSampleGT_bcftools_SingleSample_${1}_`basename ${OUT_DIR}`
#PBS -o ${OUT_DIR}/logs/bcftools_SingleSample.stdout
#PBS -e ${OUT_DIR}/logs/bcftools_SingleSample.stderr
#PBS -m ae
#PBS -M dpwickland@gmail.com
#PBS -q normal

source /opt/modules/default/init/bash

aprun -n $n_for_aprun -N ${CMNDS_PER_NODE} -d $((32/${CMNDS_PER_NODE})) /projects/sciteam/baib/builds/Scheduler/scheduler.x ${OUT_DIR}/aprun_joblists/bcftools_SingleSample_joblist_for_aprun /bin/bash > ${OUT_DIR}/logs/bcftools_SingleSample_log_aprun.txt" > ${OUT_DIR}/aprun_bcftools_SingleSample

qsub ${OUT_DIR}/aprun_bcftools_SingleSample



