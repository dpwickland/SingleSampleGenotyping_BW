#!/bin/bash

##USAGE
#bash GenotypeGVCFs_SingleSample_BW.sh <reference assembly to use: hg19 or hg38> <path to Batch directory containing single-sample GVCFs> <output directory; will be created if doesn't exist>
#bash GenotypeGVCFs_SingleSample_BW.sh hg19 /u/sciteam/wickland/ADSP_VarCallResults/ADSP_SingleSampleVC/hg19/BWA/GATK_HC/ADSP_Batch1.BWA_GATK_defaults /u/sciteam/wickland/ADSP_VarCallResults/ADSP_SingleSampleGenotyping/hg19/BWA-GATK-HC_defaults/Batch1

###SET PATHS AND ASSIGN VARIABLES
JAVADIR=/opt/java/jdk1.8.0_51/bin
GATK_PATH=/projects/sciteam/baib/builds/gatk-3.7.0
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
			#CREATE ARRAY LISTING ALL GVCFS IN INPUT PATH
                        then GVCFS=(${GVCFS[@]} $argument/*delivery/SRR*/*g.vcf)
                elif [ "$i" == 3 ];
                        then OUT_DIR=$argument
                fi
        i=$((i+1))
        done;

###CREATE DIRECTORIES
if [ ! -d ${OUT_DIR} ]; 
	then mkdir -p ${OUT_DIR}
fi

mkdir -p ${OUT_DIR}/commands/GenotypeGVCFs 
mkdir ${OUT_DIR}/tmp 
mkdir ${OUT_DIR}/VCFs
mkdir ${OUT_DIR}/logs
mkdir ${OUT_DIR}/aprun_joblists

################ GENOTYPEGVCFS SECTION ################

###CREATE SCRIPTS TO RUN GENOTYPEGVCFS ON EACH GVCF
for gvcf in ${GVCFS[*]}
do
	BASENAME=`basename ${gvcf} .raw.g.vcf`
	echo "${JAVADIR}/java -Xmx6g -Djava.io.tmpdir=${OUT_DIR}/tmp -jar ${GATK_PATH}/GenomeAnalysisTK.jar -T GenotypeGVCFs --includeNonVariantSites -R ${REF} -V ${gvcf} -L ${BED} --disable_auto_index_creation_and_locking_when_reading_rods | awk '/#/ || /[0-9]\/[0-9]/' | ${HTSLIB_PATH}/bgzip -c  >  ${OUT_DIR}/VCFs/${BASENAME}.vcf.gz

${HTSLIB_PATH}/tabix -p vcf ${OUT_DIR}/VCFs/${BASENAME}.vcf.gz" > ${OUT_DIR}/commands/GenotypeGVCFs/${BASENAME}.sh
done

###CREATE JOBLIST FOR BLUE WATERS ANISIMOV SCHEDULER 
GenotypeGVCFs_SingleSample_commands=0
for file in ${OUT_DIR}/commands/GenotypeGVCFs/*.sh; do GenotypeGVCFs_SingleSample_commands=$((${GenotypeGVCFs_SingleSample_commands} + 1)); echo ${OUT_DIR}/commands/GenotypeGVCFs/ `basename $file` >> ${OUT_DIR}/aprun_joblists/GenotypeGVCFs_joblist_for_aprun;done;

CMNDS_PER_NODE=10
NODES=$(((${GenotypeGVCFs_SingleSample_commands} + ${CMNDS_PER_NODE})/${CMNDS_PER_NODE})) 
n_for_aprun=$((${GenotypeGVCFs_SingleSample_commands} + 1))

###CREATE APRUN SCRIPT FOR BLUE WATERS ANISIMOV SCHEDULER
echo "#!/bin/bash

#PBS -A baib
#PBS -l nodes=${NODES}:ppn=32:xe
#PBS -l walltime=04:00:00
#PBS -N SingleSampleGT_GenotypeGVCFs_$1_`basename ${OUT_DIR}`
#PBS -o ${OUT_DIR}/logs/GenotypeGVCFs.stdout
#PBS -e ${OUT_DIR}/logs/GenotypeGVCFs.stderr
#PBS -m ae
#PBS -M dpwickland@gmail.com
#PBS -q normal

source /opt/modules/default/init/bash

aprun -n $n_for_aprun -N ${CMNDS_PER_NODE} -d $((32/${CMNDS_PER_NODE})) /projects/sciteam/baib/builds/Scheduler/scheduler.x ${OUT_DIR}/aprun_joblists/GenotypeGVCFs_joblist_for_aprun /bin/bash > ${OUT_DIR}/logs/GenotypeGVCFs_log_aprun.txt" > ${OUT_DIR}/aprun_GenotypeGVCFs

qsub ${OUT_DIR}/aprun_GenotypeGVCFs



